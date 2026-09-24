import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';

enum AppButtonType { primary, secondary, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final bool isExpanded;
  final IconData? prefixIcon;
  final IconData? suffixIcon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.isExpanded = false,
    this.prefixIcon,
    this.suffixIcon,
  });

  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = false,
    this.prefixIcon,
    this.suffixIcon,
  }) : type = AppButtonType.primary;

  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = false,
    this.prefixIcon,
    this.suffixIcon,
  }) : type = AppButtonType.secondary;

  const AppButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = false,
    this.prefixIcon,
    this.suffixIcon,
  }) : type = AppButtonType.text;

  @override
  Widget build(BuildContext context) {
    final button = _buildButton(context);

    if (isExpanded) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButton(BuildContext context) {
    final child = _buildChild(context);

    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case AppButtonType.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case AppButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
    }
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      final colorScheme = Theme.of(context).colorScheme;
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: type == AppButtonType.primary
              ? colorScheme.onPrimary
              : colorScheme.primary,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefixIcon != null) ...[
          Icon(prefixIcon, size: 20),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(text),
        if (suffixIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(suffixIcon, size: 20),
        ],
      ],
    );
  }
}
