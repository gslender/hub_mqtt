import 'package:deep_pick/deep_pick.dart';
import 'package:events_emitter/events_emitter.dart';
import 'package:hub_mqtt/mqtt_device.dart';
import 'package:hub_mqtt/mqtt_discovery.dart';
import 'package:hub_mqtt/utils.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:jinja/jinja.dart';

abstract class MqttBaseEntity {
  MqttBaseEntity(this.mqttClient, this.events, this.topicParts, this.jsonCfg);

  final MqttServerClient mqttClient;
  final EventEmitter events;
  final MqttTopicParts topicParts;
  final dynamic jsonCfg;
  List<Availability> availabilityList = [];
  String payloadAvailable = 'online';
  String payloadNotAvailable = 'offline';

  List<String> getStateTopicTag();
  String getValueTemplateTag() => 'value_template';
  List<String> getJsonAttributesTopicTag();
  String getAvailabilityTopicTag() => 'availability_topic';
  String getAvailabilityTag() => 'availability';
  String getAvailabilityListTopicTag() => 'topic';
  String getAvailabilityModeTag() => 'availability_mode';
  List<String> getCommandTopicTag();

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

    // subscribe to state_topic
    for (String tag in getStateTopicTag()) {
      _findTagAttachEventSubscribe(mqttDevice, tag, (data) {
        if (_entityHasCfgKey(getValueTemplateTag())) {
          String valueTemplate = pick(jsonCfg, 'value_template').asStringOrNull() ?? '';
          if (data.startsWith('{') && valueTemplate.isNotEmpty) {
            // using templates !!
            var env = Environment();
            var tmpl = env.fromString(valueTemplate);
            Map<String, dynamic> jsonMap = Utils.toJsonMap(data);
            // print('valueTemplate=$valueTemplate jsonMap = $jsonMap $data');
            data = tmpl.render({'value_json': jsonMap});
          }
          mqttDevice.addAttribValue(_attribPrefix('value'), data);
        } else {
          mqttDevice.addAttribValue(_attribPrefix('state'), data);
        }
      });
    }

    // subscribe to availability
    payloadAvailable = pick(jsonCfg, 'payload_available').asStringOrNull() ?? 'online';
    payloadNotAvailable = pick(jsonCfg, 'payload_not_available').asStringOrNull() ?? 'offline';

    if (_entityHasCfgKey(getAvailabilityTopicTag())) {
      _findTagAttachEventSubscribe(mqttDevice, getAvailabilityTopicTag(), (data) {
        if (data == payloadAvailable) {
          mqttDevice.addAttribValue('availability', 'online');
        } else {
          mqttDevice.addAttribValue('availability', 'offline');
        }
      });
    } else {
      String availabilityMode = pick(jsonCfg, getAvailabilityModeTag()).asStringOrNull() ?? 'latest';

      availabilityList = pick(jsonCfg, getAvailabilityTag()).asListOrEmpty<Availability>((pick) {
        Availability av = Availability();
        av.topic = pick(getAvailabilityListTopicTag()).asStringOrNull() ?? '';
        av.payloadAvailable = pick('payload_available').asStringOrNull() ?? 'online';
        av.payloadNotAvailable = pick('payload_not_available').asStringOrNull() ?? 'online';
        return av;
      });

      if (availabilityMode.toLowerCase() == 'latest') {
        for (Availability av in availabilityList) {
          _doAttachEventSubscribe(av.topic, (data) {
            if (data == av.payloadAvailable) {
              mqttDevice.addAttribValue('availability', 'online');
            } else {
              mqttDevice.addAttribValue('availability', 'offline');
            }
          });
        }
      }

      if (availabilityMode.toLowerCase() == 'any') {
        for (Availability av in availabilityList) {
          _doAttachEventSubscribe(av.topic, (data) {
            av.isAvailable = data == av.payloadAvailable;
            bool anyAvailable = false;
            for (Availability av in availabilityList) {
              if (av.isAvailable) anyAvailable = true;
            }
            if (anyAvailable) {
              mqttDevice.addAttribValue('availability', 'online');
            } else {
              mqttDevice.addAttribValue('availability', 'offline');
            }
          });
        }
      }

      if (availabilityMode.toLowerCase() == 'all') {
        for (Availability av in availabilityList) {
          _doAttachEventSubscribe(av.topic, (data) {
            av.isAvailable = data == av.payloadAvailable;
            int allAvailable = 0;
            for (Availability av in availabilityList) {
              if (av.isAvailable) allAvailable++;
            }
            if (allAvailable == availabilityList.length) {
              mqttDevice.addAttribValue('availability', 'online');
            } else {
              mqttDevice.addAttribValue('availability', 'offline');
            }
          });
        }
      }
    }

    // subscribe to json_attributes_topic
    for (String tag in getJsonAttributesTopicTag()) {
      _findTagAttachEventSubscribe(mqttDevice, tag, (data) {
        // String attrib = '${topicParts.componentNode}_${topicParts.objectNode ?? topicParts.idNode}_json';
        String valueTemplate = pick(jsonCfg, 'value_template').asStringOrNull() ?? '';
        if (data.startsWith('{') && valueTemplate.isNotEmpty) {
          // using templates !!
          var env = Environment();
          var tmpl = env.fromString(valueTemplate);
          Map<String, dynamic> jsonMap = Utils.toJsonMap(data);
          // print('valueTemplate=$valueTemplate jsonMap = $jsonMap $data');
          data = tmpl.render({'value_json': jsonMap});
        }
        mqttDevice.addAttribValue(_attribPrefix('json'), data);
      });
    }

    // add all command_topic
    for (String tag in getCommandTopicTag()) {
      _addCommandTopics(mqttDevice, tag);
    }
  }

  bool _entityHasCfgKey(String tag) => jsonCfg.containsKey(tag);

  String _attribPrefix(String type) => '${topicParts.objectNode ?? topicParts.idNode}_$type';

  void _findTagAttachEventSubscribe(MqttDevice mqttDevice, String tag, Function(String) eventCallback) {
    jsonCfg.forEach((cfgJsonKey, cfgJsonValue) {
      if (cfgJsonKey == tag) {
        if (cfgJsonValue is String) {
          _doAttachEventSubscribe(cfgJsonValue, eventCallback);
        }
      }
    });
  }

  void _doAttachEventSubscribe(String cfgJsonValue, Function(String) eventCallback) {
    events.on<String>(cfgJsonValue, (data) {
      // Utils.logInfo('Device: ${mqttDevice.name} Subscribe:$jsonKey $cfgJsonValue $data');
      eventCallback(data);
    });
    if (mqttClient.getSubscriptionsStatus(cfgJsonValue) != MqttSubscriptionStatus.active) {
      mqttClient.subscribe(cfgJsonValue, MqttQos.atLeastOnce);
    }
  }

  void _addCommandTopics(MqttDevice mqttDevice, String jsonKey) {
    jsonCfg.forEach((cfgJsonKey, cfgJsonValue) {
      if (cfgJsonKey.endsWith(jsonKey)) {
        mqttDevice.addCommand(cfgJsonValue);
      }
    });
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
}

class Availability {
  String topic = '';
  String payloadAvailable = 'online';
  String payloadNotAvailable = 'offline';
  String valueTemplate = '';
  bool isAvailable = false;
}
