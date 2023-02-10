import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hub_mqtt/mqtt_ha/entities/mqtt_base_entity.dart';
import 'package:hub_mqtt/mqtt_ha/entities/mqtt_binary_sensor_entity.dart';
import 'package:hub_mqtt/mqtt_ha/entities/mqtt_sensor_entity.dart';
import 'package:hub_mqtt/mqtt_ha/entities/mqtt_camera_entity.dart';
import 'package:hub_mqtt/mqtt_ha/entities/mqtt_climate_entity.dart';
import 'package:hub_mqtt/mqtt_ha/entities/mqtt_cover_entity.dart';
import 'package:hub_mqtt/mqtt_ha/entities/mqtt_default_entity.dart';
import 'package:hub_mqtt/mqtt_ha/entities/mqtt_fan_entity.dart';
import 'package:hub_mqtt/mqtt_ha/entities/mqtt_light_entity.dart';
import 'package:hub_mqtt/mqtt_ha/entities/mqtt_lock_entity.dart';
import 'package:hub_mqtt/mqtt_ha/entities/mqtt_switch_entity.dart';
import 'package:hub_mqtt/mqtt_ha/entities/mqtt_tag_entity.dart';
import 'package:hub_mqtt/mqtt_ha/ha_const.dart';
import 'package:hub_mqtt/mqtt_ha/mqtt_device.dart';
import 'package:hub_mqtt/mqtt_ha/utils.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:events_emitter/events_emitter.dart';
import 'package:deep_pick/deep_pick.dart';

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
    bool useEntityTopicTypeinAttrib = false,
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

            /// CONFIG TOPIC
            if (topicStr.endsWith('/config')) {
              _processConfigTopic(topicStr, payloadStr, useEntityTopicTypeinAttrib);
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

  void addInvalidDevice(MqttDevice device) => _mapDevices['${_mapDevices.length + 1}${MqttDevice.kInvalid}'] = device;

  void _processConfigTopic(String topicStr, String payloadStr, bool useEntityTopicTypeinAttrib) {
    if (!Utils.isValidJson(payloadStr)) {
      addInvalidDevice(MqttDevice.invalid('INVALID JSON $topicStr'));
      return;
    }
    dynamic jsonCfg = _convertPayloadCfgJson(payloadStr);
    if (jsonCfg.containsKey(MqttDevice.kInvalid)) {
      addInvalidDevice(MqttDevice.invalid('INVALID CONFIG $topicStr'));
      return;
    }

    MqttTopicParts topicParts = _getPartsFromTopic(topicStr, jsonCfg);
    if (!kSupportedComponents.contains(topicParts.componentNode)) {
      addInvalidDevice(MqttDevice.invalid('INVALID COMPONENT ${topicParts.componentNode}'));
      return;
    }
    String id = pick(jsonCfg, 'device', 'identifiers').asStringOrNull() ??
        pick(jsonCfg, 'unique_id').asStringOrNull() ??
        MqttDevice.kInvalid;
    if (id == MqttDevice.kInvalid) {
      addInvalidDevice(MqttDevice.invalid('INVALID DEVICE_ID $topicStr'));
      return;
    }

    MqttDevice? mqttDevice;
    if (_mapDevices.containsKey(id)) {
      // aggregate existing devices
      mqttDevice = _mapDevices[id];
      mqttDevice?.addTopicCfgJson(topicParts, jsonCfg);
    } else {
      // create new device
      String name = pick(jsonCfg, 'device', 'name').asStringOrNull() ?? topicParts.entity?.getNameDefault() ?? '';
      String room = pick(jsonCfg, 'device', 'suggested_area').asStringOrNull() ?? '';
      mqttDevice = MqttDevice(
        id: id,
        name: name,
        type: '',
        label: '',
        room: room,
      );
      mqttDevice.addTopicCfgJson(topicParts, jsonCfg);
      _mapDevices[id] = mqttDevice;
    }
    topicParts.entity?.bind(mqttDevice!, useEntityTopicTypeinAttrib);
  }

  Map<String, dynamic> _convertPayloadCfgJson(String config) {
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

  MqttTopicParts _getPartsFromTopic(String topicStr, dynamic jsonCfg) {
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
    switch (topicParts.componentNode) {
      case 'camera':
        topicParts.entity = MqttCameraEntity(mqttClient!, events, topicParts, jsonCfg);
        break;
      case 'tag':
        topicParts.entity = MqttTagEntity(mqttClient!, events, topicParts, jsonCfg);
        break;
      case 'light':
        topicParts.entity = MqttLightEntity(mqttClient!, events, topicParts, jsonCfg);
        break;
      case 'lock':
        topicParts.entity = MqttLockEntity(mqttClient!, events, topicParts, jsonCfg);
        break;
      case 'climate':
        topicParts.entity = MqttClimateEntity(mqttClient!, events, topicParts, jsonCfg);
        break;
      case 'cover':
        topicParts.entity = MqttCoverEntity(mqttClient!, events, topicParts, jsonCfg);
        break;
      case 'fan':
        topicParts.entity = MqttFanEntity(mqttClient!, events, topicParts, jsonCfg);
        break;
      case 'binary_sensor':
        topicParts.entity = MqttBinarySensorEntity(mqttClient!, events, topicParts, jsonCfg);
        break;
      case 'sensor':
        topicParts.entity = MqttSensorEntity(mqttClient!, events, topicParts, jsonCfg);
        break;
      case 'switch':
        topicParts.entity = MqttSwitchEntity(mqttClient!, events, topicParts, jsonCfg);
        break;
      case 'alarm_control_panel':
      case 'button':
      case 'device_automation':
      case 'device_tracker':
      case 'humidifier':
      case 'number':
      case 'scene':
      case 'siren':
      case 'select':
      case 'text':
      case 'update':
      case 'vacuum':
      default:
        topicParts.entity = MqttDefaultEntity(mqttClient!, events, topicParts, jsonCfg);
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
  MqttBaseEntity? entity;

  @override
  String toString() => fullOrigTopic;
}
