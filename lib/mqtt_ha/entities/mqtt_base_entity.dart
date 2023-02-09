// ignore_for_file: constant_identifier_names

import 'package:events_emitter/events_emitter.dart';
import 'package:hub_mqtt/mqtt_ha/mqtt_device.dart';
import 'package:hub_mqtt/mqtt_ha/mqtt_discovery.dart';
import 'package:jinja/jinja.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

const String k_value_template = 'value_template';
const String k_value_json = 'value_json';
const String k_online = 'online';
const String k_offline = 'offline';
const String k_payload_available = 'payload_available';
const String k_payload_not_available = 'payload_not_available';
const String k_availability_topic = 'availability_topic';
const String k_availability_template = 'availability_template';
const String k_availability = 'availability';
const String k_availability_mode = 'availability_mode';

abstract class MqttBaseEntity {
  MqttBaseEntity(this.mqttClient, this.events, this.topicParts, this.jsonCfg);

  final MqttServerClient mqttClient;
  final EventEmitter events;
  final MqttTopicParts topicParts;
  final dynamic jsonCfg;
  final jinjaEnv = Environment(filters: {
    'int': (Object? value, {int defaultValue = 0, int base = 10}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value, radix: base) ?? defaultValue;
      throw TypeError();
    }
  });
  List<Availability> availabilityList = [];

  List<String> getStateTopicTags();
  Map<String, String> getStateTopicTemplateTags();
  List<String> getJsonAttributesTopicTags();
  List<String> getCommandTopicTags();
  String getNameDefault();

  void bind(MqttDevice mqttDevice, bool useEntityTopicTypeinAttrib);
}

class Availability {
  String topic = '';
  String payloadAvailable = k_online;
  String payloadNotAvailable = k_offline;
  String valueTemplate = '';
  bool isAvailable = false;

  @override
  String toString() =>
      'topic=$topic payloadAvailable=$payloadAvailable payloadNotAvailable=$payloadNotAvailable valueTemplate=$valueTemplate';
}
