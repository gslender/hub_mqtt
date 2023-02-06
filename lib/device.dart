import 'package:hub_mqtt/utils.dart';

enum DevicePurpose {
  aLight,
  aBlind,
  aSwitch,
  aFan,
  aSolar,
  aThermostat,
  aSensor,
  aDoor,
  aLock,
  aAlarmControlPanel,
  aBinarySensor,
  aCamera,
  aButton,
  aDeviceAutomation,
  aDeviceTracker,
  aHumidifier,
  aNumber,
  aScene,
  aSiren,
  aSelect,
  aTag,
  aText,
  aUpdate,
  aVacuum,
  unknown,
}

class Device {
  Device({
    required this.id,
    required this.name,
    required this.type,
    this.label = '',
    this.room = '',
  }) {
    _mapAttribValues['_name'] = name;
    _mapAttribValues['_label'] = label;
    _mapAttribValues['_id'] = id;
    _mapAttribValues['_room'] = room;
  }

  Device.notfound()
      : id = 'notfound',
        name = '',
        label = '',
        room = '',
        type = '';

  DevicePurpose? purpose;
  final String id;
  final String label;
  final String room;
  int lastupdated = 0;
  final String name;
  final String type;

  final Set<String> _capabilities = {};
  final Set<String> _commands = {};
  final Map<String, String> _mapAttribValues = {};

  @override
  String toString() {
    return 'id:$id name:$name label:$label room:$room type:$type _mapAttribValues:$_mapAttribValues';
  }

  factory Device.clone(Device copy, {String? room}) {
    final hd = Device(
      id: copy.id,
      name: copy.name,
      type: copy.type,
      label: copy.label,
      room: room ?? copy.room,
    );
    hd.purpose = copy.purpose ?? DevicePurpose.unknown;
    hd._capabilities.addAll(copy._capabilities);
    hd._commands.addAll(copy._commands);
    hd._mapAttribValues.addAll(copy._mapAttribValues);
    hd.lastupdated = copy.lastupdated;
    return hd;
  }

  bool purposeKnown() => determinePurpose() != DevicePurpose.unknown;
  bool purposeIsUnknown() => purpose == DevicePurpose.unknown;

  DevicePurpose determinePurpose() {
    purpose = guessPurposeFromCapability();
    if (purposeIsUnknown()) purpose = guessPurposeFromTxt(type);
    if (purposeIsUnknown()) purpose = guessPurposeFromTxt(label);
    if (purposeIsUnknown()) purpose = guessPurposeFromTxt(name);
    return purpose!;
  }

  void addAttribValue(String attrib, String value) {
    lastupdated = DateTime.now().millisecondsSinceEpoch;
    _mapAttribValues[attrib.trim()] = value.trim();
  }

  Iterable<String> getAttributes() => _mapAttribValues.keys;

  Map<String, String> getImmutableAttribValues() => Map<String, String>.unmodifiable(_mapAttribValues);

  void addCommand(String cmd) => _commands.add(cmd);

  bool hasCommand(String cmd) => Utils.containsIgnoreCase(_commands, cmd);

  Iterable<String> getCommands() => _commands;

  void addCapability(String cap) => _capabilities.add(cap);

  void addCapabilities(Iterable<String> caps) => _capabilities.addAll(caps);

  bool hasCapability(String cap) => Utils.containsIgnoreCase(_capabilities, cap);

  Iterable<String> getCapabilities() => _capabilities;

  void addLists(Device from) {
    _capabilities.addAll(from._capabilities);
    _commands.addAll(from._commands);
    _mapAttribValues.addAll(from._mapAttribValues);
    determinePurpose();
  }

  DevicePurpose guessPurposeFromCapability() => DevicePurpose.unknown;

  DevicePurpose guessPurposeFromLocaleTxt(String text, Function(String) localeLang) {
    if (text.toLowerCase().contains(localeLang('light'))) return DevicePurpose.aLight;
    if (text.toLowerCase().contains(localeLang('bulb'))) return DevicePurpose.aLight;
    if (text.toLowerCase().contains(localeLang('blind'))) return DevicePurpose.aBlind;
    if (text.toLowerCase().contains(localeLang('shade'))) return DevicePurpose.aBlind;
    if (text.toLowerCase().contains(localeLang('switch'))) return DevicePurpose.aSwitch;
    if (text.toLowerCase().contains(localeLang('lamp'))) return DevicePurpose.aSwitch;
    if (text.toLowerCase().contains(localeLang('plug'))) return DevicePurpose.aSwitch;
    if (text.toLowerCase().contains(localeLang('thermostat'))) return DevicePurpose.aThermostat;
    if (text.toLowerCase().contains(localeLang('fan'))) return DevicePurpose.aFan;
    if (text.toLowerCase().contains(localeLang('sensor'))) return DevicePurpose.aSensor;
    if (text.toLowerCase().contains(localeLang('weather'))) return DevicePurpose.aSensor;
    if (text.toLowerCase().contains(localeLang('solar'))) return DevicePurpose.aSolar;
    if (text.toLowerCase().contains(localeLang('door'))) return DevicePurpose.aDoor;
    if (text.toLowerCase().contains(localeLang('lock'))) return DevicePurpose.aLock;
    return DevicePurpose.unknown;
  }

  DevicePurpose guessPurposeFromTxt(String text, [Function(String)? localeLang]) {
    DevicePurpose purpose = DevicePurpose.unknown;
    // try LOCALE lang first
    if (localeLang != null) purpose = guessPurposeFromLocaleTxt(text, localeLang);
    // try ENGLISH lang last
    if (purpose == DevicePurpose.unknown) purpose = guessPurposeFromLocaleTxt(text, (english) => english);
    return purpose;
  }
}
