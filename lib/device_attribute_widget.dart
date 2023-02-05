import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:hub_mqtt/mqtt_device.dart';

class DeviceAttributeWidget extends StatefulWidget {
  const DeviceAttributeWidget({super.key, required this.selectedDevice});

  final MqttDevice selectedDevice;
  @override
  State<DeviceAttributeWidget> createState() => _DeviceAttributeWidgetState();
}

class _DeviceAttributeWidgetState extends State<DeviceAttributeWidget> {
  @override
  Widget build(BuildContext context) {
    return Table(
      children: [..._mqttSelectedDeviceAttribValues()],
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
