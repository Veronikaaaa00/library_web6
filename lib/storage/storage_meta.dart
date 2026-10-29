import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Версия формата локального хранилища. При смене схемы поднимаем номер
/// и ключи сущностей (books_v2 и т.п.), чтобы старые данные не роняли приложение.
class StorageMeta {
  StorageMeta._(this.prefs, {required this.resetMessage});

  static const currentVersion = 2;
  static const _metaKey = 'storage_meta_v2';
  static const _legacyMetaKey = 'storage_meta_v1';

  final SharedPreferences prefs;
  final String? resetMessage;

  static Future<StorageMeta> open(SharedPreferences prefs) async {
    String? message;
    final raw = prefs.getString(_metaKey);
    if (raw == null) {
      // Старый формат или первый запуск.
      final hadLegacy =
          prefs.containsKey('books_v1') ||
          prefs.containsKey(_legacyMetaKey) ||
          prefs.containsKey('authors_v1');
      if (hadLegacy) {
        await _clearEntityKeys(prefs);
        message = 'Формат локальных данных обновлён. Загружен начальный набор записей.';
      }
      await prefs.setString(_metaKey, jsonEncode({'version': currentVersion}));
    } else {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final version = (map['version'] as num?)?.toInt() ?? 0;
        if (version != currentVersion) {
          await _clearEntityKeys(prefs);
          message = 'Формат локальных данных обновлён. Загружен начальный набор записей.';
          await prefs.setString(
            _metaKey,
            jsonEncode({'version': currentVersion}),
          );
        }
      } catch (_) {
        await _clearEntityKeys(prefs);
        message =
            'Локальные данные повреждены. Загружен начальный набор записей.';
        await prefs.setString(
          _metaKey,
          jsonEncode({'version': currentVersion}),
        );
      }
    }
    return StorageMeta._(prefs, resetMessage: message);
  }

  static Future<void> _clearEntityKeys(SharedPreferences prefs) async {
    for (final key in [
      'books_v1',
      'authors_v1',
      'genres_v1',
      'publishers_v1',
      'readers_v1',
      'books_v2',
      'authors_v2',
      'genres_v2',
      'publishers_v2',
      'readers_v2',
      _legacyMetaKey,
    ]) {
      await prefs.remove(key);
    }
  }
}
