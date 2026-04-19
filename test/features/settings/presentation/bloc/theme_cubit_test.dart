import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app_boilerplate/core/cache/cache_keys.dart';
import 'package:flutter_app_boilerplate/features/settings/presentation/bloc/theme_cubit.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late MockCacheManager mockCacheManager;

  setUp(() {
    mockCacheManager = MockCacheManager();
  });

  setUpAll(registerFallbackValues);

  group('ThemeCubit', () {
    test('initial state is ThemeMode.system when no saved preference', () {
      when(() => mockCacheManager.getString(CacheKeys.themeMode))
          .thenReturn(null);

      final cubit = ThemeCubit(mockCacheManager);

      expect(cubit.state.themeMode, ThemeMode.system);
      cubit.close();
    });

    test('loads saved theme on construction', () {
      when(() => mockCacheManager.getString(CacheKeys.themeMode))
          .thenReturn('dark');

      // _loadTheme has no awaits, so emit() fires synchronously during
      // construction. Check state directly instead of listening to the stream.
      final cubit = ThemeCubit(mockCacheManager);

      expect(cubit.state.themeMode, ThemeMode.dark);
      expect(cubit.state.isDark, true);
      cubit.close();
    });

    blocTest<ThemeCubit, ThemeState>(
      'setTheme() emits new theme and saves to cache',
      build: () {
        when(() => mockCacheManager.getString(CacheKeys.themeMode))
            .thenReturn(null);
        when(() => mockCacheManager.setString(CacheKeys.themeMode, any()))
            .thenAnswer((_) async {});
        return ThemeCubit(mockCacheManager);
      },
      act: (cubit) => cubit.setTheme(ThemeMode.dark),
      expect: () => [
        isA<ThemeState>()
            .having((s) => s.themeMode, 'themeMode', ThemeMode.dark)
            .having((s) => s.isDark, 'isDark', true),
      ],
      verify: (_) {
        verify(() => mockCacheManager.setString(CacheKeys.themeMode, 'dark'))
            .called(1);
      },
    );

    blocTest<ThemeCubit, ThemeState>(
      'toggleTheme() switches dark → light',
      build: () {
        when(() => mockCacheManager.getString(CacheKeys.themeMode))
            .thenReturn('dark');
        when(() => mockCacheManager.setString(CacheKeys.themeMode, any()))
            .thenAnswer((_) async {});
        return ThemeCubit(mockCacheManager);
      },
      seed: () => const ThemeState(themeMode: ThemeMode.dark, isDark: true),
      act: (cubit) => cubit.toggleTheme(),
      expect: () => [
        isA<ThemeState>()
            .having((s) => s.themeMode, 'themeMode', ThemeMode.light)
            .having((s) => s.isDark, 'isDark', false),
      ],
    );
  });
}
