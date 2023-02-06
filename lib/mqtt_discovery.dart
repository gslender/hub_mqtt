import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hub_mqtt/ha_const.dart';
import 'package:hub_mqtt/mqtt_device.dart';
import 'package:hub_mqtt/utils.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:events_emitter/events_emitter.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:jinja/jinja.dart';

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
      Utils.logInfo('$clientId MqttClientConnectionStatus=$status');
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
      Utils.logInfo('$clientId $connectionStatus');
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
    MqttTopicParts topicParts = _getPartsFromTopic(topicStr);
    dynamic jsonCfg = _convertPayloadCfgJson(topicParts, payloadStr);
    if (jsonCfg.containsKey(MqttDevice.kInvalid)) {
      MqttDevice mqttDevice = MqttDevice.invalid('INVALID CONFIG JSON $topicStr');
      mqttDevice.addTopicCfgJson(topicParts, jsonCfg);
      _mapDevices['${_mapDevices.length + 1}${MqttDevice.kInvalid}'] = mqttDevice;
    } else {
      String id = pick(jsonCfg, 'device', 'identifiers').asStringOrNull() ?? MqttDevice.kInvalid;
      if (id == MqttDevice.kInvalid) id = pick(jsonCfg, 'unique_id').asStringOrNull() ?? MqttDevice.kInvalid;
      if (id == MqttDevice.kInvalid) {
        MqttDevice mqttDevice = MqttDevice.invalid('INVALID DEVICE_ID $topicStr');
        mqttDevice.addTopicCfgJson(topicParts, jsonCfg);
        _mapDevices['${_mapDevices.length + 1}${MqttDevice.kInvalid}'] = mqttDevice;
      } else {
        MqttDevice? mqttDevice;
        if (_mapDevices.containsKey(id)) {
          // concat devices
          mqttDevice = _mapDevices[id];
          mqttDevice?.addTopicCfgJson(topicParts, jsonCfg);
          mqttDevice?.addCapability(topicParts.componentNode);
          mqttDevice?.addAttribValue('_purpose', mqttDevice.determinePurpose().toString());
        } else {
          // new device
          String name = pick(jsonCfg, 'device', 'name').asStringOrNull() ?? topicStr;
          mqttDevice = MqttDevice(
            id: id,
            name: name,
            type: '',
            label: '',
          );
          mqttDevice.addTopicCfgJson(topicParts, jsonCfg);
          mqttDevice.addCapability(topicParts.componentNode);
          mqttDevice.addAttribValue('_purpose', mqttDevice.determinePurpose().toString());
          mqttDevice.addAttribValue('device_hw_version', pick(jsonCfg, 'device', 'hw_version').asStringOrNull() ?? '');
          mqttDevice.addAttribValue('device_sw_version', pick(jsonCfg, 'device', 'sw_version').asStringOrNull() ?? '');
          mqttDevice.addAttribValue(
              'device_manufacturer', pick(jsonCfg, 'device', 'manufacturer').asStringOrNull() ?? '');
          mqttDevice.addAttribValue('device_model', pick(jsonCfg, 'device', 'model').asStringOrNull() ?? '');
          mqttDevice.addAttribValue(
              'device_configuration_url', pick(jsonCfg, 'device', 'configuration_url').asStringOrNull() ?? '');
          _mapDevices[id] = mqttDevice;
        }

        if (mqttDevice != null) {
          // now subscribe to state_topic, availability_topic and json_attributes_topic
          if (!_subScribeStateTopics(mqttDevice, 'state_topic')) _subScribeStateTopics(mqttDevice, 'topic');
          // _subScribeTopics(mqttDevice, 'availability_topic');
          // _subScribeTopics(mqttDevice, 'json_attributes_topic');

          // now add command_topics
          _addCommandTopics(mqttDevice);
        }
      }
    }
  }

  bool _subScribeStateTopics(MqttDevice mqttDevice, String jsonKey) {
    bool hasStateTopic = false;
    mqttDevice.getTopicCfgJsons().forEach((topicParts, json) {
      json.forEach((cfgJsonKey, cfgJsonValue) {
        if (cfgJsonKey == jsonKey) {
          hasStateTopic = true;
          events.on<String>(cfgJsonValue, (String data) {
            String attrib = '${topicParts.componentNode}_${topicParts.objectNode ?? topicParts.idNode}';
            mqttDevice.addAttribValue(attrib, data);
            Utils.logInfo('Device ${mqttDevice.name} Subscribing $jsonKey topic $cfgJsonValue sent $data');
          });
          if (mqttClient!.getSubscriptionsStatus(cfgJsonValue) != MqttSubscriptionStatus.active) {
            mqttClient!.subscribe(cfgJsonValue, MqttQos.atLeastOnce);
          }
        }
      });
    });
    return hasStateTopic;
  }

