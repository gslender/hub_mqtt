import 'package:hub_mqtt/entities/mqtt_default_entity.dart';

class MqttSensorEntity extends MqttDefaultEntity {
  MqttSensorEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);
}
