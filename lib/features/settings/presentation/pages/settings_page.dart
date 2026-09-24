import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/localization/supported_locales.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/theme_cubit.dart';

/// Logging out needs no navigation here: the app-level auth listener in
/// `app.dart` sends the user to Login when the session ends.
@RoutePage()
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.settingsTitle.tr())),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _SectionHeader(LocaleKeys.settingsTheme.tr()),
          const Card(
            child: Column(
              children: [
                _ThemeTile(),
                Divider(height: 1),
                _LanguageTile(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(LocaleKeys.settingsAccount.tr()),
          Card(
            child: Column(
              children: [
                _NavigationTile(
                  icon: Icons.person,
                  title: LocaleKeys.settingsProfile.tr(),
                ),
                const Divider(height: 1),
                _NavigationTile(
                  icon: Icons.security,
                  title: LocaleKeys.settingsSecurity.tr(),
                ),
                const Divider(height: 1),
                _NavigationTile(
                  icon: Icons.notifications,
                  title: LocaleKeys.settingsNotifications.tr(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(LocaleKeys.settingsAbout.tr()),
          Card(
            child: Column(
              children: [
                _NavigationTile(
                  icon: Icons.info,
                  title: LocaleKeys.settingsAbout.tr(),
                ),
                const Divider(height: 1),
                _NavigationTile(
                  icon: Icons.privacy_tip,
                  title: LocaleKeys.settingsPrivacy.tr(),
                ),
                const Divider(height: 1),
                _NavigationTile(
                  icon: Icons.description,
                  title: LocaleKeys.settingsTerms.tr(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Card(child: _LogoutTile()),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              '${LocaleKeys.settingsVersion.tr()} 1.0.0',
              style: context.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Text(title, style: context.textTheme.titleSmall),
    );
  }
}

/// Placeholder entry for screens the boilerplate doesn't implement yet.
class _NavigationTile extends StatelessWidget {
  const _NavigationTile({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Navigate to the matching screen
      },
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile();

  static String _label(ThemeMode mode) => switch (mode) {
        ThemeMode.system => LocaleKeys.settingsSystemTheme.tr(),
        ThemeMode.light => LocaleKeys.settingsLightTheme.tr(),
        ThemeMode.dark => LocaleKeys.settingsDarkTheme.tr(),
      };

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;
    // Reflects what is on screen, including ThemeMode.system.
    final isDark = context.isDarkMode;

    return ListTile(
      leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
      title: Text(LocaleKeys.settingsTheme.tr()),
      subtitle: Text(_label(themeMode)),
      trailing: Switch(
        value: isDark,
        onChanged: (dark) => unawaited(
          context
              .read<ThemeCubit>()
              .setThemeMode(dark ? ThemeMode.dark : ThemeMode.light),
        ),
      ),
      onTap: () => unawaited(_showDialog(context, themeMode)),
    );
  }

  Future<void> _showDialog(BuildContext context, ThemeMode current) {
    final cubit = context.read<ThemeCubit>();
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.settingsTheme.tr()),
        content: RadioGroup<ThemeMode>(
          groupValue: current,
          onChanged: (mode) {
            if (mode == null) return;
            unawaited(cubit.setThemeMode(mode));
            Navigator.pop(dialogContext);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in ThemeMode.values)
                RadioListTile<ThemeMode>(title: Text(_label(mode)), value: mode),
            ],
          ),
        ),
      ),
    );
  }
}

/// easy_localization persists the chosen locale itself, so switching is a
/// single `context.setLocale` call.
class _LanguageTile extends StatelessWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context) {
    final current = SupportedLocale.fromLocale(context.locale);
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(LocaleKeys.settingsLanguage.tr()),
      subtitle: Text(current.displayName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => unawaited(_showDialog(context, current)),
    );
  }

  Future<void> _showDialog(BuildContext context, SupportedLocale current) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.settingsLanguage.tr()),
        content: RadioGroup<SupportedLocale>(
          groupValue: current,
          onChanged: (locale) {
            if (locale == null) return;
            unawaited(context.setLocale(locale.locale));
            Navigator.pop(dialogContext);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final locale in SupportedLocale.values)
                RadioListTile<SupportedLocale>(
                  title: Text(locale.displayName),
                  subtitle: Text(locale.name),
                  value: locale,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile();

  @override
  Widget build(BuildContext context) {
    final errorColor = context.colorScheme.error;
    return ListTile(
      leading: Icon(Icons.logout, color: errorColor),
      title: Text(
        LocaleKeys.authLogout.tr(),
        style: TextStyle(color: errorColor),
      ),
      onTap: () => unawaited(_confirmLogout(context)),
    );
  }

  Future<void> _confirmLogout(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.authLogout.tr()),
        content: Text(LocaleKeys.authLogoutConfirm.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocaleKeys.commonCancel.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              authBloc.add(const LogoutEvent());
            },
            child: Text(
              LocaleKeys.authLogout.tr(),
              style: TextStyle(color: context.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
