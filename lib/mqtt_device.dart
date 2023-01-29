import 'package:hub_mqtt/device.dart';

class MqttDevice extends Device {
  static const String kInvalid = 'kInvalid';

  MqttDevice({
    required String id,
    required String name,
    required String type,
  }) : super(id: id, name: name, type: type);

  factory MqttDevice.invalid([String? name]) => MqttDevice(id: kInvalid, name: name ?? kInvalid, type: kInvalid);

  bool isInvalid(MqttDevice device) => device.id == kInvalid && device.type == kInvalid;
}
