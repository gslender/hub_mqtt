import 'package:deep_pick/deep_pick.dart';
import '/services/mqtt_ha/entities/mqtt_base_entity.dart';
import '/services/mqtt_ha/entities/mqtt_default_entity.dart';
import '/services/mqtt_ha/mqtt_device.dart';

class MqttSwitchEntity extends MqttDefaultEntity {
  String payloadOff = k_OFF;
  String payloadOn = k_ON;
  String stateOff = k_LOCKED;
  String stateOn = k_LOCKING;

  MqttSwitchEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);

  @override
  String getNameDefault() => 'MQTT Switch';

  @override
  List<String> getStateTopicTags() => [
        'state_topic',
      ];
  @override
  Map<String, String> getStateTopicTemplateTags() => {
        'state_topic': 'value_template',
      };

  @override
  void bind(MqttDevice mqttDevice, bool useEntityTopicTypeinAttrib) {
    super.bind(mqttDevice, useEntityTopicTypeinAttrib);

    payloadOff = pick(jsonCfg, k_payload_off).asStringOrNull() ?? k_OFF;
    payloadOn = pick(jsonCfg, k_payload_on).asStringOrNull() ?? k_ON;

    stateOff = pick(jsonCfg, k_state_off).asStringOrNull() ?? payloadOff;
    stateOn = pick(jsonCfg, k_state_on).asStringOrNull() ?? payloadOn;

    addBoolEntityAttribute(mqttDevice, 'optimistic', false, useEntityTopicTypeinAttrib);
  }
}
