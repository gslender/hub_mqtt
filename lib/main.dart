import 'package:flutter/material.dart';
import 'package:hub_mqtt/enums.dart';
import 'package:hub_mqtt/mqtt_device.dart';
import 'package:hub_mqtt/mqtt_discovery.dart';
import 'package:json_view/json_view.dart';

const String apptitle = 'hub_mqtt';

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
  String? selectedTopic;

  @override
  void initState() {
    super.initState();
    // Timer.periodic(const Duration(milliseconds: 100), (timer) {
    //   if (selectedDevice != null) setState(() {});
    // });
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

  Widget _getComponentIcon(String type) {
    switch (type) {
      case 'light':
        return const Icon(Icons.light);
      case 'sensor':
        return const Icon(Icons.sensors);
      case 'binary_sensor':
        return const Icon(Icons.sync_alt_rounded);
      case 'tag':
        return const Icon(Icons.label);
      case 'climate':
        return const Icon(Icons.device_thermostat);
      case 'cover':
        return const Icon(Icons.door_sliding);
      case 'update':
        return const Icon(Icons.update);
      case 'switch':
        return const Icon(Icons.toggle_off_outlined);
      case 'fan':
        return const Icon(Icons.air);
      case 'alarm_control_panel':
        return const Icon(Icons.alarm);
      case 'button':
        return const Icon(Icons.smart_button);
      case 'camera':
        return const Icon(Icons.camera);
      case 'device_automation':
        return const Icon(Icons.settings);
      case 'device_tracker':
        return const Icon(Icons.developer_board);
      case 'humidifier':
        return const Icon(Icons.cloudy_snowing);
      case 'lock':
        return const Icon(Icons.lock);
      case 'number':
        return const Icon(Icons.numbers);
      case 'scene':
        return const Icon(Icons.group_work);
      case 'siren':
        return const Icon(Icons.speaker);
      case 'select':
        return const Icon(Icons.select_all);
      case 'text':
        return const Icon(Icons.text_fields);
      case 'vacuum':
        return const Icon(Icons.cleaning_services);
    }
    return const Icon(Icons.question_mark);
  }

  Widget _mqttDeviceListItem(MqttDevice device) {
    return Card(
      color: device == selectedDevice ? Colors.black87 : null,
      child: ListTile(
        selectedColor: Colors.white,
        selected: device == selectedDevice,
        leading: _getComponentIcon(device.type),
        onTap: () => setState(() {
          selectedDevice = device;
          selectedTopic = null;
        }),
        title: Text(device.name),
        subtitle: Text('type:${device.type} id:${device.id}'),
      ),
    );
  }

  Widget _mqttSelectedDeviceDetails() {
    if (selectedDevice == null) return Container();
    return ListView.builder(
        shrinkWrap: true,
        itemCount: 1 + (selectedDevice?.getTopics().length ?? 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              color: selectedTopic == null ? Colors.black54 : null,
              child: ListTile(
                leading: const Icon(Icons.chevron_right),
                dense: true,
                selectedColor: Colors.white,
                selected: selectedTopic == null,
                onTap: () => setState(() => selectedTopic = null),
                title: const Text('Attributes and Variables'),
              ),
            );
          }
          String? topic = selectedDevice?.getTopics()[index - 1];
          return Card(
            color: topic == selectedTopic ? Colors.black54 : null,
            child: ListTile(
              leading: const Icon(Icons.chevron_right),
              dense: true,
              selectedColor: Colors.white,
              selected: topic == selectedTopic,
              onTap: () => setState(() => selectedTopic = topic),
              title: Text('Config JSON: $topic'),
            ),
          );
        });
  }

  // JsonView(json: data)

  List<TableRow> _mqttSelectedDeviceAttribValues() {
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
        return Container(
          padding: const EdgeInsets.all(4),
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
                child: Column(
                  children: [
                    Card(elevation: 5, child: _mqttSelectedDeviceDetails()),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Card(
                          elevation: 5,
                          child: selectedTopic == null
                              ? SingleChildScrollView(
                                  child: Table(
                                  children: [..._mqttSelectedDeviceAttribValues()],
                                ))
                              : Container(
                                  padding: const EdgeInsets.all(4),
                                  child: JsonConfig(
                                    data: JsonConfigData(style: const JsonStyleScheme(depth: 2)),
                                    child: JsonView(json: selectedDevice?.getTopicJson(selectedTopic)),
                                  ))),
                    ),
                  ],
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
