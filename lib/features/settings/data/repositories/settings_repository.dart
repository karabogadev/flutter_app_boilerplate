import 'package:flutter/material.dart';

import '../../../../core/cache/cache_keys.dart';
import '../../../../core/cache/cache_manager.dart';

/// App preferences (theme, onboarding), following the key-value pattern from
/// https://docs.flutter.dev/app-architecture/design-patterns/key-value-data.
///
/// The selected language is not stored here: easy_localization persists it
/// itself (`saveLocale: true`).
class SettingsRepository {
  SettingsRepository(this._cache);

  final CacheManager _cache;

  ThemeMode get themeMode =>
      ThemeMode.values.asNameMap()[_cache.getString(CacheKeys.themeMode)] ??
      ThemeMode.system;

  Future<void> setThemeMode(ThemeMode mode) =>
      _cache.setString(CacheKeys.themeMode, mode.name);

  bool get onboardingCompleted =>
      _cache.getBool(CacheKeys.onboardingCompleted) ?? false;

  Future<void> completeOnboarding() =>
      _cache.setBool(CacheKeys.onboardingCompleted, value: true);
}
