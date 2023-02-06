import 'package:hub_mqtt/entities/mqtt_base_entity.dart';
import 'package:hub_mqtt/entities/mqtt_default_entity.dart';

class MqttCameraEntity extends MqttDefaultEntity {
  MqttCameraEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);

  @override
  String getStateTopicTag() => 'topic';
}
