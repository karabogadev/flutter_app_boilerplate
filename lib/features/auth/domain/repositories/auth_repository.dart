import '../../../../core/result/result.dart';
import '../entities/user.dart';

/// Single source of truth for the auth session.
///
/// The router guard, [AuthBloc] and the token-refresh interceptor all read or
/// change the session through this repository only; nothing else touches
/// tokens or the cached user.
abstract interface class AuthRepository {
  /// The signed-in user, or null. Held in memory, so it is safe to read
  /// synchronously (e.g. from a route guard).
  User? get currentUser;

  bool get isAuthenticated;

  /// Emits whenever the session starts or ends, including when it expires
  /// because the refresh token was rejected.
  Stream<User?> get sessionChanges;

  /// Restores a persisted session on app start. Succeeds with null when
  /// there is no complete session (token + cached user) on the device.
  Future<Result<User?>> restoreSession();

  Future<Result<User>> login({
    required String email,
    required String password,
  });

  Future<Result<User>> register({
    required String email,
    required String password,
    String? name,
  });

  Future<Result<void>> logout();

  /// Ends the session without calling the server. Used when the refresh
  /// token is rejected.
  Future<void> expireSession();
}
