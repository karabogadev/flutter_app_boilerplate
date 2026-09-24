import 'package:flutter_app_boilerplate/config/routes/app_router.dart';
import 'package:flutter_app_boilerplate/config/routes/auth_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../helpers/test_helpers.dart';
import '../../mocks/mocks.dart';

void main() {
  late MockNavigationResolver resolver;
  late MockStackRouter router;

  setUpAll(registerFallbackValues);

  setUp(() {
    resolver = MockNavigationResolver();
    router = MockStackRouter();
  });

  test('lets authenticated users through', () async {
    final repository = FakeAuthRepository(persistedUser: TestData.testUser);
    await repository.restoreSession();

    AuthGuard(repository).onNavigation(resolver, router);

    verify(() => resolver.next()).called(1);
    verifyNever(
      () => resolver.redirectUntil(any(), replace: any(named: 'replace')),
    );
  });

  test('redirects signed-out users to Login', () {
    AuthGuard(FakeAuthRepository()).onNavigation(resolver, router);

    verify(
      () => resolver.redirectUntil(const LoginRoute(), replace: true),
    ).called(1);
    verifyNever(() => resolver.next());
  });
}
