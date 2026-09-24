import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_boilerplate/core/localization/supported_locales.dart';
import 'package:flutter_app_boilerplate/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Call from `setUpAll` in widget tests that render translated text.
Future<void> setUpLocalization() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  EasyLocalization.logger.enableBuildModes = [];
  await EasyLocalization.ensureInitialized();
}

/// Reads the real translation files synchronously from disk.
///
/// The default loader goes through `rootBundle`, whose cached futures belong
/// to the first test's fake-async zone; later tests in the same file would
/// then never finish loading and render nothing.
class _FileAssetLoader extends AssetLoader {
  const _FileAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
          as Map<String, dynamic>;
}

/// Wraps [child] in [EasyLocalization] with the real translation files and
/// the given [locale]. Use it around anything that calls `.tr()`.
Widget localized(Widget child, {Locale locale = const Locale('en')}) {
  return EasyLocalization(
    supportedLocales: SupportedLocale.locales,
    path: SupportedLocale.translationsPath,
    assetLoader: const _FileAssetLoader(),
    fallbackLocale: SupportedLocale.fallbackLocale,
    startLocale: locale,
    saveLocale: false,
    useFallbackTranslations: true,
    child: child,
  );
}

extension PumpApp on WidgetTester {
  /// Pumps [widget] inside a localized, themed [MaterialApp].
  Future<void> pumpApp(
    Widget widget, {
    List<BlocProvider<StateStreamableSource<Object?>>>? providers,
    Locale locale = const Locale('en'),
  }) async {
    await pumpWidget(
      localized(
        locale: locale,
        Builder(
          builder: (context) => MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: providers == null
                ? widget
                : MultiBlocProvider(providers: providers, child: widget),
          ),
        ),
      ),
    );
    // Translations load asynchronously.
    await pumpAndSettle();
  }
}
