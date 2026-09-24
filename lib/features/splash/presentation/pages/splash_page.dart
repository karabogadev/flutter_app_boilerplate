import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../settings/data/repositories/settings_repository.dart';

/// Shown while the persisted session is restored. There is no artificial
/// delay: as soon as [AuthBloc] settles, the app-level auth listener in
/// `app.dart` replaces this page.
@RoutePage()
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    if (context.read<SettingsRepository>().onboardingCompleted) {
      context.read<AuthBloc>().add(const CheckAuthStatusEvent());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(context.router.replace(const OnboardingRoute()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flutter_dash,
              size: 100,
              color: context.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              LocaleKeys.appName.tr(),
              style: context.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xxl),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
