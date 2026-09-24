import 'dart:async';

import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  // Theme
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  // Screen size
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  // Padding
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  double get topPadding => padding.top;
  double get bottomPadding => padding.bottom;

  // Brightness
  bool get isDarkMode => theme.brightness == Brightness.dark;

  // Navigation
  NavigatorState get navigator => Navigator.of(this);
  void pop<T>([T? result]) => navigator.pop(result);

  // Focus
  void unfocus() => FocusScope.of(this).unfocus();

  // Snackbar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
      ),
    );
  }

  // Loading dialog
  void showLoadingDialog() {
    unawaited(
      showDialog<void>(
        context: this,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void hideLoadingDialog() {
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}
