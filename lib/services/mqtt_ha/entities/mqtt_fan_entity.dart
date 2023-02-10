import '/services/mqtt_ha/entities/mqtt_default_entity.dart';

class MqttFanEntity extends MqttDefaultEntity {
  MqttFanEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);

  @override
  String getNameDefault() => 'MQTT Fan';

  @override
  List<String> getStateTopicTags() => ['state_topic', 'speed_state_topic'];
  @override
  Map<String, String> getStateTopicTemplateTags() => {
        'state_topic': 'state_value_template',
        'speed_state_topic': 'speed_value_template',
      };
  @override
  List<String> getCommandTopicTags() => ['command_topic', 'speed_command_topic'];
}
