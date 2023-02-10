// ignore_for_file: constant_identifier_names

import 'package:deep_pick/deep_pick.dart';
import 'package:hub_mqtt/mqtt_ha/entities/mqtt_default_entity.dart';
import 'package:hub_mqtt/mqtt_ha/mqtt_device.dart';

const String k_on = 'ON';
const String k_off = 'OFF';
const String k_payload_on = 'payload_on';
const String k_payload_off = 'payload_off';

class MqttBinarySensorEntity extends MqttDefaultEntity {
  String payloadOn = k_on;
  String payloadOff = k_off;
  int? offDelay;

  MqttBinarySensorEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);
  @override
  String getNameDefault() => 'MQTT Binary Sensor';

  @override
  void bind(MqttDevice mqttDevice, bool useEntityTopicTypeinAttrib) {
    super.bind(mqttDevice, useEntityTopicTypeinAttrib);
    addIntEntityAttribute(mqttDevice, 'expire_after', 0, useEntityTopicTypeinAttrib);
    addBoolEntityAttribute(mqttDevice, 'force_update', false, useEntityTopicTypeinAttrib);
    addIntEntityAttribute(mqttDevice, 'qos', 0, useEntityTopicTypeinAttrib);

    payloadOn = pick(jsonCfg, k_payload_on).asStringOrNull() ?? k_on;
    payloadOff = pick(jsonCfg, k_payload_off).asStringOrNull() ?? k_off;
    offDelay = pick(jsonCfg, 'off_delay').asIntOrNull();
  }
}
