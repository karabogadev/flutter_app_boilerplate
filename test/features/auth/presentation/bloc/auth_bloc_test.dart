import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_app_boilerplate/core/error/failures.dart';
import 'package:flutter_app_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_auth_repository.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  final user = TestData.testUser;

  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());
  tearDown(() => repository.dispose());

  AuthBloc buildBloc() => AuthBloc(authRepository: repository);

  test('initial state is AuthInitial', () async {
    final bloc = buildBloc();
    expect(bloc.state, const AuthInitial());
    await bloc.close();
  });

  group('CheckAuthStatusEvent', () {
    blocTest<AuthBloc, AuthState>(
      'emits Authenticated when a session is restored',
      setUp: () => repository = FakeAuthRepository(persistedUser: user),
      build: buildBloc,
      act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
      expect: () => [const AuthLoading(), Authenticated(user)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits Unauthenticated when there is no stored session',
      build: buildBloc,
      act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
      expect: () => [const AuthLoading(), const Unauthenticated()],
    );
  });

  group('LoginEvent', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] on success',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const LoginEvent(email: 'test@example.com', password: 'secret'),
      ),
      expect: () => [const AuthLoading(), Authenticated(user)],
      verify: (_) => expect(repository.currentUser, user),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] with the failure message',
      setUp: () => repository.signInFailure = const ServerFailure(
        message: 'Invalid credentials',
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(
        const LoginEvent(email: 'test@example.com', password: 'wrong'),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError('Invalid credentials'),
      ],
    );
  });

  group('RegisterEvent', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] on success',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const RegisterEvent(
          email: 'test@example.com',
          password: 'secret',
          name: 'Test',
        ),
      ),
      expect: () => [const AuthLoading(), Authenticated(user)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on failure',
      setUp: () => repository.signInFailure = const NetworkFailure(),
      build: buildBloc,
      act: (bloc) => bloc.add(
        const RegisterEvent(email: 'test@example.com', password: 'secret'),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError('No internet connection'),
      ],
    );
  });

  group('LogoutEvent', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] and ends the session',
      setUp: () => repository = FakeAuthRepository(persistedUser: user),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const CheckAuthStatusEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const LogoutEvent());
      },
      skip: 2,
      expect: () => [const AuthLoading(), const Unauthenticated()],
      verify: (_) => expect(repository.isAuthenticated, isFalse),
    );

    // Regression: with a real session, the repository's session change and a
    // cleanup failure used to race and emit AuthError after Unauthenticated.
    blocTest<AuthBloc, AuthState>(
      'still signs out, without an error, when local cleanup fails',
      setUp: () {
        repository = FakeAuthRepository(persistedUser: user)
          ..logoutFailure = const CacheFailure();
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const CheckAuthStatusEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const LogoutEvent());
        // Let the session-change event and the logout result both land.
        await Future<void>.delayed(Duration.zero);
      },
      skip: 2,
      expect: () => [const AuthLoading(), const Unauthenticated()],
      verify: (bloc) {
        expect(bloc.state, const Unauthenticated());
        expect(repository.isAuthenticated, isFalse);
      },
    );
  });

  group('session changes from the repository', () {
    blocTest<AuthBloc, AuthState>(
      'emits Unauthenticated when the session expires',
      setUp: () => repository = FakeAuthRepository(persistedUser: user),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const CheckAuthStatusEvent());
        await Future<void>.delayed(Duration.zero);
        await repository.expireSession();
      },
      expect: () => [
        const AuthLoading(),
        Authenticated(user),
        const Unauthenticated(),
      ],
    );
  });
}
