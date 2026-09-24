import 'package:flutter/material.dart';
import 'package:flutter_app_boilerplate/app.dart';
import 'package:flutter_app_boilerplate/config/routes/app_router.dart';
import 'package:flutter_app_boilerplate/config/routes/auth_guard.dart';
import 'package:flutter_app_boilerplate/core/cache/cache_keys.dart';
import 'package:flutter_app_boilerplate/core/cache/cache_manager.dart';
import 'package:flutter_app_boilerplate/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_app_boilerplate/features/home/presentation/pages/home_page.dart';
import 'package:flutter_app_boilerplate/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flutter_app_boilerplate/features/settings/data/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';
import 'helpers/pump_app.dart';
import 'helpers/test_helpers.dart';
import 'mocks/mocks.dart';

/// End-to-end routing through the real [App], [AppRouter] and [AuthGuard]:
/// the session in [FakeAuthRepository] alone decides which screen is shown.
void main() {
  late MockOfflineManager offlineManager;

  setUpAll(setUpLocalization);

  setUp(() {
    offlineManager = onlineOfflineManager();
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    required FakeAuthRepository auth,
    bool onboardingCompleted = true,
  }) async {
    SharedPreferences.setMockInitialValues({
      CacheKeys.onboardingCompleted.key: onboardingCompleted,
    });
    final settings = SettingsRepository(
      CacheManager(await SharedPreferences.getInstance()),
    );
    await tester.pumpWidget(
      localized(
        App(
          router: AppRouter(AuthGuard(auth)),
          authRepository: auth,
          settingsRepository: settings,
          offlineManager: offlineManager,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('first launch goes to onboarding', (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(),
      onboardingCompleted: false,
    );

    expect(find.byType(OnboardingPage), findsOneWidget);
  });

  testWidgets('a restored session opens Home directly', (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(persistedUser: TestData.testUser),
    );

    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('login opens Home; an expired session returns to Login', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await pumpApp(tester, auth: auth);
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);

    // e.g. the refresh token was rejected by the server.
    await auth.expireSession();
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('logging out from Settings returns to Login', (tester) async {
    await pumpApp(
      tester,
      auth: FakeAuthRepository(persistedUser: TestData.testUser),
    );

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Logout'), 200);
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
