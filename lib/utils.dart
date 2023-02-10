import 'dart:convert';
import 'dart:math';

class Utils {
  // ignore: avoid_print
  static loginfo(String msg) => print(msg);
  static bool isValidJson(String? jsonString, [bool debug = false]) {
    if (jsonString == null) return false;
    try {
      json.decode(jsonString) as Map<String, dynamic>;
      return true;
    } catch (e) {
      if (debug) loginfo(e.toString());
    }
    return false;
  }

  static Map<String, dynamic> toJsonMap(String jsonString) {
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (_) {}
    return {};
  }

  static String trim(String str, String trim) {
    if (str.startsWith(trim)) str = str.substring(trim.length);
    if (str.endsWith(trim)) str = str.substring(0, str.length - trim.length);
    return str;
  }

  static String limitString(String payloadStr, int i) =>
      payloadStr.length < i ? payloadStr : '${payloadStr.substring(0, min(i, payloadStr.length))}...';

  static bool containsIgnoreCase<T>(Iterable<String> strings, String match) {
    final String m = match.toLowerCase();
    for (String s in strings) {
      if (s.toLowerCase() == m) return true;
    }
    return false;
  }
}
