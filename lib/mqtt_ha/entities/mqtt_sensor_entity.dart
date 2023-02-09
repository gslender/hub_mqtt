import 'package:hub_mqtt/mqtt_ha/entities/mqtt_default_entity.dart';
import 'package:hub_mqtt/mqtt_ha/mqtt_device.dart';

class MqttSensorEntity extends MqttDefaultEntity {
  MqttSensorEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);
  @override
  String getNameDefault() => 'MQTT Sensor';

  @override
  void bind(MqttDevice mqttDevice, [bool useEntityTopicTypeinAttrib = false]) {
    super.bind(mqttDevice);
    addStringEntityAttribute(mqttDevice, 'device_class', 'none', useEntityTopicTypeinAttrib);
    addBoolEntityAttribute(mqttDevice, 'enabled_by_default', true, useEntityTopicTypeinAttrib);
    addStringEntityAttribute(mqttDevice, 'encoding', 'utf-8', useEntityTopicTypeinAttrib);
    addStringEntityAttribute(mqttDevice, 'entity_category', 'none', useEntityTopicTypeinAttrib);
    addIntEntityAttribute(mqttDevice, 'expire_after', 0, useEntityTopicTypeinAttrib);
    addBoolEntityAttribute(mqttDevice, 'force_update', false, useEntityTopicTypeinAttrib);
    addIntEntityAttribute(mqttDevice, 'qos', 0, useEntityTopicTypeinAttrib);
    addStringEntityAttribute(mqttDevice, 'state_class', 'none', useEntityTopicTypeinAttrib);
  }
}
