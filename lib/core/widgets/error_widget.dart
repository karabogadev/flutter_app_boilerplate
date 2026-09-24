import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../localization/locale_keys.dart';
import 'app_button.dart';

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    this.title,
    required String this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  }) : _titleKey = null,
       _messageKey = null;

  /// Presets use translated default texts; pass [title] / [message] to
  /// override them.
  const AppErrorWidget.network({
    super.key,
    this.title,
    this.message,
    this.onRetry,
  }) : icon = Icons.wifi_off,
       _titleKey = LocaleKeys.errorsNoConnectionTitle,
       _messageKey = LocaleKeys.errorsNetworkError;

  const AppErrorWidget.server({
    super.key,
    this.title,
    this.message,
    this.onRetry,
  }) : icon = Icons.cloud_off,
       _titleKey = LocaleKeys.errorsServerErrorTitle,
       _messageKey = LocaleKeys.errorsServerError;

  const AppErrorWidget.empty({
    super.key,
    this.title,
    this.message,
    this.onRetry,
  }) : icon = Icons.inbox_outlined,
       _titleKey = LocaleKeys.errorsEmptyTitle,
       _messageKey = LocaleKeys.errorsEmptyMessage;

  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;
  final String? _titleKey;
  final String? _messageKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = this.title ?? _titleKey?.tr();
    final message = this.message ?? _messageKey?.tr() ?? '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.error),
            if (title != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: LocaleKeys.commonRetry.tr(),
                onPressed: onRetry,
                prefixIcon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorPage extends StatelessWidget {
  final String? title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorPage({super.key, this.title, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppErrorWidget(title: title, message: message, onRetry: onRetry),
    );
  }
}
