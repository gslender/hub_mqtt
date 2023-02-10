import 'package:hub_mqtt/mqtt_ha/entities/mqtt_default_entity.dart';
import 'package:hub_mqtt/mqtt_ha/mqtt_device.dart';

class MqttCameraEntity extends MqttDefaultEntity {
  MqttCameraEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);

  @override
  String getNameDefault() => 'MQTT Camera';

  @override
  List<String> getStateTopicTags() => ['topic'];

  @override
  void bind(MqttDevice mqttDevice, bool useEntityTopicTypeinAttrib) {
    super.bind(mqttDevice, useEntityTopicTypeinAttrib);
    addStringEntityAttribute(mqttDevice, 'image_encoding', 'none', useEntityTopicTypeinAttrib);
  }
}
