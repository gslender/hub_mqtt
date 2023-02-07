import 'package:hub_mqtt/entities/mqtt_default_entity.dart';

class MqttFanEntity extends MqttDefaultEntity {
  MqttFanEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);
  @override
  List<String> getStateTopicTag() => ['state_topic', 'speed_state_topic'];
  @override
  List<String> getCommandTopicTag() => ['command_topic', 'speed_command_topic'];
}
