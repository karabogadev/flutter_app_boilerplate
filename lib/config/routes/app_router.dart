import 'package:auto_route/auto_route.dart';

import 'auth_guard.dart';

// Pages - import all your pages
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/main_navigation/presentation/pages/main_navigation_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  AppRouter(this._authGuard);

  final AuthGuard _authGuard;

  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> get routes => [
        // Splash & Onboarding
        AutoRoute(page: SplashRoute.page, initial: true),
        AutoRoute(page: OnboardingRoute.page),

        // Auth
        AutoRoute(page: LoginRoute.page),
        AutoRoute(page: RegisterRoute.page),

        // Main App — guard ensures only authenticated users can enter.
        AutoRoute(
          page: MainNavigationRoute.page,
          guards: [_authGuard],
          children: [
            AutoRoute(page: HomeRoute.page, initial: true),
            AutoRoute(page: SettingsRoute.page),
          ],
        ),
      ];
}
