import 'package:flutter/material.dart';

/// Brand palette for one brightness. Edit [light] and [dark] to rebrand the
/// app; `AppTheme` derives every component theme from these values.
///
/// Text colors meet WCAG AA contrast (4.5:1) against both [background] and
/// [surface].
@immutable
class AppColors {
  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.error,
    required this.onError,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
  });

  static const light = AppColors(
    primary: Color(0xFF6200EE),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF03DAC6),
    onSecondary: Color(0xFF000000),
    background: Color(0xFFF5F5F5),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF121212),
    error: Color(0xFFB00020),
    onError: Color(0xFFFFFFFF),
    divider: Color(0xFFE0E0E0),
    textPrimary: Color(0xFF212121),
    textSecondary: Color(0xFF616161),
    textHint: Color(0xFF6B6B6B),
  );

  static const dark = AppColors(
    primary: Color(0xFFBB86FC),
    onPrimary: Color(0xFF000000),
    secondary: Color(0xFF03DAC6),
    onSecondary: Color(0xFF000000),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    onSurface: Color(0xFFFFFFFF),
    error: Color(0xFFCF6679),
    onError: Color(0xFF000000),
    divider: Color(0xFF2C2C2C),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB3B3B3),
    textHint: Color(0xFF9E9E9E),
  );

  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color background;
  final Color surface;
  final Color onSurface;
  final Color error;
  final Color onError;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
}
