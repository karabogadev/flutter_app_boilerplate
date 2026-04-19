import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app_boilerplate/core/error/failures.dart';
import 'package:flutter_app_boilerplate/features/auth/domain/usecases/login_user.dart';
import 'package:flutter_app_boilerplate/features/auth/domain/usecases/register_user.dart';
import 'package:flutter_app_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_app_boilerplate/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_app_boilerplate/features/auth/presentation/bloc/auth_state.dart';

import '../../../../mocks/mocks.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late AuthBloc bloc;
  late MockLoginUser mockLoginUser;
  late MockRegisterUser mockRegisterUser;
  late MockLogoutUser mockLogoutUser;
  late MockGetCurrentUser mockGetCurrentUser;

  setUp(() {
    mockLoginUser = MockLoginUser();
    mockRegisterUser = MockRegisterUser();
    mockLogoutUser = MockLogoutUser();
    mockGetCurrentUser = MockGetCurrentUser();

    bloc = AuthBloc(
      loginUser: mockLoginUser,
      registerUser: mockRegisterUser,
      logoutUser: mockLogoutUser,
      getCurrentUser: mockGetCurrentUser,
    );
  });

  setUpAll(() {
    registerFallbackValues();
  });

  tearDown(() {
    bloc.close();
  });

  final tUser = TestData.testUser;

  test('initial state should be AuthInitial', () {
    expect(bloc.state, equals(const AuthInitial()));
  });

  group('LoginEvent', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when login succeeds',
      build: () {
        when(() => mockLoginUser(any()))
            .thenAnswer((_) async => Right(tUser));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoginEvent(
        email: tEmail,
        password: tPassword,
      )),
      expect: () => [const AuthLoading(), Authenticated(tUser)],
      verify: (_) {
        verify(() => mockLoginUser(const LoginParams(
              email: tEmail,
              password: tPassword,
            ))).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when login fails',
      build: () {
        when(() => mockLoginUser(any())).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Invalid credentials')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoginEvent(
        email: tEmail,
        password: tPassword,
      )),
      expect: () => [
        const AuthLoading(),
        const AuthError('Invalid credentials'),
      ],
    );
  });

  group('RegisterEvent', () {
    const tEmail = 'new@example.com';
    const tPassword = 'password123';
    const tName = 'New User';

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when register succeeds',
      build: () {
        when(() => mockRegisterUser(any()))
            .thenAnswer((_) async => Right(tUser));
        return bloc;
      },
      act: (bloc) => bloc.add(const RegisterEvent(
        email: tEmail,
        password: tPassword,
        name: tName,
      )),
      expect: () => [const AuthLoading(), Authenticated(tUser)],
      verify: (_) {
        verify(() => mockRegisterUser(const RegisterParams(
              email: tEmail,
              password: tPassword,
              name: tName,
            ))).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when register fails',
      build: () {
        when(() => mockRegisterUser(any())).thenAnswer(
            (_) async => const Left(ServerFailure(message: 'Email taken')));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const RegisterEvent(email: tEmail, password: tPassword)),
      expect: () => [
        const AuthLoading(),
        const AuthError('Email taken'),
      ],
    );
  });

  group('LogoutEvent', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when logout succeeds',
      build: () {
        when(() => mockLogoutUser(any()))
            .thenAnswer((_) async => const Right(unit));
        return bloc;
      },
      act: (bloc) => bloc.add(const LogoutEvent()),
      expect: () => [const AuthLoading(), const Unauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when logout fails',
      build: () {
        when(() => mockLogoutUser(any())).thenAnswer(
            (_) async => const Left(CacheFailure(message: 'Clear failed')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LogoutEvent()),
      expect: () => [
        const AuthLoading(),
        const AuthError('Clear failed'),
      ],
    );
  });

  group('CheckAuthStatusEvent', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when user is logged in',
      build: () {
        when(() => mockGetCurrentUser(any()))
            .thenAnswer((_) async => Right(tUser));
        return bloc;
      },
      act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
      expect: () => [const AuthLoading(), Authenticated(tUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when user is not logged in',
      build: () {
        when(() => mockGetCurrentUser(any())).thenAnswer(
            (_) async =>
                const Left(CacheFailure(message: 'No user found')));
        return bloc;
      },
      act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
      expect: () => [const AuthLoading(), const Unauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when getCurrentUser returns null user',
      build: () {
        when(() => mockGetCurrentUser(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const CheckAuthStatusEvent()),
      expect: () => [const AuthLoading(), const Unauthenticated()],
    );
  });
}
