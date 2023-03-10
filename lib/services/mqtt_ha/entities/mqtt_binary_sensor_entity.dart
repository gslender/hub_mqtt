import 'package:deep_pick/deep_pick.dart';
import '/services/mqtt_ha/entities/mqtt_base_entity.dart';
import '/services/mqtt_ha/entities/mqtt_default_entity.dart';
import '/services/mqtt_ha/mqtt_device.dart';

class MqttBinarySensorEntity extends MqttDefaultEntity {
  String payloadOn = k_ON;
  String payloadOff = k_OFF;
  int? offDelay;

  MqttBinarySensorEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);

  @override
  String getNameDefault() => 'MQTT Binary Sensor';

  @override
  void bind(MqttDevice mqttDevice, bool useEntityTopicTypeinAttrib) {
    super.bind(mqttDevice, useEntityTopicTypeinAttrib);
    addIntEntityAttribute(mqttDevice, 'expire_after', 0, useEntityTopicTypeinAttrib);
    addBoolEntityAttribute(mqttDevice, 'force_update', false, useEntityTopicTypeinAttrib);
    addIntEntityAttribute(mqttDevice, 'qos', 0, useEntityTopicTypeinAttrib);

    payloadOn = pick(jsonCfg, k_payload_on).asStringOrNull() ?? k_ON;
    payloadOff = pick(jsonCfg, k_payload_off).asStringOrNull() ?? k_OFF;
    offDelay = pick(jsonCfg, 'off_delay').asIntOrNull();
  }
}
