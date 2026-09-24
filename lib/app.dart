import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/routes/app_router.dart';
import 'core/localization/locale_keys.dart';
import 'core/offline/connectivity_cubit.dart';
import 'core/offline/offline_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_indicator.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/settings/data/repositories/settings_repository.dart';
import 'features/settings/presentation/bloc/theme_cubit.dart';

/// Root widget. Receives its dependencies from `main.dart` (or a test), exposes
/// the repositories to the tree and creates the app-wide blocs.
class App extends StatefulWidget {
  const App({
    super.key,
    required this.router,
    required this.authRepository,
    required this.settingsRepository,
    required this.offlineManager,
  });

  final AppRouter router;
  final AuthRepository authRepository;
  final SettingsRepository settingsRepository;
  final OfflineManager offlineManager;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  /// Created once. `config()` must not run on every rebuild (theme or locale
  /// changes rebuild this widget).
  late final _routerConfig = widget.router.config();

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: widget.authRepository),
        RepositoryProvider<SettingsRepository>.value(
          value: widget.settingsRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthBloc(authRepository: context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (context) => ThemeCubit(context.read<SettingsRepository>()),
          ),
          BlocProvider(
            create: (_) => ConnectivityCubit(widget.offlineManager)..init(),
          ),
        ],
        child: _AuthNavigationListener(
          router: widget.router,
          child: BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              onGenerateTitle: (_) => LocaleKeys.appName.tr(),
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              routerConfig: _routerConfig,
              // Inside MaterialApp so the listener can reach ScaffoldMessenger.
              builder: (context, child) =>
                  ConnectivityListener(child: child ?? const SizedBox.shrink()),
            ),
          ),
        ),
      ),
    );
  }
}

/// The one place that navigates on session changes: signing in (login,
/// register, restored session) opens the main shell; signing out or an
/// expired session returns to Login. Pages never navigate on auth state.
class _AuthNavigationListener extends StatelessWidget {
  const _AuthNavigationListener({required this.router, required this.child});

  final AppRouter router;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          (current is Authenticated && previous is! Authenticated) ||
          (current is Unauthenticated && previous is! Unauthenticated),
      listener: (context, state) => unawaited(
        router.replaceAll([
          if (state is Authenticated)
            const MainNavigationRoute()
          else
            const LoginRoute(),
        ]),
      ),
      child: child,
    );
  }
}
