import 'package:deep_pick/deep_pick.dart';
import 'package:flutter/foundation.dart';
import 'package:hub_mqtt/entities/mqtt_base_entity.dart';
import 'package:hub_mqtt/mqtt_device.dart';
import 'package:hub_mqtt/utils.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:jinja/jinja.dart';

class MqttDefaultEntity extends MqttBaseEntity {
  MqttDefaultEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);

  @override
  List<String> getStateTopicTags() => ['state_topic'];
  @override
  Map<String, String> getStateTopicTemplateTags() => {'state_topic': 'value_template'};
  @override
  List<String> getJsonAttributesTopicTags() => ['json_attributes_topic'];
  @override
  List<String> getCommandTopicTags() => ['command_topic'];

  @mustCallSuper
  @override
  void bind(MqttDevice mqttDevice, [bool useEntityTopicTypeinAttrib = false]) {
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

    //////////////////////////////////////
    // subscribe to state_topic
    //////////////////////////////////////
    for (String tag in getStateTopicTags()) {
      String tagTemplate = getStateTopicTemplateTags()[tag] ?? k_value_template;
      _findTagAttachEventSubscribe(mqttDevice, tag, (data) {
        if (_entityHasCfgKey(tagTemplate)) {
          String valueTemplate = pick(jsonCfg, tagTemplate).asStringOrNull() ?? '';
          data = _checkTemplate(data, valueTemplate);

          mqttDevice.addAttribValue(_attribPrefix('value', useEntityTopicTypeinAttrib), data);
        } else {
          mqttDevice.addAttribValue(_attribPrefix('state', useEntityTopicTypeinAttrib), data);
        }
      });
    }

    //////////////////////////////////////
    // subscribe to availability
    //////////////////////////////////////
    payloadAvailable = pick(jsonCfg, k_payload_available).asStringOrNull() ?? k_online;
    payloadNotAvailable = pick(jsonCfg, k_payload_not_available).asStringOrNull() ?? k_offline;

    if (_entityHasCfgKey(k_availability_topic)) {
      _findTagAttachEventSubscribe(mqttDevice, k_availability_topic, (data) {
        String availabilityTemplate = pick(jsonCfg, k_availability_template).asStringOrNull() ?? '';
        data = _checkTemplate(data, availabilityTemplate);
        if (data == payloadAvailable) {
          mqttDevice.addAttribValue(k_availability, k_online);
        } else {
          mqttDevice.addAttribValue(k_availability, k_offline);
        }
      });
    } else {
      String availabilityMode = pick(jsonCfg, k_availability_mode).asStringOrNull() ?? 'latest';

      availabilityList = pick(jsonCfg, k_availability).asListOrEmpty<Availability>((pick) {
        Availability av = Availability();
        av.topic = pick('topic').asStringOrNull() ?? '';
        av.payloadAvailable = pick(k_payload_available).asStringOrNull() ?? k_online;
        av.payloadNotAvailable = pick(k_payload_not_available).asStringOrNull() ?? k_offline;
        av.valueTemplate = pick(k_value_template).asStringOrNull() ?? '';
        return av;
      });

      if (availabilityMode.toLowerCase() == 'latest') {
        for (Availability av in availabilityList) {
          _doAttachEventSubscribe(av.topic, (data) {
            data = _checkTemplate(data, av.valueTemplate);
            if (data == av.payloadAvailable) {
              mqttDevice.addAttribValue(k_availability, k_online);
            } else {
              mqttDevice.addAttribValue(k_availability, k_offline);
            }
          });
        }
      }

      if (availabilityMode.toLowerCase() == 'any') {
        for (Availability av in availabilityList) {
          _doAttachEventSubscribe(av.topic, (data) {
            data = _checkTemplate(data, av.valueTemplate);
            av.isAvailable = data == av.payloadAvailable;
            bool anyAvailable = false;
            for (Availability av in availabilityList) {
              if (av.isAvailable) anyAvailable = true;
            }
            if (anyAvailable) {
              mqttDevice.addAttribValue(k_availability, k_online);
            } else {
              mqttDevice.addAttribValue(k_availability, k_offline);
            }
          });
        }
      }

      if (availabilityMode.toLowerCase() == 'all') {
        for (Availability av in availabilityList) {
          _doAttachEventSubscribe(av.topic, (data) {
            data = _checkTemplate(data, av.valueTemplate);
            av.isAvailable = data == av.payloadAvailable;
            int allAvailable = 0;
            for (Availability av in availabilityList) {
              if (av.isAvailable) allAvailable++;
            }
            if (allAvailable == availabilityList.length) {
              mqttDevice.addAttribValue(k_availability, k_online);
            } else {
              mqttDevice.addAttribValue(k_availability, k_offline);
            }
          });
        }
      }
    }

    //////////////////////////////////////
    // subscribe to json_attributes_topic
    //////////////////////////////////////
    for (String tag in getJsonAttributesTopicTags()) {
      _findTagAttachEventSubscribe(mqttDevice, tag, (data) {
        String valueTemplate = pick(jsonCfg, k_value_template).asStringOrNull() ?? '';
        data = _checkTemplate(data, valueTemplate);
        mqttDevice.addAttribValue(_attribPrefix('json', useEntityTopicTypeinAttrib), data);
      });
    }

    // add all command_topic
    for (String tag in getCommandTopicTags()) {
      _addCommandTopics(mqttDevice, tag);
    }
  }

  String _checkTemplate(data, template) {
    if (data.startsWith('{') && template.isNotEmpty) {
      // using templates !!
      var env = Environment();
      var tmpl = env.fromString(template);
      Map<String, dynamic> jsonMap = Utils.toJsonMap(data);
      // print('valueTemplate=$valueTemplate jsonMap = $jsonMap $data');
      data = tmpl.render({k_value_json: jsonMap});
    }
    return data;
  }

  bool _entityHasCfgKey(String tag) => jsonCfg.containsKey(tag);

  String _attribPrefix(String type, bool useEntityTopicTypeinAttrib) => useEntityTopicTypeinAttrib
      ? '${topicParts.componentNode}_${topicParts.objectNode ?? topicParts.idNode}_$type'
      : topicParts.objectNode ?? topicParts.idNode;

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