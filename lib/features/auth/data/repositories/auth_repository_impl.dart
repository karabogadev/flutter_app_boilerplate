import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/offline/sync_queue.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final DioClient dioClient;
  final SyncQueue syncQueue;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.dioClient,
    required this.syncQueue,
  });

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.login(
        email: email,
        password: password,
      );
      return Right(await _persistAuthResult(result));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final result = await remoteDataSource.register(
        email: email,
        password: password,
        name: name,
      );
      return Right(await _persistAuthResult(result));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await localDataSource.getUser();
      if (user != null) {
        final token = await localDataSource.getAccessToken();
        if (token != null) {
          dioClient.setAuthToken(token);
        }
      }
      return Right(user?.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    // Remote logout is best-effort — a server error doesn't block local cleanup.
    try {
      await remoteDataSource.logout();
    } catch (_) {}

    // Local cleanup must succeed — if it fails the user is in a broken state.
    try {
      await localDataSource.clearAll();
      await syncQueue.clearPending();
      dioClient.clearAuthToken();
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final token = await localDataSource.getAccessToken();
      return Right(token != null);
    } catch (_) {
      return const Right(false);
    }
  }

  Future<User> _persistAuthResult(AuthResponse result) async {
    await localDataSource.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    dioClient.setAuthToken(result.accessToken);
    await localDataSource.saveUser(result.user);
    return result.user.toEntity();
  }
}
