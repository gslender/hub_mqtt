import 'package:deep_pick/deep_pick.dart';
import '/services/mqtt_ha/entities/mqtt_base_entity.dart';
import '/services/mqtt_ha/entities/mqtt_default_entity.dart';
import '/services/mqtt_ha/mqtt_device.dart';

class MqttLockEntity extends MqttDefaultEntity {
  String payloadLock = k_LOCK;
  String payloadUnlock = k_UNLOCK;
  String payloadOpen = k_OPEN;
  String stateJammed = k_JAMMED;
  String stateLocked = k_LOCKED;
  String stateLocking = k_LOCKING;
  String stateUnlocked = k_UNLOCKED;
  String stateUnlocking = k_UNLOCKING;

  MqttLockEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);

  @override
  String getNameDefault() => 'MQTT Lock';

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

    payloadLock = pick(jsonCfg, k_payload_lock).asStringOrNull() ?? k_LOCK;
    payloadUnlock = pick(jsonCfg, k_payload_unlock).asStringOrNull() ?? k_UNLOCK;
    payloadOpen = pick(jsonCfg, k_payload_open).asStringOrNull() ?? k_OPEN;
    stateJammed = pick(jsonCfg, k_state_jammed).asStringOrNull() ?? k_JAMMED;
    stateLocked = pick(jsonCfg, k_state_locked).asStringOrNull() ?? k_LOCKED;
    stateLocking = pick(jsonCfg, k_state_locking).asStringOrNull() ?? k_LOCKING;
    stateUnlocked = pick(jsonCfg, k_state_unlocked).asStringOrNull() ?? k_UNLOCKED;
    stateUnlocking = pick(jsonCfg, k_state_unlocking).asStringOrNull() ?? k_UNLOCKING;

    addStringEntityAttribute(mqttDevice, 'code_format', 'none', useEntityTopicTypeinAttrib);
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
