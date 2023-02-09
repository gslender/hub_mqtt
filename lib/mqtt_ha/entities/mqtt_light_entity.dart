import 'package:hub_mqtt/mqtt_ha/entities/mqtt_default_entity.dart';

class MqttLightEntity extends MqttDefaultEntity {
  MqttLightEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);

  @override
  List<String> getStateTopicTags() => [
        'state_topic',
        'brightness_state_topic',
        'color_mode_state_topic',
        'color_temp_state_topic',
        'effect_state_topic',
        'hs_state_topic',
        'rgb_state_topic',
        'rgbw_state_topic',
        'rgbww_state_topic',
        'xy_state_topic',
      ];

  @override
  Map<String, String> getStateTopicTemplateTags() => {
        'state_topic': 'state_value_template',
        'brightness_state_topic': 'brightness_value_template',
        'color_mode_state_topic': 'color_mode_value_template',
        'color_temp_state_topic': 'color_temp_value_template',
        'effect_state_topic': 'effect_state_value_template',
        'hs_state_topic': 'hs_value_template',
        'rgb_state_topic': 'rgb_value_template',
        'rgbw_state_topic': 'rgbw_value_template',
        'rgbww_state_topic': 'rgbww_value_template',
        'xy_state_topic': 'xy_value_template',
      };

  @override
  List<String> getCommandTopicTags() => [
        'command_topic',
        'brightness_command_topic',
        'color_temp_command_topic',
        'effect_command_topic',
        'hs_command_topic',
        'rgb_command_topic',
        'rgbw_command_topic',
        'rgbww_command_topic',
        'white_command_topic',
        'xy_command_topic',
      ];
/*
  @override
  void bind(MqttDevice mqttDevice) {
    super.bind(mqttDevice);


    // add all command_topic
    for (String tag in getCommandTopicTag()) {
      _addCommandTopics(mqttDevice, tag);
    }
  }
  */
}
