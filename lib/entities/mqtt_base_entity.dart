import 'package:deep_pick/deep_pick.dart';
import 'package:events_emitter/events_emitter.dart';
import 'package:hub_mqtt/mqtt_device.dart';
import 'package:hub_mqtt/mqtt_discovery.dart';
import 'package:hub_mqtt/utils.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttBaseEntity {
  MqttBaseEntity(this.mqttClient, this.events, this.topicParts, this.jsonCfg);
  final MqttServerClient mqttClient;
  final EventEmitter events;
  final MqttTopicParts topicParts;
  final dynamic jsonCfg;

  void bind(MqttDevice mqttDevice) {
    mqttDevice.addCapability(topicParts.componentNode);
    mqttDevice.addAttribValue('_purpose', mqttDevice.determinePurpose().toString());
    String hwVersion = pick(jsonCfg, 'device', 'hw_version').asStringOrNull() ?? '';
    if (hwVersion.isNotEmpty) mqttDevice.addAttribValue('device_hw_version', hwVersion);
    String swVersion = pick(jsonCfg, 'device', 'sw_version').asStringOrNull() ?? '';
    if (swVersion.isNotEmpty) mqttDevice.addAttribValue('device_sw_version', swVersion);
    String manufacturer = pick(jsonCfg, 'device', 'manufacturer').asStringOrNull() ?? '';
    if (manufacturer.isNotEmpty) mqttDevice.addAttribValue('device_manufacturer', manufacturer);
    String model = pick(jsonCfg, 'device', 'model').asStringOrNull() ?? '';
    if (model.isNotEmpty) mqttDevice.addAttribValue('device_model', model);
    String cfgUrl = pick(jsonCfg, 'device', 'configuration_url').asStringOrNull() ?? '';
    if (cfgUrl.isNotEmpty) mqttDevice.addAttribValue('device_configuration_url', cfgUrl);

    if (!_subScribeStateTopics(mqttDevice, 'state_topic')) _subScribeStateTopics(mqttDevice, 'topic');
    _addCommandTopics(mqttDevice);

    // now subscribe to state_topic, availability_topic and json_attributes_topic

    // _subScribeTopics(mqttDevice, 'availability_topic');
    // _subScribeTopics(mqttDevice, 'json_attributes_topic');
  }

  bool _subScribeStateTopics(MqttDevice mqttDevice, String jsonKey) {
    bool hasStateTopic = false;
    mqttDevice.getTopicCfgJsons().forEach((topicParts, json) {
      json.forEach((cfgJsonKey, cfgJsonValue) {
        if (cfgJsonKey == jsonKey) {
          hasStateTopic = true;
          events.on<String>(cfgJsonValue, (String data) {
            String attrib = '${topicParts.componentNode}_${topicParts.objectNode ?? topicParts.idNode}';
            mqttDevice.addAttribValue(attrib, data);
            Utils.logInfo('Device ${mqttDevice.name} Subscribing $jsonKey topic $cfgJsonValue sent $data');
          });
          if (mqttClient.getSubscriptionsStatus(cfgJsonValue) != MqttSubscriptionStatus.active) {
            mqttClient.subscribe(cfgJsonValue, MqttQos.atLeastOnce);
          }
        }
      });
    });
    return hasStateTopic;
  }

/*
  void _addJsonAttrToMqttDevice(MqttDevice mqttDevice, String attribName, Map<String, dynamic> json) {
    json.forEach((key, value) {
      String newAttribName = '${attribName}_$key';
      if (value is Map<String, dynamic>) _addJsonAttrToMqttDevice(mqttDevice, newAttribName, value);
      mqttDevice.addAttribValue(newAttribName, value.toString());
    });
  }
  
  String _attribNameFromTopic(String topic) {
    if (topic.contains('/')) {
      List<String> leafs = topic.split('/');
      return '${leafs[leafs.length - 2]}_${leafs[leafs.length - 1]}';
    }
    return MqttDevice.kInvalid;
  }
*/
  void _addCommandTopics(MqttDevice mqttDevice) {
    for (String topic in mqttDevice.getTopics()) {
      dynamic json = mqttDevice.getTopicJson(topic);
      json.forEach((key, topic) {
        if (key.endsWith('command_topic')) {
          mqttDevice.addCommand(topic);
        }
      });
    }
  }
}
