import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_theme.dart';

/// Light and dark [ThemeData], built once per app run.
///
/// Both are `static final`, so switching theme mode or rebuilding
/// `MaterialApp` never reconstructs the theme tree.
abstract final class AppTheme {
  static final ThemeData light = _build(AppColors.light, Brightness.light);
  static final ThemeData dark = _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final textTheme = AppTextTheme.textTheme.apply(
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    );
    final secondaryText = TextStyle(color: colors.textSecondary);

    final colorScheme = isLight
        ? ColorScheme.light(
            primary: colors.primary,
            onPrimary: colors.onPrimary,
            secondary: colors.secondary,
            onSecondary: colors.onSecondary,
            surface: colors.surface,
            onSurface: colors.onSurface,
            error: colors.error,
            onError: colors.onError,
          )
        : ColorScheme.dark(
            primary: colors.primary,
            onPrimary: colors.onPrimary,
            secondary: colors.secondary,
            onSecondary: colors.onSecondary,
            surface: colors.surface,
            onSurface: colors.onSurface,
            error: colors.error,
            onError: colors.onError,
          );

    final smallRadius = BorderRadius.circular(8);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTextTheme.fontFamily,
      colorScheme: colorScheme,
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.background,
      dividerColor: colors.divider,
      textTheme: textTheme.copyWith(
        titleSmall: textTheme.titleSmall?.merge(secondaryText),
        bodyMedium: textTheme.bodyMedium?.merge(secondaryText),
        bodySmall: textTheme.bodySmall?.merge(secondaryText),
        labelMedium: textTheme.labelMedium?.merge(secondaryText),
        labelSmall: textTheme.labelSmall?.copyWith(color: colors.textHint),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        systemOverlayStyle:
            isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          padding: buttonPadding,
          shape: RoundedRectangleBorder(borderRadius: smallRadius),
          textStyle: AppTextTheme.textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          padding: buttonPadding,
          shape: RoundedRectangleBorder(borderRadius: smallRadius),
          side: BorderSide(color: colors.primary),
          textStyle: AppTextTheme.textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: AppTextTheme.textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: smallRadius,
          borderSide: BorderSide(color: colors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: smallRadius,
          borderSide: BorderSide(color: colors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: smallRadius,
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: smallRadius,
          borderSide: BorderSide(color: colors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textHint),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? colors.onSurface : colors.surface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isLight ? colors.surface : colors.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: smallRadius),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
