import 'dart:async';

import '../../../../core/network/dio_client.dart';
import '../../../../core/offline/sync_queue.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required DioClient dioClient,
    required SyncQueue syncQueue,
  })  : _remote = remoteDataSource,
        _local = localDataSource,
        _dioClient = dioClient,
        _syncQueue = syncQueue;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final DioClient _dioClient;
  final SyncQueue _syncQueue;

  final _sessionController = StreamController<User?>.broadcast();
  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  Stream<User?> get sessionChanges => _sessionController.stream;

  @override
  Future<Result<User?>> restoreSession() => Result.guard(() async {
        final token = await _local.getAccessToken();
        final user = token == null ? null : _local.getUser()?.toEntity();

        if (token == null || user == null) {
          // A token without a profile (or vice versa) is not a usable
          // session; wipe the leftovers so every check agrees.
          if (token != null || _local.getUser() != null) {
            await _local.clearAll();
          }
          _setUser(null);
          return null;
        }

        _dioClient.setAuthToken(token);
        _setUser(user);
        return user;
      });

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) =>
      Result.guard(() async {
        final response = await _remote.login(email: email, password: password);
        return _startSession(response);
      });

  @override
  Future<Result<User>> register({
    required String email,
    required String password,
    String? name,
  }) =>
      Result.guard(() async {
        final response = await _remote.register(
          email: email,
          password: password,
          name: name,
        );
        return _startSession(response);
      });

  @override
  Future<Result<void>> logout() async {
    await _remote.logout();
    return Result.guard(_endSession);
  }

  @override
  Future<void> expireSession() => Result.guard(_endSession);

  Future<User> _startSession(AuthResponse response) async {
    await _local.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    await _local.saveUser(response.user);
    _dioClient.setAuthToken(response.accessToken);

    final user = response.user.toEntity();
    _setUser(user);
    return user;
  }

  /// Ends the in-memory session first, so even if clearing storage fails the
  /// app never keeps acting as the previous user. Pending sync operations are
  /// dropped so they are not sent with another user's token.
  Future<void> _endSession() async {
    _dioClient.clearAuthToken();
    _setUser(null);
    await Future.wait([_local.clearAll(), _syncQueue.clearPending()]);
  }

  void _setUser(User? user) {
    if (user == _currentUser) return;
    _currentUser = user;
    _sessionController.add(user);
  }

  Future<void> dispose() => _sessionController.close();
}
