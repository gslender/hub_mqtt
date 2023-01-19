import 'package:hub_mqtt/device.dart';

class MqttDevice extends Device {
  MqttDevice({
    required id,
    required name,
    required type,
  }) : super(id: id, name: name, type: type);

  factory MqttDevice.fromTopicConfig({required String topic, required String config}) {
    final newDevice = MqttDevice(
      id: 'id',
      name: topic,
      type: 'type',
    );
    newDevice.lastupdated = DateTime.now().millisecondsSinceEpoch;
    return newDevice;
  }
}
