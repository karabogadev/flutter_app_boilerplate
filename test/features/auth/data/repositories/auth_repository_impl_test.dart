import 'package:flutter_app_boilerplate/core/error/exceptions.dart';
import 'package:flutter_app_boilerplate/core/error/failures.dart';
import 'package:flutter_app_boilerplate/core/result/result.dart';
import 'package:flutter_app_boilerplate/features/auth/data/models/user_model.dart';
import 'package:flutter_app_boilerplate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_helpers.dart';
import '../../../../mocks/mocks.dart';

void main() {
  late MockAuthRemoteDataSource remote;
  late MockAuthLocalDataSource local;
  late MockDioClient dioClient;
  late MockSyncQueue syncQueue;
  late AuthRepositoryImpl repository;

  final user = TestData.testUser;
  final userModel = UserModel.fromEntity(user);
  final authResponse = AuthResponse(
    user: userModel,
    accessToken: 'access',
    refreshToken: 'refresh',
  );

  setUpAll(registerFallbackValues);

  setUp(() {
    remote = MockAuthRemoteDataSource();
    local = MockAuthLocalDataSource();
    dioClient = MockDioClient();
    syncQueue = MockSyncQueue();
    repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      dioClient: dioClient,
      syncQueue: syncQueue,
    );

    when(
      () => local.saveTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async {});
    when(() => local.saveUser(any())).thenAnswer((_) async {});
    when(() => local.clearAll()).thenAnswer((_) async {});
    when(() => syncQueue.clearPending()).thenAnswer((_) async {});
    when(() => remote.logout()).thenAnswer((_) async {});
  });

  tearDown(() => repository.dispose());

  group('restoreSession', () {
    test('restores a complete session and sets the auth header', () async {
      when(() => local.getAccessToken()).thenAnswer((_) async => 'access');
      when(() => local.getUser()).thenReturn(userModel);

      final result = await repository.restoreSession();

      expect(result, Result<Object?>.ok(user));
      expect(repository.currentUser, user);
      expect(repository.isAuthenticated, isTrue);
      verify(() => dioClient.setAuthToken('access')).called(1);
    });

    test('returns null when nothing is stored', () async {
      when(() => local.getAccessToken()).thenAnswer((_) async => null);
      when(() => local.getUser()).thenReturn(null);

      final result = await repository.restoreSession();

      expect(result, const Result<Object?>.ok(null));
      expect(repository.isAuthenticated, isFalse);
      verifyNever(() => local.clearAll());
    });

    test('wipes a token that has no cached user', () async {
      when(() => local.getAccessToken()).thenAnswer((_) async => 'access');
      when(() => local.getUser()).thenReturn(null);

      final result = await repository.restoreSession();

      expect(result, const Result<Object?>.ok(null));
      expect(repository.isAuthenticated, isFalse);
      verify(() => local.clearAll()).called(1);
      verifyNever(() => dioClient.setAuthToken(any()));
    });

    test('returns CacheFailure when secure storage fails', () async {
      when(
        () => local.getAccessToken(),
      ).thenThrow(const CacheException(message: 'keychain locked'));

      final result = await repository.restoreSession();

      expect(
        result,
        const Result<Object?>.error(CacheFailure(message: 'keychain locked')),
      );
    });
  });

  group('login', () {
    test('persists tokens and user, then starts the session', () async {
      when(
        () => remote.login(email: 'a@b.c', password: 'pw'),
      ).thenAnswer((_) async => authResponse);
      final sessions = <Object?>[];
      final subscription = repository.sessionChanges.listen(sessions.add);

      final result = await repository.login(email: 'a@b.c', password: 'pw');
      await Future<void>.delayed(Duration.zero);

      expect(result, Result<Object?>.ok(user));
      expect(repository.currentUser, user);
      expect(sessions, [user]);
      verify(
        () => local.saveTokens(accessToken: 'access', refreshToken: 'refresh'),
      ).called(1);
      verify(() => local.saveUser(userModel)).called(1);
      verify(() => dioClient.setAuthToken('access')).called(1);
      await subscription.cancel();
    });

    test('maps a ServerException to ServerFailure', () async {
      when(
        () => remote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const ServerException(message: 'Invalid credentials', statusCode: 401),
      );

      final result = await repository.login(email: 'a@b.c', password: 'x');

      expect(
        result,
        const Result<Object?>.error(
          ServerFailure(message: 'Invalid credentials', statusCode: 401),
        ),
      );
      expect(repository.isAuthenticated, isFalse);
    });

    test('maps a NetworkException to NetworkFailure', () async {
      when(
        () => remote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const NetworkException(message: 'No internet connection'));

      final result = await repository.login(email: 'a@b.c', password: 'x');

      expect(
        result,
        const Result<Object?>.error(
          NetworkFailure(message: 'No internet connection'),
        ),
      );
    });
  });

  group('register', () {
    test('starts a session like login does', () async {
      when(
        () => remote.register(email: 'a@b.c', password: 'pw', name: 'Test'),
      ).thenAnswer((_) async => authResponse);

      final result = await repository.register(
        email: 'a@b.c',
        password: 'pw',
        name: 'Test',
      );

      expect(result, Result<Object?>.ok(user));
      expect(repository.isAuthenticated, isTrue);
    });
  });

  group('logout', () {
    setUp(() async {
      when(
        () => remote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => authResponse);
      await repository.login(email: 'a@b.c', password: 'pw');
    });

    test('ends the session and clears local data and pending sync', () async {
      final result = await repository.logout();

      expect(result, const Result<void>.ok(null));
      expect(repository.isAuthenticated, isFalse);
      verify(() => remote.logout()).called(1);
      verify(() => local.clearAll()).called(1);
      verify(() => syncQueue.clearPending()).called(1);
      verify(() => dioClient.clearAuthToken()).called(1);
    });

    test('ends the in-memory session even if storage cleanup fails', () async {
      when(
        () => local.clearAll(),
      ).thenThrow(const CacheException(message: 'disk full'));

      final result = await repository.logout();

      expect(
        result,
        const Result<void>.error(CacheFailure(message: 'disk full')),
      );
      expect(repository.isAuthenticated, isFalse);
      verify(() => dioClient.clearAuthToken()).called(1);
    });
  });

  test('expireSession ends the session without calling the server', () async {
    when(
      () => remote.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => authResponse);
    await repository.login(email: 'a@b.c', password: 'pw');
    final sessions = <Object?>[];
    final subscription = repository.sessionChanges.listen(sessions.add);

    await repository.expireSession();
    await Future<void>.delayed(Duration.zero);

    expect(repository.isAuthenticated, isFalse);
    expect(sessions, [null]);
    verifyNever(() => remote.logout());
    verify(() => local.clearAll()).called(1);
    await subscription.cancel();
  });
}
