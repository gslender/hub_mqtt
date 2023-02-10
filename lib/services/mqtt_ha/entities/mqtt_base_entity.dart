// ignore_for_file: constant_identifier_names

import 'package:events_emitter/events_emitter.dart';
import '/services/mqtt_ha/mqtt_device.dart';
import '/services/mqtt_ha/mqtt_discovery.dart';
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

const String k_ON = 'ON';
const String k_OFF = 'OFF';
const String k_LOCK = 'CLOSE';
const String k_UNLOCK = 'OPEN';
const String k_CLOSE = 'CLOSE';
const String k_OPEN = 'OPEN';
const String k_STOP = 'STOP';
const String k_JAMMED = 'JAMMED';
const String k_LOCKED = 'LOCKED';
const String k_LOCKING = 'LOCKING';
const String k_UNLOCKED = 'UNLOCKED';
const String k_UNLOCKING = 'UNLOCKING';
const String k_closed = 'closed';
const String k_closing = 'closing';
const String k_open = 'open';
const String k_opening = 'opening';
const String k_stopped = 'stopped';

const String k_payload_on = 'payload_on';
const String k_payload_off = 'payload_off';
const String k_payload_lock = 'payload_lock';
const String k_payload_unlock = 'payload_unlock';
const String k_payload_close = 'payload_close';
const String k_payload_open = 'payload_open';
const String k_payload_stop = 'payload_stop';

const String k_state_off = 'state_off';
const String k_state_on = 'state_on';
const String k_state_jammed = 'state_jammed';
const String k_state_locked = 'state_locked';
const String k_state_locking = 'state_locking';
const String k_state_unlocked = 'state_unlocked';
const String k_state_unlocking = 'state_unlocking';
const String k_state_closed = 'state_closed';
const String k_state_closing = 'state_closing';
const String k_state_open = 'state_open';
const String k_state_opening = 'state_opening';
const String k_state_stopped = 'state_stopped';

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
