import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import 'app_button.dart';

class AppErrorWidget extends StatelessWidget {
  final String? title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorWidget({
    super.key,
    this.title,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  const AppErrorWidget.network({
    super.key,
    this.title = 'No Connection',
    this.message = 'Please check your internet connection and try again.',
    this.onRetry,
  }) : icon = Icons.wifi_off;

  const AppErrorWidget.server({
    super.key,
    this.title = 'Server Error',
    this.message = 'Something went wrong. Please try again later.',
    this.onRetry,
  }) : icon = Icons.cloud_off;

  const AppErrorWidget.empty({
    super.key,
    this.title = 'No Data',
    this.message = 'No data available at the moment.',
    this.onRetry,
  }) : icon = Icons.inbox_outlined;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                title!,
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
                text: 'Retry',
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
