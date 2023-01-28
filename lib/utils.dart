import 'dart:convert';

class Utils {
  static String toJsonString(dynamic j) => json.encoder.convert(j);

  static bool isValidJson(String? jsonString, [bool debug = false]) {
    if (jsonString == null) return false;
    try {
      json.decode(jsonString) as Map<String, dynamic>;
      return true;
    } catch (e) {
      if (debug) print(e);
    }
    return false;
  }

  static Map<String, dynamic> toJsonMap(String jsonString) {
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (_) {}
    return {};
  }

  static dynamic getFlatJsonPropDynamic(String jsonStr, String prop) {
    try {
      var data = json.decode(jsonStr) as Map<String, dynamic>;
      return data[prop];
    } catch (_) {}
    return null;
  }

  static String? getFlatJsonPropString(String jsonStr, String prop) {
    try {
      var data = json.decode(jsonStr) as Map<String, dynamic>;
      return data[prop] as String;
    } catch (_) {}
    return null;
  }

  static double? getFlatJsonPropDouble(String jsonStr, String prop) {
    try {
      var data = json.decode(jsonStr) as Map<String, dynamic>;
      return data[prop] as double;
    } catch (_) {}
    return null;
  }

  static bool? getFlatJsonPropBool(String jsonStr, String prop) {
    try {
      var data = json.decode(jsonStr) as Map<String, dynamic>;
      return data[prop] as bool;
    } catch (_) {}
    return null;
  }

  static String _setFlatJsonPropString(String jsonStr, String prop, dynamic value) {
    if (!isValidJson(jsonStr)) jsonStr = '{}';
    try {
      var data = json.decode(jsonStr) as Map<String, dynamic>;
      data[prop] = value;
      return json.encode(data);
    } catch (_) {}
    return jsonStr;
  }

  static String setFlatJsonPropString(String jsonStr, String prop, String value) =>
      _setFlatJsonPropString(jsonStr, prop, value);

  static String setFlatJsonPropDouble(String jsonStr, String prop, double value) =>
      _setFlatJsonPropString(jsonStr, prop, value);

  static String setFlatJsonPropBool(String jsonStr, String prop, bool value) =>
      _setFlatJsonPropString(jsonStr, prop, value);
}
