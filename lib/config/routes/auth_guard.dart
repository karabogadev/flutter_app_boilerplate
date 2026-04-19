import 'dart:async';

import 'package:auto_route/auto_route.dart';

import '../../features/auth/data/datasources/auth_local_datasource.dart';

class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._authLocalDataSource);

  final AuthLocalDataSource _authLocalDataSource;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final token = await _authLocalDataSource.getAccessToken();
    if (token != null) {
      resolver.next(true);
    } else {
      // Push login and block the original navigation.
      // Using pushPath avoids a circular import with app_router.gr.dart.
      unawaited(router.pushPath('/login'));
      resolver.next(false);
    }
  }
}
