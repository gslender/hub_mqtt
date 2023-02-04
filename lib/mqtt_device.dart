import 'package:deep_pick/deep_pick.dart';
import 'package:hub_mqtt/device.dart';
import 'package:hub_mqtt/mqtt_discovery.dart';

class MqttDevice extends Device {
  static const String kInvalid = 'kInvalid';

  MqttDevice({
    required String id,
    required String name,
    required String label,
    required String type,
  }) : super(id: id, name: name, label: label, type: type);

  final Map<MqttTopicParts, dynamic> _topicCfgs = {};

  factory MqttDevice.invalid([String? name]) =>
      MqttDevice(id: kInvalid, name: name ?? kInvalid, label: kInvalid, type: kInvalid);

  bool isInvalid(MqttDevice device) => device.id == kInvalid && device.type == kInvalid;

  void addTopicCfgJson(MqttTopicParts topicParts, dynamic cfgJson) {
    bool skip = false;
    _topicCfgs.forEach((key, value) {
      if (key.origTopic == topicParts.origTopic) skip = true;
    });
    if (skip) return;
    _topicCfgs[topicParts] = cfgJson;
  }

  List<String> getTopics() => _topicCfgs.keys.map<String>((e) => e.toString()).toList();

  dynamic getTopicJson(String? topic) {
    dynamic json = {'config_json_empty': true};
    _topicCfgs.forEach((key, value) {
      if (key.origTopic == topic) json = value;
    });
    return json;
  }

  @override
  DevicePurpose guessPurposeFromCapability() {
    List<String> validCapabilities = [];
    _topicCfgs.forEach((key, value) {
      String entityCategory = pick(value, 'entity_category').asStringOrNull() ?? '';
      if (entityCategory != 'diagnostic') {
        validCapabilities.add(key.componentTopic);
      }
    });
    if (validCapabilities.isEmpty) validCapabilities = getCapabilities().toList();
    if (validCapabilities.contains('light')) return DevicePurpose.aLight;
    if (validCapabilities.contains('switch')) return DevicePurpose.aSwitch;
    if (validCapabilities.contains('fan')) return DevicePurpose.aFan;
    if (validCapabilities.contains('cover')) return DevicePurpose.aBlind;
    if (validCapabilities.contains('sensor')) return DevicePurpose.aSensor;
    return DevicePurpose.unknown;
  }
}
