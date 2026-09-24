import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/localization/supported_locales.dart';
import 'core/logging/app_logger.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setUpErrorReporting();
  _registerFontLicenses();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Only what the first frame needs is awaited, and independent work runs in
  // parallel. Keep this list short: nothing is drawn until runApp.
  await (initDependencies(), EasyLocalization.ensureInitialized()).wait;

  runApp(
    EasyLocalization(
      supportedLocales: SupportedLocale.locales,
      path: SupportedLocale.translationsPath,
      fallbackLocale: SupportedLocale.fallbackLocale,
      child: App(
        router: sl(),
        authRepository: sl(),
        settingsRepository: sl(),
        offlineManager: sl(),
      ),
    ),
  );
}

/// Routes framework errors and uncaught async errors to [AppLogger].
/// Forward them to your crash reporter (Crashlytics, Sentry, ...) here.
void _setUpErrorReporting() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger.error(
      'Uncaught asynchronous error',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };
}

/// Bundled fonts must ship their license; it is loaded lazily, only when the
/// license page is opened.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/inter/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Inter'], license);
  });
}
