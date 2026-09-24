import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/settings_repository.dart';

/// Holds the selected [ThemeMode].
///
/// The saved mode is read synchronously in the constructor, so the first
/// frame already uses it and there is no extra rebuild after startup.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._settingsRepository) : super(_settingsRepository.themeMode);

  final SettingsRepository _settingsRepository;

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    await _settingsRepository.setThemeMode(mode);
  }
}
