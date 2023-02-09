// ignore_for_file: constant_identifier_names
import 'package:deep_pick/deep_pick.dart';
import 'package:hub_mqtt/mqtt_ha/entities/mqtt_default_entity.dart';
import 'package:hub_mqtt/mqtt_ha/mqtt_device.dart';

const String k_close = 'CLOSE';
const String k_open = 'OPEN';
const String k_payload_close = 'payload_close';
const String k_payload_open = 'payload_open';

class MqttCoverEntity extends MqttDefaultEntity {
  String payloadClose = k_close;
  String payloadOpen = k_open;

  MqttCoverEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);

  @override
  void bind(MqttDevice mqttDevice, bool useEntityTopicTypeinAttrib) {
    super.bind(mqttDevice, useEntityTopicTypeinAttrib);
    payloadClose = pick(jsonCfg, k_payload_close).asStringOrNull() ?? k_close;
    payloadOpen = pick(jsonCfg, k_payload_open).asStringOrNull() ?? k_open;
  }
}
