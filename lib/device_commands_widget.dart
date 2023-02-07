import 'package:flutter/material.dart';
import 'package:hub_mqtt/mqtt_device.dart';

class DeviceCommandsWidget extends StatefulWidget {
  const DeviceCommandsWidget({super.key, required this.selectedDevice});

  final MqttDevice selectedDevice;
  @override
  State<DeviceCommandsWidget> createState() => _DeviceCommandsWidgetState();
}

class _DeviceCommandsWidgetState extends State<DeviceCommandsWidget> {
  @override
  Widget build(BuildContext context) {
    return Table(
      children: [..._mqttSelectedDeviceCommands()],
    );
  }

  List<TableRow> _mqttSelectedDeviceCommands() {
    List<TableRow> table = [];
    // widget.selectedDevice.getImmutableAttribValues().forEach((key, value) {
    widget.selectedDevice.getCommands().forEach((cmd) {
      table.add(TableRow(children: [
        Text(cmd),
      ]));
    });
    return table;
  }
}
