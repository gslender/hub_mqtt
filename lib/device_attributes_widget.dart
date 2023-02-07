import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hub_mqtt/mqtt_device.dart';

class DeviceAttributesWidget extends StatefulWidget {
  const DeviceAttributesWidget({super.key, required this.selectedDevice});

  final MqttDevice selectedDevice;
  @override
  State<DeviceAttributesWidget> createState() => _DeviceAttributesWidgetState();
}

class _DeviceAttributesWidgetState extends State<DeviceAttributesWidget> {
  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Table(
        children: [..._mqttSelectedDeviceAttribValues()],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) setState(() {});
    });
  }

  List<TableRow> _mqttSelectedDeviceAttribValues() {
    List<TableRow> table = [];
    widget.selectedDevice.getImmutableAttribValues().forEach((key, value) {
      table.add(TableRow(children: [
        Text(key),
        Text(value),
      ]));
    });
    return table;
  }
}
