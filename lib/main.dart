import 'package:flutter/material.dart';
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
  String buttonTitleState = 'RECONNECT';
  final TextEditingController hostname =
      TextEditingController(text: '192.168.1.110');
  final TextEditingController username = TextEditingController(text: '');
  final TextEditingController password = TextEditingController(text: '');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: buttonTitleState,
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
          const Spacer()
        ],
      ),
    );
  }

  _queryMQTT() {
    debugPrint('_queryMQTT ${hostname.text} ${username.text} ${password.text}');
    final client = MqttServerClient(hostname.text, widget.title);
    client.logging(on: true);
    client.connect(username.text, password.text);
  }
}
