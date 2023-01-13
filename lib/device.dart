class Device {
  Device({
    required this.id,
    required this.name,
    required this.type,
    this.label = '',
  }) {
    _mapAttribValues['_name'] = name;
    _mapAttribValues['_label'] = label;
    _mapAttribValues['_id'] = id;
  }

  Device.notfound()
      : id = 'notfound',
        name = '',
        label = '',
        type = '';

  final String id;
  final String label;
  int lastupdated = 0;
  final String name;
  final String type;

  final Set<String> _commands = {};
  final Map<String, String> _mapAttribValues = {};

  @override
  String toString() {
    return 'id:$id name:$name label:$label type:$type _mapAttribValues:$_mapAttribValues';
  }

  factory Device.clone(Device copy, {String? room}) {
    final hd = Device(
      id: copy.id,
      name: copy.name,
      type: copy.type,
      label: copy.label,
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

  Iterable<String> getAttributes() => _mapAttribValues.keys;

  Map<String, String> getImmutableAttribValues() =>
      Map<String, String>.unmodifiable(_mapAttribValues);

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
