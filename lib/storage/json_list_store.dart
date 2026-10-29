import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class JsonListStore<T> {
  JsonListStore({
    required this.prefs,
    required this.key,
    required this.fromJson,
    required this.toJson,
    required this.seed,
  });

  final SharedPreferences prefs;
  final String key;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;
  final List<T> seed;

  List<T> load() {
    final raw = prefs.getString(key);
    if (raw == null) {
      final initial = [...seed];
      save(initial);
      return initial;
    }
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      final initial = [...seed];
      save(initial);
      return initial;
    }
  }

  Future<void> save(List<T> items) async {
    await prefs.setString(key, jsonEncode(items.map(toJson).toList()));
  }
}
