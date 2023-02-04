import 'package:hub_mqtt/device.dart';

class MqttDevice extends Device {
  static const String kInvalid = 'kInvalid';

  MqttDevice({
    required String id,
    required String name,
    required String label,
    required String type,
  }) : super(id: id, name: name, label: label, type: type);

  final Map<String, dynamic> _topicCfgs = {};

  factory MqttDevice.invalid([String? name]) =>
      MqttDevice(id: kInvalid, name: name ?? kInvalid, label: kInvalid, type: kInvalid);

  bool isInvalid(MqttDevice device) => device.id == kInvalid && device.type == kInvalid;

  void addTopicCfgJson(String topicStr, dynamic cfgJson) => _topicCfgs[topicStr] = cfgJson;

  List<String> getTopics() => _topicCfgs.keys.toList();

  dynamic getTopicJson(String? topic) => _topicCfgs[topic];
}
