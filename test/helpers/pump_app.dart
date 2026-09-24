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

/// Wraps [child] in [EasyLocalization] with the real translation files and
/// the given [locale]. Use it around anything that calls `.tr()`.
Widget localized(Widget child, {Locale locale = const Locale('en')}) {
  return EasyLocalization(
    supportedLocales: SupportedLocale.locales,
    path: SupportedLocale.translationsPath,
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
