import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../cache/cache_keys.dart';
import '../cache/cache_manager.dart';
import 'supported_locales.dart';

class LocalizationManager {
  LocalizationManager(this._cacheManager);

  final CacheManager _cacheManager;

  /// Get list of all supported locales
  List<Locale> get supportedLocales => SupportedLocale.locales;

  /// Get fallback locale
  Locale get fallbackLocale => SupportedLocale.fallbackLocale;

  /// Get translations asset path
  String get translationsPath => 'assets/translations';

  /// Get current locale from context
  Locale getCurrentLocale(BuildContext context) {
    return context.locale;
  }

  /// Get current SupportedLocale from context
  SupportedLocale getCurrentSupportedLocale(BuildContext context) {
    return SupportedLocale.fromLocale(context.locale);
  }

  /// Change locale
  Future<void> setLocale(BuildContext context, SupportedLocale locale) async {
    await context.setLocale(locale.locale);
    await _saveLocale(locale);
  }

  /// Change locale by Locale object
  Future<void> setLocaleByLocale(BuildContext context, Locale locale) async {
    final supportedLocale = SupportedLocale.fromLocale(locale);
    await setLocale(context, supportedLocale);
  }

  /// Save locale to cache
  Future<void> _saveLocale(SupportedLocale locale) async {
    await _cacheManager.setString(CacheKeys.locale, locale.languageCode);
  }

  /// Get saved locale from cache
  SupportedLocale? getSavedLocale() {
    final languageCode = _cacheManager.getString(CacheKeys.locale);
    if (languageCode == null) return null;
    return SupportedLocale.fromLanguageCode(languageCode);
  }

  /// Get saved Locale or fallback
  Locale getSavedLocaleOrFallback() {
    final saved = getSavedLocale();
    return saved?.locale ?? fallbackLocale;
  }

  /// Reset locale to default
  Future<void> resetLocale(BuildContext context) async {
    await context.resetLocale();
    await _cacheManager.remove(CacheKeys.locale);
  }

  /// Check if locale is RTL
  bool isRTL(BuildContext context) {
    return Directionality.of(context) == ui.TextDirection.rtl;
  }

  /// Get language name in current locale
  String getLanguageName(SupportedLocale locale) {
    return locale.nativeName;
  }

  /// Get all supported locales as SupportedLocale list
  List<SupportedLocale> get allSupportedLocales => SupportedLocale.values;
}
