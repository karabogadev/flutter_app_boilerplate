import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cache/cache_keys.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/localization/localization_manager.dart';
import '../../../../core/localization/supported_locales.dart';

/// State for LocaleCubit
class LocaleState extends Equatable {
  final SupportedLocale currentLocale;
  final bool isLoading;

  const LocaleState({
    required this.currentLocale,
    this.isLoading = false,
  });

  factory LocaleState.initial() => LocaleState(
        currentLocale: SupportedLocale.defaultLocale,
        isLoading: true,
      );

  LocaleState copyWith({
    SupportedLocale? currentLocale,
    bool? isLoading,
  }) {
    return LocaleState(
      currentLocale: currentLocale ?? this.currentLocale,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [currentLocale, isLoading];
}

/// Cubit for managing app locale/language
class LocaleCubit extends Cubit<LocaleState> {
  final CacheManager _cacheManager;
  final LocalizationManager _localizationManager;

  LocaleCubit(this._cacheManager, this._localizationManager)
      : super(LocaleState.initial()) {
    _loadSavedLocale();
  }

  /// Load saved locale from cache
  Future<void> _loadSavedLocale() async {
    final savedLanguageCode = _cacheManager.getString(CacheKeys.locale);

    if (savedLanguageCode != null) {
      final savedLocale = SupportedLocale.fromLanguageCode(savedLanguageCode);
      emit(LocaleState(currentLocale: savedLocale, isLoading: false));
    } else {
      emit(LocaleState(
        currentLocale: SupportedLocale.defaultLocale,
        isLoading: false,
      ));
    }
  }

  /// Change the current locale
  /// Note: You must also call context.setLocale() from the UI
  Future<void> setLocale(
    BuildContext context,
    SupportedLocale locale,
  ) async {
    emit(state.copyWith(isLoading: true));

    await _localizationManager.setLocale(context, locale);

    emit(LocaleState(currentLocale: locale, isLoading: false));
  }

  /// Change locale by language code
  Future<void> setLocaleByCode(
    BuildContext context,
    String languageCode,
  ) async {
    final locale = SupportedLocale.fromLanguageCode(languageCode);
    await setLocale(context, locale);
  }

  /// Get all available locales
  List<SupportedLocale> get availableLocales => SupportedLocale.values;

  /// Check if given locale is current
  bool isCurrentLocale(SupportedLocale locale) {
    return state.currentLocale == locale;
  }

  /// Reset to default locale
  Future<void> resetToDefault(BuildContext context) async {
    await setLocale(context, SupportedLocale.defaultLocale);
  }
}
