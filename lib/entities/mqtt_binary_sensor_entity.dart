import 'package:hub_mqtt/entities/mqtt_default_entity.dart';

class MqttBinarySensorEntity extends MqttDefaultEntity {
  MqttBinarySensorEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);
}
