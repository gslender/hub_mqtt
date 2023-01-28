import 'package:hub_mqtt/ha_const.dart';
import 'package:hub_mqtt/utils.dart';

import 'package:hub_mqtt/device.dart';

class MqttDevice extends Device {
  static const String kInvalid = '!invalid';
  static const String kUnknown = '?unknown';
  static const String kNotImplemented = 'notImplementedComponent';

  MqttDevice({
    required String id,
    required String name,
    required String type,
  }) : super(id: id, name: name, type: type);

  factory MqttDevice.invalid([String? name]) => MqttDevice(id: kInvalid, name: name ?? kInvalid, type: kInvalid);

  bool isInvalid(MqttDevice device) => device.id == kInvalid && device.type == kInvalid;

  factory MqttDevice.fromTopicConfig({required String topic, required String config}) {
    if (!Utils.isValidJson(config)) {
      print('!!! INVALID CONFIG !!! - $config');
      return MqttDevice.invalid(topic);
    }
    String component = _componentFromTopic(topic);
    if (component == kInvalid) {
      print('!!! INVALID COMPONENT !!! - $topic');
      return MqttDevice.invalid(topic);
    }

    final Map<String, dynamic> json = {};

    Utils.toJsonMap(config).forEach((key, value) {
      if (kAbbreviations.containsKey(key)) {
        json[kAbbreviations[key]!] = value;
      } else {
        json[key] = value;
      }
    });

    String id = json['unique_id'] ?? _uidFromTopic(topic);
    if (id == kUnknown) return MqttDevice.invalid(topic);
    String name = json['name'] ?? '';

    MqttDevice newDevice = MqttDevice(
      id: id,
      name: name,
      type: component,
    );

    newDevice.lastupdated = DateTime.now().millisecondsSinceEpoch;
    _convertJsonToAttribValue(newDevice, json, 'config');
    return newDevice;
  }

  static void _convertJsonToAttribValue(MqttDevice device, Map<String, dynamic> json, String prefix) {
    json.forEach((k, v) {
      String key = k;

      Map<String, String> abbrev = kAbbreviations;
      if (prefix == 'device') abbrev = kDeviceAbbreviations;

      if (abbrev.containsKey(k)) {
        key = abbrev[k]!;
      }
      String value = v.toString();
      if (value.startsWith('{') && value.endsWith('}')) {
        if (v is Map<String, dynamic>) {
          _convertJsonToAttribValue(device, v, key);
        } else {
          print('prefix:$prefix k:$k v:$v');
        }
      } else {
        device.addAttribValue('${prefix}_$key', value.toString());
      }
    });
  }

  static String _componentFromTopic(String topic) {
    if (topic.contains('/')) {
      List<String> leafs = topic.split('/');
      if (kSupportedComponents.contains(leafs[1])) return leafs[1];
    }
    return kInvalid;
  }

  static String _uidFromTopic(String topic) {
    String? id;
    if (topic.contains('/')) {
      List<String> leafs = topic.split('/');
      if (leafs.length > 2) {
        leafs.removeLast();
        leafs.removeAt(0);
        id = leafs.join('_');
      }
    }
    return id ?? kUnknown;
  }
}
