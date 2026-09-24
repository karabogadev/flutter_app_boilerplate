import 'package:flutter/material.dart';
import 'package:flutter_app_boilerplate/core/cache/cache_keys.dart';
import 'package:flutter_app_boilerplate/core/cache/cache_manager.dart';
import 'package:flutter_app_boilerplate/features/settings/data/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SettingsRepository> build([
    Map<String, Object> values = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(values);
    return SettingsRepository(
      CacheManager(await SharedPreferences.getInstance()),
    );
  }

  group('themeMode', () {
    test('defaults to system', () async {
      expect((await build()).themeMode, ThemeMode.system);
    });

    test('reads the stored mode', () async {
      final repository = await build({CacheKeys.themeMode.key: 'dark'});
      expect(repository.themeMode, ThemeMode.dark);
    });

    test('falls back to system for an unknown stored value', () async {
      final repository = await build({CacheKeys.themeMode.key: 'sepia'});
      expect(repository.themeMode, ThemeMode.system);
    });

    test('persists a new mode', () async {
      final repository = await build();
      await repository.setThemeMode(ThemeMode.light);
      expect(repository.themeMode, ThemeMode.light);
    });
  });

  group('onboarding', () {
    test('is not completed by default', () async {
      expect((await build()).onboardingCompleted, isFalse);
    });

    test('completeOnboarding persists the flag', () async {
      final repository = await build();
      await repository.completeOnboarding();
      expect(repository.onboardingCompleted, isTrue);
    });
  });
}
