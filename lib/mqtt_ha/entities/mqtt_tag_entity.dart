import 'package:hub_mqtt/mqtt_ha/entities/mqtt_default_entity.dart';

class MqttTagEntity extends MqttDefaultEntity {
  MqttTagEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);

  @override
  String getNameDefault() => 'MQTT Tag';

  @override
  List<String> getStateTopicTags() => ['topic'];
}
