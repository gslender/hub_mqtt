import 'package:flutter/material.dart';
import 'package:hub_mqtt/enums.dart';
import 'package:hub_mqtt/mqtt_device.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

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
        title: Text('name:${device.name} id:${device.id}'),
        subtitle: Text(device.getImmutableAttribValues().toString()),
      ),
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
        return ListView.builder(
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              return _mqttDeviceListItem(_devices[index]);
            });
      case AppStatus.none:
      default:
        return Container();
    }
  }

  _queryMQTT() {
    debugPrint('_queryMQTT ${hostname.text} ${username.text} ${password.text}');
    setState(() {
      appStatus = AppStatus.connecting;
    });
    final client = MqttServerClient(hostname.text, widget.title);
    client.logging(on: false);
    client.connectTimeoutPeriod = 1000;
    // client.secure = true; // does not work and peer resets connection
    client.connect(username.text, password.text).then((status) {
      debugPrint('_queryMQTT MqttClientConnectionStatus=$status');
      if (status == null) return;
      switch (status.state) {
        case MqttConnectionState.faulted:
        case MqttConnectionState.disconnecting:
        case MqttConnectionState.disconnected:
          break;
        case MqttConnectionState.connecting:
        case MqttConnectionState.connected:
          setState(() {
            appStatus = AppStatus.connected;
            _devices.clear();
          });

          client.subscribe('homeassistant/#', MqttQos.atMostOnce);
          // ignore that for now, that is for compatibility and not needed at this state.
          // client.subscribe('discovery/#', MqttQos.atMostOnce);
          // homeassistant/[DEVICE_TYPE]/[DEVICE_ID]/[OBJECT_ID]/config
          final builder = MqttClientPayloadBuilder().addString('online');
          client.publishMessage('homeassistant/status', MqttQos.exactlyOnce, builder.payload!);

          client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
            if (c == null) return;
            final MqttReceivedMessage msg = c.first;
            if (msg.topic == 'homeassistant/status') return;
            final publishMessage = msg.payload as MqttPublishMessage;
            final config = MqttPublishPayload.bytesToStringAsString(publishMessage.payload.message);
            setState(() {
              _devices.add(MqttDevice.fromTopicConfig(topic: msg.topic, config: config));
            });
          });
          break;
      }
    }, onError: (_) {
      var connectionStatus = client.connectionStatus;
      debugPrint('_queryMQTT $connectionStatus');
      if (connectionStatus == null) return;
      if (connectionStatus.returnCode == MqttConnectReturnCode.notAuthorized) {
        setState(() {
          appStatus = AppStatus.notauthorised;
        });
      }

      if (connectionStatus.returnCode == MqttConnectReturnCode.noneSpecified) {
        setState(() {
          appStatus = AppStatus.failed;
        });
      }
    });
  }
}
