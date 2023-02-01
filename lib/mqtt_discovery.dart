import 'package:flutter/foundation.dart';
import 'package:hub_mqtt/ha_const.dart';
import 'package:hub_mqtt/mqtt_device.dart';
import 'package:hub_mqtt/utils.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:events_emitter/events_emitter.dart';

class MqttDiscovery {
  final Map<String, MqttDevice> _mapDevices = {};
  Map<String, MqttDevice> getImmutableDevices() => Map<String, MqttDevice>.unmodifiable(_mapDevices);
  MqttClientConnectionStatus? connectionStatus;
  MqttServerClient? mqttClient;
  final EventEmitter events = EventEmitter();

  void disconnect() {
    if (mqttClient != null) {
      mqttClient!.disconnect();
    }
    events.off();
  }

  void connect({
    required String hostname,
    String clientId = 'MqttDiscovery',
    required String username,
    required String password,
    VoidCallback? connectedCallback,
    VoidCallback? failedCallback,
    VoidCallback? notAuthorizedCallback,
    VoidCallback? devicesUpdatedCallback,
  }) {
    disconnect();
    mqttClient = MqttServerClient(hostname, clientId);
    mqttClient!.logging(on: false);
    mqttClient!.connectTimeoutPeriod = 1000;
    // client.secure = true; // does not work and peer resets connection
    mqttClient!.connect(username, password).then((status) {
      print('$clientId MqttClientConnectionStatus=$status');
      if (status == null) return;
      connectionStatus = status;
      switch (status.state) {
        case MqttConnectionState.faulted:
        case MqttConnectionState.disconnecting:
        case MqttConnectionState.disconnected:
          break;
        case MqttConnectionState.connecting:
        case MqttConnectionState.connected:
          if (connectedCallback != null) connectedCallback();
          _mapDevices.clear();

          mqttClient!.subscribe('homeassistant/status', MqttQos.atMostOnce);
          mqttClient!.subscribe('homeassistant/+/+/config', MqttQos.atMostOnce);
          mqttClient!.subscribe('homeassistant/+/+/+/config', MqttQos.atMostOnce);
          // ignore that for now, that is for compatibility and not needed at this state.
          // client.subscribe('discovery/#', MqttQos.atMostOnce);
          // homeassistant/[DEVICE_TYPE]/[DEVICE_ID]/[OBJECT_ID]/config
          final builder = MqttClientPayloadBuilder().addString('online');
          mqttClient!.publishMessage('homeassistant/status', MqttQos.exactlyOnce, builder.payload!);

          mqttClient!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
            if (c == null || c.isEmpty) return;
            String payloadStr = '';
            String topicStr = '';

            try {
              final MqttReceivedMessage<MqttMessage?> msg = c.first;
              final publishMessage = msg.payload as MqttPublishMessage;
              topicStr = msg.topic;
              payloadStr = MqttPublishPayload.bytesToStringAsString(publishMessage.payload.message);
            } catch (_) {
              return;
            }

            /// STATUS TOPIC
            if (topicStr.endsWith('/status')) {
              return;
            }

            /// CONFIG TOPIC
            if (topicStr.endsWith('/config')) {
              Map<String, String> attrVal = _attrValFromTopicConfig(topicStr, payloadStr);
              if (attrVal.containsKey(MqttDevice.kInvalid)) {
                _mapDevices['${_mapDevices.length + 1}${MqttDevice.kInvalid}'] =
                    MqttDevice.invalid(attrVal[MqttDevice.kInvalid]);
              } else {
                String component = _componentFromTopic(topicStr);
                MqttIdPrefix mip = _idPrefixFromTopic(topicStr);
                if (mip.id == MqttDevice.kInvalid) {
                  //MqttDevice.kInvalid: 'INVALID UID $topic'
                } else {
                  MqttDevice? mqttDevice;
                  if (_mapDevices.containsKey(mip.id)) {
                    // concat devices
                    mqttDevice = _mapDevices[mip.id];
                    attrVal.forEach((key, value) {
                      String prefix = mip.prefix;
                      if (key.startsWith('device_')) prefix = '';
                      mqttDevice?.addAttribValue('$prefix$key', value);
                    });
                  } else {
                    // new device
                    String name = '${attrVal['device_name'] ?? topicStr} $component';
                    mqttDevice = MqttDevice(
                      id: mip.id,
                      name: name,
                      type: _componentFromTopic(topicStr),
                    );
                    attrVal.forEach((key, value) {
                      if (key.startsWith('device_')) mip.prefix = '';
                      mqttDevice?.addAttribValue('${mip.prefix}$key', value);
                    });
                    mqttDevice.addAttribValue('topic', topicStr);
                    _mapDevices[mip.id] = mqttDevice;
                  }
                  if (mqttDevice != null) {
                    // now check MqttSubscriptionStatus of the state_topic,
                    // availability_topic,command_topic and json_attributes_topic
                    _subScribe(mqttDevice, '_state_topic');
                    _subScribe(mqttDevice, '_availability_topic');
                    _subScribe(mqttDevice, '_command_topic');
                    _subScribe(mqttDevice, '_json_attributes_topic');
                  }
                }
              }
              if (devicesUpdatedCallback != null) devicesUpdatedCallback();
              return;
            }

            events.emit(topicStr, payloadStr);
          });
          break;
      }
    }, onError: (_) {
      var connectionStatus = mqttClient!.connectionStatus;
      print('$clientId $connectionStatus');
      if (connectionStatus == null) return;
      if (connectionStatus.returnCode == MqttConnectReturnCode.notAuthorized) {
        if (notAuthorizedCallback != null) notAuthorizedCallback();
      }

      if (connectionStatus.returnCode == MqttConnectReturnCode.noneSpecified) {
        if (failedCallback != null) failedCallback();
      }
    });
  }

  void _addJsonAttrToMqttDevice(MqttDevice mqttDevice, String attribName, Map<String, dynamic> json) {
    json.forEach((key, value) {
      String newAttribName = '${attribName}_$key';
      if (value is Map<String, dynamic>) _addJsonAttrToMqttDevice(mqttDevice, newAttribName, value);
      mqttDevice.addAttribValue(newAttribName, value.toString());
    });
  }

  void _subScribe(MqttDevice mqttDevice, String partTopic) {
    final attribValues = mqttDevice.getImmutableAttribValues();
    if (mqttClient?.connectionStatus?.state != MqttConnectionState.connected) return;
    attribValues.forEach((key, topic) {
      if (key.endsWith(partTopic)) {
        events.on<String>(topic, (String data) {
          if (data.startsWith('{')) {
            _addJsonAttrToMqttDevice(mqttDevice, attribNameFromTopic(topic), Utils.toJsonMap(data));
          } else {
            mqttDevice.addAttribValue(attribNameFromTopic(topic), data);
          }
        });
        if (mqttClient!.getSubscriptionsStatus(topic) != MqttSubscriptionStatus.active) {
          mqttClient!.subscribe(topic, MqttQos.atMostOnce);
        }
      }
    });
  }

  Map<String, String> _attrValFromTopicConfig(String topic, String config) {
    if (!Utils.isValidJson(config)) {
      print('!!! INVALID CONFIG !!! - $config');
      return {MqttDevice.kInvalid: 'INVALID CONFIG $topic'};
    }
    String component = _componentFromTopic(topic);
    if (component == MqttDevice.kInvalid) {
      print('!!! INVALID COMPONENT !!! - $topic');
      return {MqttDevice.kInvalid: 'INVALID COMPONENT $topic'};
    }

    final Map<String, dynamic> json = {};

    Utils.toJsonMap(config).forEach((key, value) {
      if (kAbbreviations.containsKey(key)) {
        json[kAbbreviations[key]!] = value;
      } else {
        json[key] = value;
      }
    });

    Map<String, String> attrVal = {};
    _convertJsonToAttribValue(attrVal, json, 'config');

    return attrVal;
  }

  void _convertJsonToAttribValue(Map<String, String> attrVal, Map<String, dynamic> json, String prefix) {
    json.forEach((k, v) {
      String key = k;

      Map<String, String> abbrev = kAbbreviations;
      if (prefix == 'device') abbrev = kDeviceAbbreviations;

      if (abbrev.containsKey(k)) {
        key = abbrev[k]!;
      }
      String value = v.toString();
      if (value.startsWith('{') && value.endsWith('}')) {
        if (v is Map<String, dynamic>) {
          _convertJsonToAttribValue(attrVal, v, key);
        } else {
          //TODO unhandled do we need to do anything prior to templates ??
          attrVal['${prefix}_$key'] = value;
        }
      } else {
        attrVal['${prefix}_$key'] = value.toString();
      }
    });
  }

  String attribNameFromTopic(String topic) {
    if (topic.contains('/')) {
      List<String> leafs = topic.split('/');
      return '${leafs[leafs.length - 2]}_${leafs[leafs.length - 1]}';
    }
    return MqttDevice.kInvalid;
  }

  String _componentFromTopic(String topic) {
    if (topic.contains('/')) {
      List<String> leafs = topic.split('/');
      if (kSupportedComponents.contains(leafs[1])) return leafs[1];
    }
    return MqttDevice.kInvalid;
  }

  MqttIdPrefix _idPrefixFromTopic(String topic) {
    MqttIdPrefix idPrefix = MqttIdPrefix();
    if (topic.contains('/')) {
      List<String> leafs = topic.split('/');
      if (leafs.length > 2 && leafs.last == 'config') {
        // short example is homeassistant/light/lamp/config
        // long example is  homeassistant/sensor/0x00124b001b78133/battery/config
        leafs.removeLast(); // remove config from the end
        leafs.removeAt(0); // homeassistant from start
        String componentTopic = leafs.removeAt(0); // light (or) sensor
        String nodeTopic = leafs.removeAt(0); // lamp (or) 0x00124b001b78133
        idPrefix.id = '${componentTopic}_$nodeTopic';
        if (leafs.isNotEmpty) {
          idPrefix.prefix = '${leafs.removeAt(0)}_';
        }
      }
    }
    return idPrefix;
  }
}

class MqttIdPrefix {
  String id = MqttDevice.kInvalid;
  String prefix = '';
}
