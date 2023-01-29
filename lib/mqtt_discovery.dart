import 'package:flutter/foundation.dart';
import 'package:hub_mqtt/ha_const.dart';
import 'package:hub_mqtt/mqtt_device.dart';
import 'package:hub_mqtt/utils.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttDiscovery {
  Map<String, MqttDevice> _mapDevices = {};
  Map<String, MqttDevice> getImmutableDevices() => Map<String, MqttDevice>.unmodifiable(_mapDevices);

  connect({
    required String hostname,
    String clientId = 'MqttDiscovery',
    required String username,
    required String password,
    VoidCallback? connectedCallback,
    VoidCallback? failedCallback,
    VoidCallback? notAuthorizedCallback,
    VoidCallback? devicesUpdatedCallback,
  }) {
    final client = MqttServerClient(hostname, clientId);
    client.logging(on: false);
    client.connectTimeoutPeriod = 1000;
    // client.secure = true; // does not work and peer resets connection
    client.connect(username, password).then((status) {
      print('$clientId MqttClientConnectionStatus=$status');
      if (status == null) return;
      switch (status.state) {
        case MqttConnectionState.faulted:
        case MqttConnectionState.disconnecting:
        case MqttConnectionState.disconnected:
          break;
        case MqttConnectionState.connecting:
        case MqttConnectionState.connected:
          if (connectedCallback != null) connectedCallback();
          _mapDevices.clear();

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
            Map<String, String> attrVal = _attrValFromTopicConfig(msg.topic, config);
            if (attrVal.containsKey(MqttDevice.kInvalid)) {
              _mapDevices['${_mapDevices.length + 1}${MqttDevice.kInvalid}'] =
                  MqttDevice.invalid(attrVal[MqttDevice.kInvalid]);
            } else {
              String component = _componentFromTopic(msg.topic);
              MqttIdPrefix mip = _idPrefixFromTopic(msg.topic);
              if (mip.id == MqttDevice.kInvalid) {
                //MqttDevice.kInvalid: 'INVALID UID $topic'
              } else {
                if (_mapDevices.containsKey(mip.id)) {
                  // concat devices
                  print('_mapDevices.containsKey ${mip.id}');
                  MqttDevice mqttDevice = _mapDevices[mip.id]!;
                  attrVal.forEach((key, value) {
                    if (mqttDevice.getAttributes().contains(key)) {
                      String was = mqttDevice.getValue(key);
                      if (was != value) print('key: $key was:$was now: $value');
                    }
                    if (key.startsWith('device_')) mip.prefix = '';
                    mqttDevice.addAttribValue('${mip.prefix}$key', value);
                  });
                } else {
                  // new device
                  String name = '${attrVal['device_name'] ?? msg.topic} $component';
                  MqttDevice mqttDevice = MqttDevice(
                    id: mip.id,
                    name: name,
                    type: _componentFromTopic(msg.topic),
                  );
                  attrVal.forEach((key, value) {
                    if (key.startsWith('device_')) mip.prefix = '';
                    mqttDevice.addAttribValue('${mip.prefix}$key', value);
                  });
                  _mapDevices[mip.id] = mqttDevice;
                }
              }
            }
            if (devicesUpdatedCallback != null) devicesUpdatedCallback();
          });
          break;
      }
    }, onError: (_) {
      var connectionStatus = client.connectionStatus;
      print('$clientId $connectionStatus');
      if (connectionStatus == null) return;
      if (connectionStatus.returnCode == MqttConnectReturnCode.notAuthorized) {
        if (notAuthorizedCallback != null) notAuthorizedCallback();
      }

      if (connectionStatus.returnCode == MqttConnectReturnCode.noneSpecified) {
        if (failedCallback != null) failedCallback();
      }
    });
  }

  Map<String, String> _attrValFromTopicConfig(String topic, String config) {
    if (!Utils.isValidJson(config)) {
      print('!!! INVALID CONFIG !!! - $config');
      return {MqttDevice.kInvalid: 'INVALID CONFIG $topic'};
    }
    String component = _componentFromTopic(topic);
    if (component == MqttDevice.kInvalid) {
      print('!!! INVALID COMPONENT !!! - $topic');
      return {MqttDevice.kInvalid: 'INVALID COMPONENT $topic'};
    }

    final Map<String, dynamic> json = {};

    Utils.toJsonMap(config).forEach((key, value) {
      if (kAbbreviations.containsKey(key)) {
        json[kAbbreviations[key]!] = value;
      } else {
        json[key] = value;
      }
    });

    Map<String, String> attrVal = {};
    _convertJsonToAttribValue(attrVal, json, 'config');

    // MqttDevice newDevice = MqttDevice(
    //   id: id,
    //   name: name,
    //   type: component,
    // );

    // newDevice.lastupdated = DateTime.now().millisecondsSinceEpoch;
    // attrVal.forEach((key, value) => newDevice.addAttribValue(key, value));

    return attrVal;
  }

  void _convertJsonToAttribValue(Map<String, String> attrVal, Map<String, dynamic> json, String prefix) {
    json.forEach((k, v) {
      String key = k;

      Map<String, String> abbrev = kAbbreviations;
      if (prefix == 'device') abbrev = kDeviceAbbreviations;

      if (abbrev.containsKey(k)) {
        key = abbrev[k]!;
      }
      String value = v.toString();
      if (value.startsWith('{') && value.endsWith('}')) {
        if (v is Map<String, dynamic>) {
          _convertJsonToAttribValue(attrVal, v, key);
        } else {
          print('prefix:$prefix k:$k v:$v');
          attrVal['${prefix}_$key'] = value.toString();
        }
      } else {
        attrVal['${prefix}_$key'] = value.toString();
      }
    });
  }

  String _componentFromTopic(String topic) {
    if (topic.contains('/')) {
      List<String> leafs = topic.split('/');
      if (kSupportedComponents.contains(leafs[1])) return leafs[1];
    }
    return MqttDevice.kInvalid;
  }

  MqttIdPrefix _idPrefixFromTopic(String topic) {
    MqttIdPrefix idPrefix = MqttIdPrefix();
    if (topic.contains('/')) {
      List<String> leafs = topic.split('/');
      if (leafs.length > 2 && leafs.last == 'config') {
        // short example is homeassistant/light/lamp/config
        // long example is  homeassistant/sensor/0x00124b001b78133/battery/config
        leafs.removeLast(); // remove config from the end
        leafs.removeAt(0); // homeassistant from start
        String componentTopic = leafs.removeAt(0); // light (or) sensor
        String nodeTopic = leafs.removeAt(0); // lamp (or) 0x00124b001b78133
        idPrefix.id = '${componentTopic}_$nodeTopic';
        if (leafs.isNotEmpty) {
          idPrefix.prefix = '${leafs.removeAt(0)}_';
        }
      }
    }
    return idPrefix;
  }
}

class MqttIdPrefix {
  String id = MqttDevice.kInvalid;
  String prefix = '';
}
