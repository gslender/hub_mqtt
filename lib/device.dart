class Device {
  Device({
    required this.id,
    required this.name,
    required String type,
    String label = '',
  })  : _label = label,
        _type = type {
    _mapAttribValues['_name'] = name;
    _mapAttribValues['_label'] = label;
    _mapAttribValues['_id'] = id;
    _mapAttribValues['_type'] = type;
  }

  Device.notfound()
      : id = 'notfound',
        name = '',
        _label = '',
        _type = '';

  final String id;
  int lastupdated = 0;
  final String name;
  String _label;
  String _type;

  final Set<String> _commands = {};
  final Map<String, String> _mapAttribValues = {};

  String get label => _label;
  set label(String label) {
    _mapAttribValues['_label'] = label;
    _label = label;
  }

  String get type => _type;

  addType(String type) {
    List<String> types = _type.split(',');
    if (types.contains(type)) return;
    _mapAttribValues['_type'] = '$_type,$type';
    _type = '$_type,$type';
  }

  @override
  String toString() {
    return 'id:$id name:$name label:$_label type:$_type _mapAttribValues:$_mapAttribValues';
  }

  factory Device.clone(Device copy, {String? room}) {
    final hd = Device(
      id: copy.id,
      name: copy.name,
      type: copy._type,
      label: copy._label,
    );
    hd._commands.addAll(copy._commands);
    hd._mapAttribValues.addAll(copy._mapAttribValues);
    hd.lastupdated = copy.lastupdated;
    return hd;
  }

  void addAttribValue(String attrib, String value) {
    lastupdated = DateTime.now().millisecondsSinceEpoch;
    _mapAttribValues[attrib.trim()] = value.trim();
  }

  String getValue(String attrib) => _mapAttribValues[attrib] ?? '';

  Iterable<String> getAttributes() => _mapAttribValues.keys;

  Map<String, String> getImmutableAttribValues() => Map<String, String>.unmodifiable(_mapAttribValues);

  void addCommand(String cmd) => _commands.add(cmd);

  bool hasCommand(String cmd) => _containsIgnoreCase(_commands, cmd);

  Iterable<String> getCommands() => _commands;

  void addLists(Device from) {
    _commands.addAll(from._commands);
    _mapAttribValues.addAll(from._mapAttribValues);
  }

  bool _containsIgnoreCase<T>(Iterable<String> strings, String match) {
    final String m = match.toLowerCase();
    for (String s in strings) {
      if (s.toLowerCase() == m) return true;
    }
    return false;
  }
}
