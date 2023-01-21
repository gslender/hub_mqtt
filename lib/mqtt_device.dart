import 'package:hub_mqtt/utils.dart';

import 'package:hub_mqtt/device.dart';

class MqttDevice extends Device {
  MqttDevice({
    required String id,
    required String name,
    required String type,
  }) : super(id: id, name: name, type: type);

  String stateTopic = '';
  String attrTopic = '';
  String unitOfMeasurement = '';
  DeviceDetails deviceDetails = DeviceDetails();

  factory MqttDevice.invalid() => MqttDevice(id: 'invalid', name: 'invalid', type: 'invalid');

  factory MqttDevice.fromTopicConfig({required String topic, required String config}) {
    if (!Utils.isValidJson(config)) return MqttDevice.invalid();

    final newDevice = MqttDevice(
      id: Utils.getFlatJsonPropString(config, 'unique_id') ?? 'unknown',
      name: Utils.getFlatJsonPropString(config, 'name') ?? 'unknown',
      type: 'unknown',
    );
    newDevice.lastupdated = DateTime.now().millisecondsSinceEpoch;
    newDevice.stateTopic = Utils.getFlatJsonPropString(config, 'state_topic') ?? '';
    newDevice.attrTopic = Utils.getFlatJsonPropString(config, 'json_attr_t') ??
        Utils.getFlatJsonPropString(config, 'json_attributes_topic') ??
        '';
    newDevice.unitOfMeasurement = Utils.getFlatJsonPropString(config, 'unit_of_measurement') ?? '';
    newDevice.deviceDetails = DeviceDetails.fromJson(json: Utils.getFlatJsonPropDynamic(config, 'device') ?? {});
    return newDevice;
  }
}

class DeviceDetails {
  DeviceDetails();
  String configurationUrl = '';
  String identifiers = '';
  String manufacturer = '';
  String model = '';
  String swVersion = '';
  String name = '';

  factory DeviceDetails.fromJson({required dynamic json}) {
    DeviceDetails dd = DeviceDetails();
    String jsonStr = Utils.toJsonString(json);
    dd.configurationUrl = Utils.getFlatJsonPropString(jsonStr, 'configuration_url') ?? '';
    dd.identifiers = Utils.getFlatJsonPropString(jsonStr, 'identifiers') ?? '';
    dd.manufacturer = Utils.getFlatJsonPropString(jsonStr, 'manufacturer') ?? '';
    dd.model = Utils.getFlatJsonPropString(jsonStr, 'model') ?? '';
    dd.swVersion = Utils.getFlatJsonPropString(jsonStr, 'sw_version') ?? '';
    dd.name = Utils.getFlatJsonPropString(jsonStr, 'name') ?? '';
    return dd;
  }

  @override
  String toString() => '$name [$manufacturer $model $swVersion]';
}
