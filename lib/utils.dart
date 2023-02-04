import 'dart:convert';
import 'dart:math';

class Utils {
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
