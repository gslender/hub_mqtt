import 'package:hub_mqtt/entities/mqtt_base_entity.dart';
import 'package:hub_mqtt/entities/mqtt_default_entity.dart';

class MqttTagEntity extends MqttDefaultEntity {
  MqttTagEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);

  @override
  List<String> getStateTopicTag() => ['topic'];
}
