import 'package:deep_pick/deep_pick.dart';
import 'package:hub_mqtt/mqtt_ha/entities/mqtt_default_entity.dart';
import 'package:hub_mqtt/mqtt_ha/mqtt_device.dart';
import 'package:hub_mqtt/mqtt_ha/entities/mqtt_base_entity.dart';

class MqttCoverEntity extends MqttDefaultEntity {
  String payloadClose = k_CLOSE;
  String payloadOpen = k_OPEN;
  String payloadStop = k_STOP;
  String stateClosed = k_closed;
  String stateClosing = k_closing;
  String stateOpen = k_open;
  String stateOpening = k_opening;
  String stateStopped = k_stopped;

  @override
  List<String> getStateTopicTags() => [
        'state_topic',
        'position_topic',
        'tilt_status_topic',
      ];
  @override
  Map<String, String> getStateTopicTemplateTags() => {
        'state_topic': 'state_value_template',
        'position_topic': 'position_template',
        'tilt_status_topic': 'tilt_status_template',
      };

  MqttCoverEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);

  @override
  void bind(MqttDevice mqttDevice, bool useEntityTopicTypeinAttrib) {
    super.bind(mqttDevice, useEntityTopicTypeinAttrib);
    payloadClose = pick(jsonCfg, k_payload_close).asStringOrNull() ?? k_CLOSE;
    payloadOpen = pick(jsonCfg, k_payload_open).asStringOrNull() ?? k_OPEN;
    payloadStop = pick(jsonCfg, k_payload_stop).asStringOrNull() ?? k_STOP;
    stateClosed = pick(jsonCfg, k_state_closed).asStringOrNull() ?? k_closed;
    stateClosing = pick(jsonCfg, k_state_closing).asStringOrNull() ?? k_closing;
    stateOpen = pick(jsonCfg, k_state_open).asStringOrNull() ?? k_open;
    stateOpening = pick(jsonCfg, k_state_opening).asStringOrNull() ?? k_opening;
    stateStopped = pick(jsonCfg, k_state_stopped).asStringOrNull() ?? k_stopped;
    addBoolEntityAttribute(mqttDevice, 'optimistic', false, useEntityTopicTypeinAttrib);
    addIntEntityAttribute(mqttDevice, 'position_closed', 0, useEntityTopicTypeinAttrib);
    addIntEntityAttribute(mqttDevice, 'position_open', 100, useEntityTopicTypeinAttrib);
    addIntEntityAttribute(mqttDevice, 'tilt_closed_value', 0, useEntityTopicTypeinAttrib);
    addIntEntityAttribute(mqttDevice, 'tilt_max', 100, useEntityTopicTypeinAttrib);
    addIntEntityAttribute(mqttDevice, 'tilt_min', 0, useEntityTopicTypeinAttrib);
    addIntEntityAttribute(mqttDevice, 'tilt_opened_value', 100, useEntityTopicTypeinAttrib);
    addBoolEntityAttribute(mqttDevice, 'tilt_optimistic', true, useEntityTopicTypeinAttrib);
  }
}
