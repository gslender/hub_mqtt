import 'dart:async';

import 'package:flutter/material.dart';
import '/services/mqtt_ha/mqtt_device.dart';

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
    List<MapEntry<String, String>> attribValues = widget.selectedDevice.getImmutableAttribValues().entries.toList();
    attribValues.sort(((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase())));
    for (MapEntry me in attribValues) {
      table.add(TableRow(children: [
        Text(me.key),
        Text(me.value),
      ]));
    }
    return table;
  }
}
