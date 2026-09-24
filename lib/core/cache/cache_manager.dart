import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'cache_keys.dart';
import 'cacheable_base_model.dart';

/// Typed key-value store for non-sensitive data, backed by SharedPreferences.
///
/// Takes an already loaded [SharedPreferences] instance, so every read is
/// synchronous and there is no "not initialized" state. Tokens and other
/// secrets belong in `SecureCacheManager`.
class CacheManager {
  CacheManager(this._prefs);

  final SharedPreferences _prefs;

  Future<void> setString(CacheKeys key, String? value) async {
    if (value == null) {
      await _prefs.remove(key.key);
    } else {
      await _prefs.setString(key.key, value);
    }
  }

  String? getString(CacheKeys key) => _prefs.getString(key.key);

  Future<void> setBool(CacheKeys key, {required bool value}) =>
      _prefs.setBool(key.key, value);

  bool? getBool(CacheKeys key) => _prefs.getBool(key.key);

  Future<void> setInt(CacheKeys key, int value) => _prefs.setInt(key.key, value);

  int? getInt(CacheKeys key) => _prefs.getInt(key.key);

  Future<void> setObject<T extends CacheableModel>(CacheKeys key, T value) =>
      _prefs.setString(key.key, jsonEncode(value.toJson()));

  /// Returns null when the key is missing or the stored JSON no longer
  /// matches [fromJson] (e.g. after a model change).
  T? getObject<T extends CacheableModel>(
    CacheKeys key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final jsonString = _prefs.getString(key.key);
    if (jsonString == null) return null;
    try {
      return fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<void> setList<T extends CacheableModel>(
    CacheKeys key,
    List<T> value,
  ) =>
      _prefs.setString(
        key.key,
        jsonEncode([for (final item in value) item.toJson()]),
      );

  List<T>? getList<T extends CacheableModel>(
    CacheKeys key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final jsonString = _prefs.getString(key.key);
    if (jsonString == null) return null;
    try {
      return [
        for (final item in jsonDecode(jsonString) as List<dynamic>)
          fromJson(item as Map<String, dynamic>),
      ];
    } on Object {
      return null;
    }
  }

  Future<void> remove(CacheKeys key) => _prefs.remove(key.key);

  Future<void> clear() => _prefs.clear();
}
