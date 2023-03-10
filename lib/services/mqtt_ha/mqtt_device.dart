import 'package:deep_pick/deep_pick.dart';
import '/model/device.dart';
import '/services/mqtt_ha/mqtt_discovery.dart';

class MqttDevice extends Device {
  static const String kInvalid = 'kInvalid';

  MqttDevice({
    required String id,
    required String name,
    required String label,
    required String type,
    String room = '',
  }) : super(id: id, name: name, label: label, type: type, room: room);

  final Map<MqttTopicParts, dynamic> _topicCfgs = {};

  factory MqttDevice.invalid([String? name]) =>
      MqttDevice(id: kInvalid, name: name ?? kInvalid, label: kInvalid, type: kInvalid);

  bool isInvalid(MqttDevice device) => device.id == kInvalid && device.type == kInvalid;

  void addTopicCfgJson(MqttTopicParts topicParts, dynamic cfgJson) {
    bool skip = false;
    _topicCfgs.forEach((key, value) {
      if (key.fullOrigTopic == topicParts.fullOrigTopic) skip = true;
    });
    if (skip) return;
    _topicCfgs[topicParts] = cfgJson;
  }

  List<String> getTopics() => _topicCfgs.keys.map<String>((e) => e.toString()).toList();

  Map<MqttTopicParts, dynamic> getTopicCfgJsons() => _topicCfgs;

  dynamic getTopicJson(String? topic) {
    dynamic json = {'config_json_empty': true};
    _topicCfgs.forEach((key, value) {
      if (key.fullOrigTopic == topic) json = value;
    });
    return json;
  }

  @override
  DevicePurpose guessPurposeFromCapability() {
    List<String> validCapabilities = [];
    _topicCfgs.forEach((key, value) {
      String entityCategory = pick(value, 'entity_category').asStringOrNull() ?? '';
      String deviceClass = pick(value, 'device_class').asStringOrNull() ?? '';
      if (entityCategory == 'diagnostic' || entityCategory == 'config') return;
      if (deviceClass == 'firmware') return;
      validCapabilities.add(key.componentNode);
    });
    if (validCapabilities.isEmpty) validCapabilities = getCapabilities().toList();
    if (validCapabilities.contains('fan')) return DevicePurpose.aFan;
    if (validCapabilities.contains('climate')) return DevicePurpose.aClimate;
    if (validCapabilities.contains('cover')) return DevicePurpose.aCover;
    if (validCapabilities.contains('camera')) return DevicePurpose.aCamera;
    if (validCapabilities.contains('lock')) return DevicePurpose.aLock;
    if (validCapabilities.contains('device_automation')) return DevicePurpose.aDeviceAutomation;
    if (validCapabilities.contains('alarm_control_panel')) return DevicePurpose.aAlarmControlPanel;
    if (validCapabilities.contains('device_tracker')) return DevicePurpose.aDeviceTracker;
    if (validCapabilities.contains('humidifier')) return DevicePurpose.aHumidifier;
    if (validCapabilities.contains('siren')) return DevicePurpose.aSiren;
    if (validCapabilities.contains('vacuum')) return DevicePurpose.aVacuum;
    if (validCapabilities.contains('light')) return DevicePurpose.aLight;
    if (validCapabilities.contains('switch')) return DevicePurpose.aSwitch;
    if (validCapabilities.contains('number')) return DevicePurpose.aNumber;
    if (validCapabilities.contains('scene')) return DevicePurpose.aScene;
    if (validCapabilities.contains('button')) return DevicePurpose.aButton;
    if (validCapabilities.contains('select')) return DevicePurpose.aSelect;
    if (validCapabilities.contains('tag')) return DevicePurpose.aTag;
    if (validCapabilities.contains('text')) return DevicePurpose.aText;
    if (validCapabilities.contains('binary_sensor')) return DevicePurpose.aSensor;
    if (validCapabilities.contains('sensor')) return DevicePurpose.aSensor;
    if (validCapabilities.contains('update')) return DevicePurpose.aUpdate;
    return DevicePurpose.unknown;
  }
}
