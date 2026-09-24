import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_boilerplate/app.dart';
import 'package:flutter_app_boilerplate/config/routes/app_router.dart';
import 'package:flutter_app_boilerplate/config/routes/auth_guard.dart';
import 'package:flutter_app_boilerplate/core/cache/cache_keys.dart';
import 'package:flutter_app_boilerplate/core/cache/cache_manager.dart';
import 'package:flutter_app_boilerplate/core/localization/supported_locales.dart';
import 'package:flutter_app_boilerplate/features/home/presentation/pages/home_page.dart';
import 'package:flutter_app_boilerplate/features/settings/data/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/fakes/fake_auth_repository.dart';
import '../test/helpers/test_helpers.dart';
import '../test/mocks/mocks.dart';

/// Records a timeline while scrolling Home, for frame-budget regressions.
///
/// Run on a real device in profile mode (see README, "Performance"):
///   flutter drive --profile --driver=test_driver/perf_driver.dart \
///     --target=integration_test/home_scroll_perf_test.dart
/// The summary is written to build/home_scroll_timeline.timeline_summary.json.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home scroll stays within the frame budget', (tester) async {
    await EasyLocalization.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(CacheKeys.onboardingCompleted.key, true);

    final offlineManager = onlineOfflineManager();
    final auth = FakeAuthRepository(persistedUser: TestData.testUser);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: SupportedLocale.locales,
        path: SupportedLocale.translationsPath,
        fallbackLocale: SupportedLocale.fallbackLocale,
        child: App(
          router: AppRouter(AuthGuard(auth)),
          authRepository: auth,
          settingsRepository: SettingsRepository(CacheManager(prefs)),
          offlineManager: offlineManager,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    await binding.traceAction(() async {
      for (var i = 0; i < 3; i++) {
        await tester.fling(scrollable, const Offset(0, -600), 3000);
        await tester.pumpAndSettle();
        await tester.fling(scrollable, const Offset(0, 600), 3000);
        await tester.pumpAndSettle();
      }
    }, reportKey: 'home_scroll_timeline');
  });
}
