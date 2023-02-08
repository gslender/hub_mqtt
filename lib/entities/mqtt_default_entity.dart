import 'package:hub_mqtt/entities/mqtt_base_entity.dart';

class MqttDefaultEntity extends MqttBaseEntity {
  MqttDefaultEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);

  @override
  List<String> getStateTopicTag() => ['state_topic'];
  @override
  List<String> getJsonAttributesTopicTag() => ['json_attributes_topic'];
  @override
  List<String> getCommandTopicTag() => ['command_topic'];
}
