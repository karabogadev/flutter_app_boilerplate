import 'package:flutter/material.dart';
import 'package:flutter_app_boilerplate/core/error/failures.dart';
import 'package:flutter_app_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_app_boilerplate/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_auth_repository.dart';
import '../../../../helpers/accessibility.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthBloc bloc;

  setUpAll(setUpLocalization);

  setUp(() => repository = FakeAuthRepository());

  /// The bloc is created inside the test body so its event processing runs
  /// in the test's fake-async zone and is advanced by `pump`.
  Future<void> pumpLoginPage(WidgetTester tester) {
    bloc = AuthBloc(authRepository: repository);
    addTearDown(bloc.close);
    return tester.pumpApp(
      const LoginPage(),
      providers: [BlocProvider<AuthBloc>.value(value: bloc)],
    );
  }

  Future<void> submit(
    WidgetTester tester, {
    String email = '',
    String password = '',
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders translated copy', (tester) async {
    await pumpLoginPage(tester);

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });

  testWidgets('shows validation errors and does not sign in when empty', (
    tester,
  ) async {
    await pumpLoginPage(tester);

    await submit(tester);

    expect(find.text('This field is required'), findsNWidgets(2));
    expect(bloc.state, const AuthInitial());
  });

  testWidgets('rejects a malformed email', (tester) async {
    await pumpLoginPage(tester);

    await submit(tester, email: 'not-an-email', password: 'secret');

    expect(find.text('Please enter a valid email'), findsOneWidget);
    expect(bloc.state, const AuthInitial());
  });

  testWidgets('signs in with the entered credentials', (tester) async {
    await pumpLoginPage(tester);

    await submit(tester, email: ' test@example.com ', password: 'secret');

    expect(bloc.state, Authenticated(TestData.testUser));
    expect(repository.isAuthenticated, isTrue);
  });

  testWidgets('shows the failure message in a snackbar', (tester) async {
    repository.signInFailure = const ServerFailure(
      message: 'Invalid credentials',
    );
    await pumpLoginPage(tester);

    await submit(tester, email: 'test@example.com', password: 'wrong');

    expect(
      find.widgetWithText(SnackBar, 'Invalid credentials'),
      findsOneWidget,
    );
  });

  testWidgets('meets accessibility guidelines', (tester) async {
    await pumpLoginPage(tester);

    await expectMeetsAccessibilityGuidelines(tester);
  });
}
