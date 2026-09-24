import 'dart:ui';

/// Enum representing all supported locales in the app
enum SupportedLocale {
  english(
    locale: Locale('en'),
    languageCode: 'en',
    name: 'English',
    nativeName: 'English',
    flag: '🇺🇸',
  ),
  turkish(
    locale: Locale('tr'),
    languageCode: 'tr',
    name: 'Turkish',
    nativeName: 'Türkçe',
    flag: '🇹🇷',
  );

  const SupportedLocale({
    required this.locale,
    required this.languageCode,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  final Locale locale;
  final String languageCode;
  final String name;
  final String nativeName;
  final String flag;

  /// Get display name with flag
  String get displayName => '$flag $nativeName';

  /// Get all supported locales as `List<Locale>`
  static List<Locale> get locales =>
      SupportedLocale.values.map((e) => e.locale).toList();

  /// Find SupportedLocale by Locale
  static SupportedLocale fromLocale(Locale locale) {
    return SupportedLocale.values.firstWhere(
      (e) => e.languageCode == locale.languageCode,
      orElse: () => SupportedLocale.english,
    );
  }

  /// Find SupportedLocale by language code
  static SupportedLocale fromLanguageCode(String code) {
    return SupportedLocale.values.firstWhere(
      (e) => e.languageCode == code,
      orElse: () => SupportedLocale.english,
    );
  }

  /// Default locale
  static SupportedLocale get defaultLocale => SupportedLocale.english;

  /// Fallback locale
  static Locale get fallbackLocale => SupportedLocale.english.locale;

  /// Folder with one `<languageCode>.json` per locale.
  static const translationsPath = 'assets/translations';
}
