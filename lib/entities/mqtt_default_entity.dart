import 'package:hub_mqtt/entities/mqtt_base_entity.dart';

class MqttDefaultEntity extends MqttBaseEntity {
  MqttDefaultEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);

  @override
  String getStateTopicTag() => 'state_topic';
  @override
  String getJsonAttributesTopicTag() => 'json_attributes_topic';
}
