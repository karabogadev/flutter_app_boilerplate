import 'dart:async';

import 'package:flutter_app_boilerplate/core/error/failures.dart';
import 'package:flutter_app_boilerplate/core/result/result.dart';
import 'package:flutter_app_boilerplate/features/auth/domain/entities/user.dart';
import 'package:flutter_app_boilerplate/features/auth/domain/repositories/auth_repository.dart';

import '../helpers/test_helpers.dart';

/// In-memory [AuthRepository] with real session semantics, following the
/// docs' "fakes over mocks" guidance. Configure outcomes through the public
/// fields, then assert on state instead of verifying calls.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({User? persistedUser}) : _persistedUser = persistedUser;

  /// User restored by [restoreSession]; null means no stored session.
  final User? _persistedUser;

  /// When set, [login] and [register] fail with this instead of succeeding.
  Failure? signInFailure;

  /// When set, [logout] fails with this after ending the session.
  Failure? logoutFailure;

  /// User returned by a successful [login] or [register].
  User signInUser = TestData.testUser;

  final _sessionController = StreamController<User?>.broadcast();
  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  Stream<User?> get sessionChanges => _sessionController.stream;

  @override
  Future<Result<User?>> restoreSession() async {
    _setUser(_persistedUser);
    return Result.ok(_persistedUser);
  }

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async => _signIn();

  @override
  Future<Result<User>> register({
    required String email,
    required String password,
    String? name,
  }) async => _signIn();

  @override
  Future<Result<void>> logout() async {
    _setUser(null);
    final failure = logoutFailure;
    return failure == null ? const Result.ok(null) : Result.error(failure);
  }

  @override
  Future<void> expireSession() async => _setUser(null);

  Result<User> _signIn() {
    final failure = signInFailure;
    if (failure != null) return Result.error(failure);
    _setUser(signInUser);
    return Result.ok(signInUser);
  }

  void _setUser(User? user) {
    if (user == _currentUser) return;
    _currentUser = user;
    _sessionController.add(user);
  }

  Future<void> dispose() => _sessionController.close();
}
