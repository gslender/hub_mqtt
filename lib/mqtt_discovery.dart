import 'dart:convert';

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
              payloadStr = utf8.decoder.convert(publishMessage.payload.message);
            } catch (_) {
              return;
            }

            /// STATUS TOPIC
            if (topicStr.endsWith('/status')) {
              return;
            }

            /// CONFIG TOPIC
            if (topicStr.endsWith('/config')) {
              _processConfigTopic(topicStr, payloadStr);
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

  void _processConfigTopic(String topicStr, String payloadStr) {
    Map<String, String> attrVal = _attrValFromTopicConfig(topicStr, payloadStr);
    if (attrVal.containsKey(MqttDevice.kInvalid)) {
      _mapDevices['${_mapDevices.length + 1}${MqttDevice.kInvalid}'] = MqttDevice.invalid(attrVal[MqttDevice.kInvalid]);
    } else {
      MqttTopicParts parts = _getPartsFromTopic(topicStr);
      String id = attrVal['device_identifiers'] ?? MqttDevice.kInvalid;
      if (id == MqttDevice.kInvalid) {
        _mapDevices['${_mapDevices.length + 1}${MqttDevice.kInvalid}'] =
            MqttDevice.invalid('INVALID DEVICE_ID $topicStr');
      } else {
        MqttDevice? mqttDevice;
        String prefix = '${parts.objectIdTopic}_';
        if (_mapDevices.containsKey(id)) {
          // concat devices
          mqttDevice = _mapDevices[id];
          mqttDevice?.addTopic(topicStr);
          attrVal.forEach((key, value) {
            if (key.startsWith('device_')) prefix = '';
            mqttDevice?.addAttribValue('$prefix$key', value);
          });
        } else {
          // new device
          // String name = '${attrVal['device_name'] ?? topicStr} ${parts.componentTopic}';
          mqttDevice = MqttDevice(
            id: id,
            name: attrVal['device_name'] ?? topicStr,
            label: topicStr,
            type: _componentFromTopic(topicStr),
          );
          mqttDevice.addTopic(topicStr);
          attrVal.forEach((key, value) {
            if (key.startsWith('device_')) prefix = '';
            mqttDevice?.addAttribValue('$prefix$key', value);
          });
          mqttDevice.addAttribValue('topic', topicStr);
          _mapDevices[id] = mqttDevice;
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

  MqttTopicParts _getPartsFromTopic(String topicStr) {
    MqttTopicParts topicParts = MqttTopicParts();
    topicParts.configTopic = MqttDevice.kInvalid;
    if (topicStr.contains('/')) {
      List<String> leafs = topicStr.split('/');
      if (leafs.length > 2) {
        // short example is homeassistant/light/lamp/config
        // long example is  homeassistant/sensor/0x00124b001b78133/battery/config
        String configTopic = leafs.removeLast(); // remove config from the end
        if (configTopic != 'config') return topicParts;
        topicParts.configTopic = configTopic;
        topicParts.discoveryTopic = leafs.removeAt(0); // homeassistant from start
        topicParts.componentTopic = leafs.removeAt(0); // light (or) sensor
        topicParts.nodeIdTopic = leafs.removeAt(0); // lamp (or) 0x00124b001b78133
        if (leafs.isNotEmpty) {
          topicParts.objectIdTopic = leafs.removeAt(0); // battery
        }
      }
    }
    return topicParts;
  }
}

class MqttTopicParts {
  String discoveryTopic = '';
  String componentTopic = '';
  String nodeIdTopic = '';
  String objectIdTopic = '';
  String configTopic = '';
}
