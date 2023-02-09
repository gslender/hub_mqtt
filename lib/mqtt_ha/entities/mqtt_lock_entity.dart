import 'package:hub_mqtt/mqtt_ha/entities/mqtt_default_entity.dart';

class MqttLockEntity extends MqttDefaultEntity {
  MqttLockEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);
}
