import 'package:hub_mqtt/mqtt_ha/entities/mqtt_default_entity.dart';

class MqttCameraEntity extends MqttDefaultEntity {
  MqttCameraEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);

  @override
  List<String> getStateTopicTags() => ['topic'];
}