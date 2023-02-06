import 'package:hub_mqtt/entities/mqtt_default_entity.dart';

class MqttFanEntity extends MqttDefaultEntity {
  MqttFanEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);
}