/*
  void _addJsonAttrToMqttDevice(MqttDevice mqttDevice, String attribName, Map<String, dynamic> json) {
    json.forEach((key, value) {
      String newAttribName = '${attribName}_$key';
      if (value is Map<String, dynamic>) _addJsonAttrToMqttDevice(mqttDevice, newAttribName, value);
      mqttDevice.addAttribValue(newAttribName, value.toString());
    });
  }
  
  String _attribNameFromTopic(String topic) {
    if (topic.contains('/')) {
      List<String> leafs = topic.split('/');
      return '${leafs[leafs.length - 2]}_${leafs[leafs.length - 1]}';
    }
    return MqttDevice.kInvalid;
  }
*/
  void _addCommandTopics(MqttDevice mqttDevice) {
    for (String topic in mqttDevice.getTopics()) {
      dynamic json = mqttDevice.getTopicJson(topic);
      json.forEach((key, topic) {
        if (key.endsWith('command_topic')) {
          mqttDevice.addCommand(topic);
        }
      });
    }
  }

  Map<String, dynamic> _convertPayloadCfgJson(MqttTopicParts topicParts, String config) {
    if (!Utils.isValidJson(config)) {
      return {MqttDevice.kInvalid: 'INVALID CONFIG ${topicParts.fullOrigTopic}'};
    }
    if (!kSupportedComponents.contains(topicParts.componentNode)) {
      return {MqttDevice.kInvalid: 'INVALID COMPONENT ${topicParts.componentNode}'};
    }

    final Map<String, dynamic> json = {};

    Utils.toJsonMap(config).forEach((k, value) {
      String key = k;
      if (kAbbreviations.containsKey(k)) {
        key = kAbbreviations[k] ?? k;
      }
      if (key == 'device' && value is Map<String, dynamic>) {
        final Map<String, dynamic> devJson = {};
        value.forEach((dkey, dvalue) {
          if (kDeviceAbbreviations.containsKey(dkey)) {
            devJson[kDeviceAbbreviations[dkey]!] = dvalue;
          } else {
            devJson[dkey] = dvalue;
          }
        });
        json[key] = devJson;
      } else {
        json[key] = value;
      }
    });
    return json;
  }

  MqttTopicParts _getPartsFromTopic(String topicStr) {
    MqttTopicParts topicParts = MqttTopicParts(topicStr);
    topicParts.configNode = MqttDevice.kInvalid;
    if (topicStr.contains('/')) {
      List<String> leafs = topicStr.split('/');
      if (leafs.length > 2) {
        // short example is homeassistant/light/lamp/config
        // long example is  homeassistant/sensor/0x00124b001b78133/battery/config
        String lastNode = leafs.removeLast(); // remove config from the end
        if (lastNode != 'config') return topicParts;
        topicParts.configNode = lastNode;
        topicParts.discoveryNode = leafs.removeAt(0); // homeassistant from start
        topicParts.componentNode = leafs.removeAt(0); // light (or) sensor
        topicParts.idNode = leafs.removeAt(0); // lamp (or) 0x00124b001b78133
        if (leafs.isNotEmpty) {
          topicParts.objectNode = leafs.removeAt(0); // battery
        }
      }
    }
    return topicParts;
  }
}

class MqttTopicParts {
  MqttTopicParts(this.fullOrigTopic);
  String fullOrigTopic = '';
  String discoveryNode = '';
  String componentNode = '';
  String idNode = '';
  String? objectNode;
  String configNode = '';

  @override
  String toString() => fullOrigTopic;
}
