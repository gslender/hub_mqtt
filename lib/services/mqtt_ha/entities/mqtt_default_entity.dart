import 'package:deep_pick/deep_pick.dart';
import 'package:flutter/foundation.dart';
import '/services/mqtt_ha/entities/mqtt_base_entity.dart';
import '/services/mqtt_ha/mqtt_device.dart';
import '/utils.dart';
import 'package:mqtt_client/mqtt_client.dart';

class MqttDefaultEntity extends MqttBaseEntity {
  String payloadAvailable = k_online;
  String payloadNotAvailable = k_offline;

  MqttDefaultEntity(super.mqttClient, super.events, super.topicParts, super.jsonCfg);

  @override
  List<String> getStateTopicTags() => ['state_topic'];
  @override
  Map<String, String> getStateTopicTemplateTags() => {'state_topic': 'value_template'};
  @override
  List<String> getJsonAttributesTopicTags() => ['json_attributes_topic'];
  @override
  List<String> getCommandTopicTags() => ['command_topic'];
  @override
  String getNameDefault() => 'unknown';

  @mustCallSuper
  @override
  void bind(MqttDevice mqttDevice, bool useEntityTopicTypeinAttrib) {
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
    String connections = pick(jsonCfg, 'device', 'connections').asStringOrNull() ?? '';
    if (connections.isNotEmpty) mqttDevice.addAttribValue('device_connections', connections);
    String viaDevice = pick(jsonCfg, 'device', 'via_device').asStringOrNull() ?? '';
    if (viaDevice.isNotEmpty) mqttDevice.addAttribValue('device_via_device', viaDevice);

    //////////////////////////////////////
    // add common attributes
    //////////////////////////////////////
    addStringEntityAttribute(mqttDevice, 'device_class', 'none', useEntityTopicTypeinAttrib);
    addBoolEntityAttribute(mqttDevice, 'enabled_by_default', true, useEntityTopicTypeinAttrib);
    addStringEntityAttribute(mqttDevice, 'encoding', 'utf-8', useEntityTopicTypeinAttrib);
    addStringEntityAttribute(mqttDevice, 'entity_category', 'none', useEntityTopicTypeinAttrib);

    //////////////////////////////////////
    // subscribe to state_topic
    //////////////////////////////////////
    for (String tag in getStateTopicTags()) {
      String tagTemplate = getStateTopicTemplateTags()[tag] ?? k_value_template;
      _findTagAttachEventSubscribe(mqttDevice, tag, (data) {
        if (_entityHasCfgKey(tagTemplate)) {
          String valueTemplate = pick(jsonCfg, tagTemplate).asStringOrNull() ?? '';
          data = _checkTemplate(data, valueTemplate);
        }
        if (tag.endsWith('state_topic')) tag = tag.substring(0, tag.length - 11);
        mqttDevice.addAttribValue(_attribPrefix(tag, useEntityTopicTypeinAttrib), data);
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
        if (data.startsWith('{') && Utils.isValidJson(data)) {
          Map<String, dynamic> jsonData = Utils.toJsonMap(data);
          jsonData.forEach((key, value) {
            mqttDevice.addAttribValue(_attribPrefix(key, useEntityTopicTypeinAttrib), value.toString());
          });
        }
      });
    }

    // add all command_topic
    for (String tag in getCommandTopicTags()) {
      _addCommandTopics(mqttDevice, tag);
    }
  }

  void addStringEntityAttribute(
      MqttDevice mqttDevice, String attribName, String? defaultName, bool useEntityTopicTypeinAttrib) {
    if (defaultName == null && pick(jsonCfg, attribName).isAbsent) return;
    mqttDevice.addAttribValue(_attribPrefix(attribName, useEntityTopicTypeinAttrib),
        pick(jsonCfg, attribName).asStringOrNull() ?? defaultName ?? '');
  }

