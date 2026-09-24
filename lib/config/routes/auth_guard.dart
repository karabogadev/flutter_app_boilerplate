import 'package:auto_route/auto_route.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';
import 'app_router.dart';

/// Keeps signed-out users out of guarded routes.
///
/// Reads the in-memory session from [AuthRepository], so it runs
/// synchronously and never hits secure storage on navigation.
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._authRepository);

  final AuthRepository _authRepository;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_authRepository.isAuthenticated) {
      resolver.next();
    } else {
      resolver.redirectUntil(const LoginRoute(), replace: true);
    }
  }
}
