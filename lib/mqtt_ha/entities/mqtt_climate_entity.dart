import 'package:hub_mqtt/mqtt_ha/entities/mqtt_default_entity.dart';

class MqttClimateEntity extends MqttDefaultEntity {
  MqttClimateEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);
}