import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ItemsCache {
  static const String _key = 'cached_items_raw';

  /// Save the raw item list (as the server sent it)
  static Future<void> save(List<dynamic> rawItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(rawItems));
    } catch (_) {
      // Cache failure must never break the app
    }
  }

  /// Load the cached list, or null if nothing is cached
  static Future<List<dynamic>?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return null;
    }
  }
}