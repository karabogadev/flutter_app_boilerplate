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
    // Cubit re-emits an equal state if nothing was emitted yet; skip it to
    // avoid a needless MaterialApp rebuild and disk write.
    if (mode == state) return;
    emit(mode);
    await _settingsRepository.setThemeMode(mode);
  }
}
