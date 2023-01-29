import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hub_mqtt/enums.dart';
import 'package:hub_mqtt/mqtt_device.dart';
import 'package:hub_mqtt/mqtt_discovery.dart';

const String apptitle = 'HUB-MQTT';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: apptitle,
    theme: ThemeData(
      primarySwatch: Colors.grey,
    ),
    home: const HubMQTT(title: apptitle),
  ));
}

class HubMQTT extends StatefulWidget {
  const HubMQTT({super.key, required this.title});
  final String title;

  @override
  State<HubMQTT> createState() => _HubMQTTState();
}

class _HubMQTTState extends State<HubMQTT> {
  AppStatus appStatus = AppStatus.none;
  final TextEditingController hostname = TextEditingController(text: '192.168.1.110');
  final TextEditingController username = TextEditingController(text: '');
  final TextEditingController password = TextEditingController(text: '');
  final List<MqttDevice> _devices = [];
  final MqttDiscovery discovery = MqttDiscovery();
  MqttDevice? selectedDevice;

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (selectedDevice != null) setState(() {});
    });
  }

  @override
  void dispose() {
    discovery.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.restart_alt),
            label: Text('Discover'.toUpperCase()),
            onPressed: () => _queryMQTT(),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: TextFormField(
                  controller: hostname,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.device_hub),
                    labelText: 'HUB IP ADDR',
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: username,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.person),
                    labelText: 'USERNAME',
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  obscureText: true,
                  controller: password,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.lock),
                    labelText: 'PASSWORD',
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
          Expanded(child: _deviceListProgress()),
        ],
      ),
    );
  }

  Widget _mqttDeviceListItem(MqttDevice device) {
    return Card(
      child: ListTile(
        onTap: () => selectedDevice = device,
        title: Text('name:${device.name} id:${device.id}'),
      ),
    );
  }

  List<TableRow> _mqttDeviceAttribValues() {
    if (selectedDevice == null) return [];
    List<TableRow> table = [];
    selectedDevice!.getImmutableAttribValues().forEach((key, value) {
      table.add(TableRow(children: [
        Text(key),
        Text(value),
      ]));
    });
    return table;
  }

  Widget _deviceListProgress() {
    switch (appStatus) {
      case AppStatus.failed:
        return const Center(child: Text('CONNECTION ERROR - FAILED!'));
      case AppStatus.notauthorised:
        return const Center(child: Text('CONNECTION ERROR - NOT AUTHORISED!'));
      case AppStatus.connecting:
        return const Center(child: CircularProgressIndicator());
      case AppStatus.connected:
        return SelectionArea(
          child: Row(
            children: [
              Expanded(
                child: ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      return _mqttDeviceListItem(_devices[index]);
                    }),
              ),
              Expanded(
                  child: Align(
                alignment: Alignment.topCenter,
                child: Table(
                  children: [..._mqttDeviceAttribValues()],
                ),
              )),
            ],
          ),
        );
      case AppStatus.none:
      default:
        return Container();
    }
  }

  _queryMQTT() {
    debugPrint('_queryMQTT ${hostname.text} ${username.text} ${'*' * password.text.length}');
    setState(() {
      selectedDevice = null;
      appStatus = AppStatus.connecting;
    });

    discovery.connect(
      hostname: hostname.text,
      clientId: widget.title,
      username: username.text,
      password: password.text,
      connectedCallback: () => setState(() {
        appStatus = AppStatus.connected;
        _devices.clear();
      }),
      failedCallback: () => setState(() {
        appStatus = AppStatus.failed;
      }),
      notAuthorizedCallback: () => setState(() {
        appStatus = AppStatus.notauthorised;
      }),
      devicesUpdatedCallback: () => setState(() {
        _devices.clear();
        _devices.addAll(discovery.getImmutableDevices().values);
      }),
    );
  }
}