  void addIntEntityAttribute(
      MqttDevice mqttDevice, String attribName, int? defaultName, bool useEntityTopicTypeinAttrib) {
    if (defaultName == null && pick(jsonCfg, attribName).isAbsent) return;
    mqttDevice.addAttribValue(_attribPrefix(attribName, useEntityTopicTypeinAttrib),
        (pick(jsonCfg, attribName).asIntOrNull() ?? defaultName).toString());
  }

  void addDoubleEntityAttribute(
      MqttDevice mqttDevice, String attribName, double? defaultName, bool useEntityTopicTypeinAttrib) {
    if (defaultName == null && pick(jsonCfg, attribName).isAbsent) return;
    mqttDevice.addAttribValue(_attribPrefix(attribName, useEntityTopicTypeinAttrib),
        (pick(jsonCfg, attribName).asDoubleOrNull() ?? defaultName).toString());
  }

  void addBoolEntityAttribute(
      MqttDevice mqttDevice, String attribName, bool? defaultName, bool useEntityTopicTypeinAttrib) {
    if (defaultName == null && pick(jsonCfg, attribName).isAbsent) return;
    mqttDevice.addAttribValue(_attribPrefix(attribName, useEntityTopicTypeinAttrib),
        (pick(jsonCfg, attribName).asBoolOrNull() ?? defaultName).toString());
  }

  String _checkTemplate(dataIn, template) {
    String dataOut = dataIn;
    if (dataIn.startsWith('{') && template.isNotEmpty) {
      Map<String, dynamic> jsonMap = Utils.toJsonMap(dataIn);
      try {
        var tmpl = jinjaEnv.fromString(template);
        dataOut = tmpl.render({k_value_json: jsonMap});
        // print('$dataIn $template ==== $dataOut');
      } catch (e, _) {
        Utils.loginfo('${e.toString()} template=$template jsonMap = $jsonMap $dataOut');
      }
    }
    return dataOut;
  }

  bool _entityHasCfgKey(String tag) => jsonCfg.containsKey(tag);

  String _shortComp(String comp) =>
      {
        'alarm_control_panel': 'acp',
        'binary_sensor': 'bsn',
        'button': 'btn',
        'camera': 'cam',
        'climate': 'cli',
        'cover': 'cvr',
        'device_automation': 'dat',
        'device_tracker': 'trk',
        'fan': 'fan',
        'humidifier': 'hum',
        'light': 'lig',
        'lock': 'lck',
        'number': 'num',
        'scene': 'scn',
        'siren': 'sir',
        'select': 'sel',
        'sensor': 'sns',
        'switch': 'swt',
        'tag': 'tag',
        'text': 'txt',
        'update': 'upd',
        'vacuum': 'vac',
      }[comp] ??
      comp;

  String _attribPrefix(String type, bool useEntityTopicTypeinAttrib) {
    if (useEntityTopicTypeinAttrib) {
      return Utils.trim(
          '${_shortComp(topicParts.componentNode)}_${topicParts.objectNode ?? topicParts.idNode}_$type', '_');
    } else {
      return Utils.trim('${topicParts.objectNode ?? topicParts.idNode}_$type', '_');
    }
  }

  void _findTagAttachEventSubscribe(MqttDevice mqttDevice, String tag, Function(String) eventCallback) {
    jsonCfg.forEach((cfgJsonKey, cfgJsonValue) {
      if (cfgJsonKey == tag) {
        if (cfgJsonValue is String) {
          _doAttachEventSubscribe(cfgJsonValue, eventCallback);
        } else {
          Utils.loginfo('ERROR $cfgJsonValue is ${cfgJsonValue.runtimeType} $cfgJsonKey');
        }
      }
    });
  }

  void _doAttachEventSubscribe(String cfgJsonValue, Function(String) eventCallback) {
    events.on<String>(cfgJsonValue, (data) {
      // Utils.logInfo('_doAttachEventSubscribe: $cfgJsonValue $data');
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
