import 'package:flutter/material.dart';
import 'package:hub_mqtt/device.dart';
import 'package:hub_mqtt/device_attributes_widget.dart';
import 'package:hub_mqtt/device_commands_widget.dart';
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
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
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

  Widget _getComponentIcon(DevicePurpose type) {
    switch (type) {
      case DevicePurpose.aLight:
        return const Icon(Icons.light);
      case DevicePurpose.aSensor:
        return const Icon(Icons.sensors);
      case DevicePurpose.aBinarySensor:
        return const Icon(Icons.sync_alt_rounded);
      case DevicePurpose.aTag:
        return const Icon(Icons.label);
      case DevicePurpose.aThermostat:
        return const Icon(Icons.device_thermostat);
      case DevicePurpose.aBlind:
        return const Icon(Icons.door_sliding);
      case DevicePurpose.aUpdate:
        return const Icon(Icons.update);
      case DevicePurpose.aSwitch:
        return const Icon(Icons.toggle_off_outlined);
      case DevicePurpose.aFan:
        return const Icon(Icons.air);
      case DevicePurpose.aCamera:
        return const Icon(Icons.camera);
      case DevicePurpose.aLock:
        return const Icon(Icons.lock);
      case DevicePurpose.aAlarmControlPanel:
        return const Icon(Icons.alarm);
      case DevicePurpose.aButton:
        return const Icon(Icons.smart_button);
      case DevicePurpose.aDeviceAutomation:
        return const Icon(Icons.settings);
      case DevicePurpose.aDeviceTracker:
        return const Icon(Icons.developer_board);
      case DevicePurpose.aHumidifier:
        return const Icon(Icons.cloudy_snowing);
      case DevicePurpose.aNumber:
        return const Icon(Icons.numbers);
      case DevicePurpose.aScene:
        return const Icon(Icons.group_work);
      case DevicePurpose.aSiren:
        return const Icon(Icons.speaker);
      case DevicePurpose.aSelect:
        return const Icon(Icons.select_all);
      case DevicePurpose.aText:
        return const Icon(Icons.text_fields);
      case DevicePurpose.aVacuum:
        return const Icon(Icons.cleaning_services);
      default:
    }
    return const Icon(Icons.question_mark);
  }

  Widget _mqttDeviceListItem(MqttDevice device) {
    return Card(
      color: device == selectedDevice ? Colors.black87 : null,
      child: ListTile(
        selectedColor: Colors.white,
        selected: device == selectedDevice,
        leading: _getComponentIcon(device.purpose ?? DevicePurpose.unknown),
        onTap: () => setState(() {
          selectedDevice = device;
          selectedTopic = null;
        }),
        title: Text(device.name),
        subtitle: Text('purpose:${_shortPurpose(device.determinePurpose())}  ID:${device.id}'),
      ),
    );
  }

  String _shortPurpose(DevicePurpose purpose) =>
      purpose == DevicePurpose.unknown ? 'UNKNOWN!' : purpose.toString().split('.').last.substring(1);

  Widget _mqttSelectedDeviceDetails() {
    if (selectedDevice == null) return Container();
    return SingleChildScrollView(
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: 2 + (selectedDevice?.getTopics().length ?? 0),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Card(
                color: selectedTopic == null && selectedIndex == 0 ? Colors.black54 : null,
                child: ListTile(
                  leading: const Icon(Icons.chevron_right),
                  dense: true,
                  selectedColor: Colors.white,
                  selected: selectedTopic == null && selectedIndex == 0,
                  onTap: () => setState(() {
                    selectedIndex = 0;
                    selectedTopic = null;
                  }),
                  title: const Text('Attributes and Variables'),
                ),
              );
            }
            if (index == 1) {
              return Card(
                color: selectedTopic == null && selectedIndex == 1 ? Colors.black54 : null,
                child: ListTile(
                  leading: const Icon(Icons.chevron_right),
                  dense: true,
                  selectedColor: Colors.white,
                  selected: selectedTopic == null && selectedIndex == 1,
                  onTap: () => setState(() {
                    selectedIndex = 1;
                    selectedTopic = null;
                  }),
                  title: const Text('Commands'),
                ),
              );
            }
            String? topic = selectedDevice?.getTopics()[index - 2];
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
          }),
    );
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
        Widget bottomRightWidget = Container();
        if (selectedDevice != null) {
          if (selectedTopic == null) {
            if (selectedIndex == 0) {
              bottomRightWidget = SingleChildScrollView(
                  child: DeviceAttributesWidget(key: UniqueKey(), selectedDevice: selectedDevice!));
            }
            if (selectedIndex == 1) {
              bottomRightWidget =
                  SingleChildScrollView(child: DeviceCommandsWidget(key: UniqueKey(), selectedDevice: selectedDevice!));
            }
          } else {
            bottomRightWidget = Container(
                padding: const EdgeInsets.all(4),
                child: JsonConfig(
                  data: JsonConfigData(style: const JsonStyleScheme(depth: 2)),
                  child: JsonView(json: selectedDevice?.getTopicJson(selectedTopic)),
                ));
          }
        }
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
                    Flexible(
                        flex: 1,
                        fit: FlexFit.tight,
                        child: Card(
                          elevation: 5,
                          child: _mqttSelectedDeviceDetails(),
                        )),
                    Flexible(
                      flex: 1,
                      fit: FlexFit.tight,
                      child: Card(elevation: 5, child: bottomRightWidget),
                    )
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
      selectedTopic = null;
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
