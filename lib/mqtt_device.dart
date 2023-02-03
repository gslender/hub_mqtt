import 'package:hub_mqtt/device.dart';

class MqttDevice extends Device {
  static const String kInvalid = 'kInvalid';

  MqttDevice({
    required String id,
    required String name,
    required String label,
    required String type,
  }) : super(id: id, name: name, label: label, type: type);

  List<String> _topics = [];

  factory MqttDevice.invalid([String? name]) =>
      MqttDevice(id: kInvalid, name: name ?? kInvalid, label: kInvalid, type: kInvalid);

  bool isInvalid(MqttDevice device) => device.id == kInvalid && device.type == kInvalid;

  void addTopic(String topicStr) => _topics.contains(topicStr) ? null : _topics.add(topicStr);

  List<String> getTopics() => _topics;
}
