import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_boilerplate/core/cache/cache_keys.dart';
import 'package:flutter_app_boilerplate/core/cache/cache_manager.dart';
import 'package:flutter_app_boilerplate/features/settings/data/repositories/settings_repository.dart';
import 'package:flutter_app_boilerplate/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsRepository repository;

  Future<void> setUpRepository([Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    repository = SettingsRepository(
      CacheManager(await SharedPreferences.getInstance()),
    );
  }

  setUp(setUpRepository);

  test('starts with the stored mode without emitting', () async {
    await setUpRepository({CacheKeys.themeMode.key: 'dark'});
    final cubit = ThemeCubit(repository);

    expect(cubit.state, ThemeMode.dark);
    await cubit.close();
  });

  blocTest<ThemeCubit, ThemeMode>(
    'setThemeMode emits and persists the mode',
    build: () => ThemeCubit(repository),
    act: (cubit) => cubit.setThemeMode(ThemeMode.dark),
    expect: () => [ThemeMode.dark],
    verify: (_) => expect(repository.themeMode, ThemeMode.dark),
  );

  blocTest<ThemeCubit, ThemeMode>(
    'setting the current mode again emits nothing',
    build: () => ThemeCubit(repository),
    act: (cubit) => cubit.setThemeMode(ThemeMode.system),
    expect: () => <ThemeMode>[],
  );
}
