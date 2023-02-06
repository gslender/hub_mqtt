import 'package:hub_mqtt/entities/mqtt_default_entity.dart';

class MqttLightEntity extends MqttDefaultEntity {
  MqttLightEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);
}
