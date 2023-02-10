import 'package:hub_mqtt/mqtt_ha/entities/mqtt_default_entity.dart';
import 'package:hub_mqtt/mqtt_ha/mqtt_device.dart';

class MqttClimateEntity extends MqttDefaultEntity {
  MqttClimateEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);

  @override
  String getNameDefault() => 'MQTT HVAC';

  @override
  List<String> getStateTopicTags() => [
        'state_topic',
        'aux_state_topic',
        'fan_mode_state_topic',
        'preset_mode_state_topic',
        'swing_mode_state_topic',
        'target_humidity_state_topic',
        'temperature_high_state_topic',
        'temperature_low_state_topic',
        'temperature_state_topic',
      ];
  @override
  Map<String, String> getStateTopicTemplateTags() => {
        'state_topic': 'value_template',
        'aux_state_topic': 'aux_state_template',
        'fan_mode_state_topic': 'fan_mode_state_template',
        'preset_mode_state_topic': 'preset_mode_state_template',
        'swing_mode_state_topic': 'swing_mode_state_template',
        'target_humidity_state_topic': 'target_humidity_state_template',
        'temperature_high_state_topic': 'temperature_high_state_template',
        'temperature_low_state_topic': 'temperature_low_state_template',
        'temperature_state_topic': 'temperature_state_template',
      };

  @override
  void bind(MqttDevice mqttDevice, bool useEntityTopicTypeinAttrib) {
    super.bind(mqttDevice, useEntityTopicTypeinAttrib);
    // addIntEntityAttribute(mqttDevice, 'expire_after', 0, useEntityTopicTypeinAttrib);
    // addBoolEntityAttribute(mqttDevice, 'force_update', false, useEntityTopicTypeinAttrib);
    // addIntEntityAttribute(mqttDevice, 'qos', 0, useEntityTopicTypeinAttrib);
    addDoubleEntityAttribute(mqttDevice, 'initial', 22.0, useEntityTopicTypeinAttrib);
    addDoubleEntityAttribute(mqttDevice, 'precision', 1.0, useEntityTopicTypeinAttrib);
    addDoubleEntityAttribute(mqttDevice, 'temp_step', 1.0, useEntityTopicTypeinAttrib);
    addStringEntityAttribute(mqttDevice, 'fan_modes', null, useEntityTopicTypeinAttrib);
    addStringEntityAttribute(mqttDevice, 'preset_modes', null, useEntityTopicTypeinAttrib);
    addStringEntityAttribute(mqttDevice, 'swing_modes', null, useEntityTopicTypeinAttrib);
    addStringEntityAttribute(mqttDevice, 'temperature_unit', 'C', useEntityTopicTypeinAttrib);
  }
}
