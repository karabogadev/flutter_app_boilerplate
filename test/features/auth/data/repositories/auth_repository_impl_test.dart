import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app_boilerplate/core/error/exceptions.dart';
import 'package:flutter_app_boilerplate/core/error/failures.dart';
import 'package:flutter_app_boilerplate/features/auth/data/models/user_model.dart';
import 'package:flutter_app_boilerplate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_app_boilerplate/features/auth/domain/entities/user.dart';

import '../../../../mocks/mocks.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemote;
  late MockAuthLocalDataSource mockLocal;
  late MockDioClient mockDioClient;
  late MockSyncQueue mockSyncQueue;

  setUp(() {
    mockRemote = MockAuthRemoteDataSource();
    mockLocal = MockAuthLocalDataSource();
    mockDioClient = MockDioClient();
    mockSyncQueue = MockSyncQueue();

    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemote,
      localDataSource: mockLocal,
      dioClient: mockDioClient,
      syncQueue: mockSyncQueue,
    );
  });

  setUpAll(registerFallbackValues);

  final tUser = TestData.testUser;
  final tUserModel = UserModel(
    id: tUser.id,
    email: tUser.email,
    name: tUser.name,
    avatarUrl: tUser.avatarUrl,
    createdAt: tUser.createdAt,
  );
  final tAuthResponse = AuthResponse(
    user: tUserModel,
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
  );

  // ─────────────────────────────────────────────────────────────
  // login()
  // ─────────────────────────────────────────────────────────────

  group('login()', () {
    test('returns Right(User), saves tokens and sets DioClient header', () async {
      when(() => mockRemote.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => tAuthResponse);
      when(() => mockLocal.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});
      when(() => mockDioClient.setAuthToken(any())).thenReturn(null);
      when(() => mockLocal.saveUser(any())).thenAnswer((_) async {});

      final result = await repository.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, Right<Failure, User>(tUser));
      verify(() => mockLocal.saveTokens(
            accessToken: 'access-token',
            refreshToken: 'refresh-token',
          )).called(1);
      verify(() => mockDioClient.setAuthToken('access-token')).called(1);
      verify(() => mockLocal.saveUser(tUserModel)).called(1);
    });

    test('returns Left(ServerFailure) on ServerException', () async {
      when(() => mockRemote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(const ServerException(message: 'Invalid credentials', statusCode: 401));

      final result =
          await repository.login(email: 'test@example.com', password: 'wrong');

      expect(result,
          const Left<Failure, User>(
              ServerFailure(message: 'Invalid credentials', statusCode: 401)));
    });

    test('returns Left(NetworkFailure) on NetworkException', () async {
      when(() => mockRemote.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(const NetworkException(message: 'No internet'));

      final result = await repository.login(
          email: 'test@example.com', password: 'password123');

      expect(result,
          const Left<Failure, User>(NetworkFailure(message: 'No internet')));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // register()
  // ─────────────────────────────────────────────────────────────

  group('register()', () {
    test('returns Right(User) on success', () async {
      when(() => mockRemote.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
          )).thenAnswer((_) async => tAuthResponse);
      when(() => mockLocal.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});
      when(() => mockDioClient.setAuthToken(any())).thenReturn(null);
      when(() => mockLocal.saveUser(any())).thenAnswer((_) async {});

      final result = await repository.register(
        email: 'new@example.com',
        password: 'password123',
        name: 'New User',
      );

      expect(result, Right<Failure, User>(tUser));
    });

    test('returns Left(ServerFailure) on ServerException', () async {
      when(() => mockRemote.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
          )).thenThrow(const ServerException(message: 'Email taken'));

      final result = await repository.register(
          email: 'taken@example.com', password: 'password123');

      expect(result,
          const Left<Failure, User>(ServerFailure(message: 'Email taken')));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // getCurrentUser()
  // ─────────────────────────────────────────────────────────────

  group('getCurrentUser()', () {
    test('returns Right(User) and restores DioClient token', () async {
      when(() => mockLocal.getUser())
          .thenAnswer((_) async => tUserModel);
      when(() => mockLocal.getAccessToken())
          .thenAnswer((_) async => 'stored-token');
      when(() => mockDioClient.setAuthToken(any())).thenReturn(null);

      final result = await repository.getCurrentUser();

      expect(result, Right<Failure, User?>(tUser));
      verify(() => mockDioClient.setAuthToken('stored-token')).called(1);
    });

    test('returns Right(null) when no user is cached', () async {
      when(() => mockLocal.getUser()).thenAnswer((_) async => null);

      final result = await repository.getCurrentUser();

      expect(result, const Right<Failure, User?>(null));
      verifyNever(() => mockDioClient.setAuthToken(any()));
    });

    test('returns Left(CacheFailure) on CacheException', () async {
      when(() => mockLocal.getUser())
          .thenThrow(const CacheException(message: 'Read error'));

      final result = await repository.getCurrentUser();

      expect(result,
          const Left<Failure, User?>(CacheFailure(message: 'Read error')));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // logout()
  // ─────────────────────────────────────────────────────────────

  group('logout()', () {
    test('clears tokens, sync queue and DioClient header on success', () async {
      when(() => mockRemote.logout()).thenAnswer((_) async {});
      when(() => mockLocal.clearAll()).thenAnswer((_) async {});
      when(() => mockSyncQueue.clearPending()).thenAnswer((_) async {});
      when(() => mockDioClient.clearAuthToken()).thenReturn(null);

      final result = await repository.logout();

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => mockLocal.clearAll()).called(1);
      verify(() => mockSyncQueue.clearPending()).called(1);
      verify(() => mockDioClient.clearAuthToken()).called(1);
    });

    test('succeeds even when remote logout fails', () async {
      when(() => mockRemote.logout())
          .thenThrow(const ServerException(message: 'Server error'));
      when(() => mockLocal.clearAll()).thenAnswer((_) async {});
      when(() => mockSyncQueue.clearPending()).thenAnswer((_) async {});
      when(() => mockDioClient.clearAuthToken()).thenReturn(null);

      final result = await repository.logout();

      // Remote failure should not block local cleanup.
      expect(result, const Right<Failure, Unit>(unit));
      verify(() => mockLocal.clearAll()).called(1);
    });

    test('returns Left(CacheFailure) when local clearAll fails', () async {
      when(() => mockRemote.logout()).thenAnswer((_) async {});
      when(() => mockLocal.clearAll())
          .thenThrow(const CacheException(message: 'Clear failed'));

      final result = await repository.logout();

      expect(result,
          const Left<Failure, Unit>(CacheFailure(message: 'Clear failed')));
    });
  });
}
