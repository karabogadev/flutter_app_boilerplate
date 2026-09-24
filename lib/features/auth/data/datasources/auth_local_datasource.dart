import '../../../../core/cache/cache_keys.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/secure_cache_manager.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract interface class AuthLocalDataSource {
  Future<void> saveTokens({required String accessToken, String? refreshToken});

  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<void> saveUser(UserModel user);

  UserModel? getUser();

  Future<void> clearAll();
}

/// Tokens are stored in the platform keychain/keystore via
/// [SecureCacheManager]. The non-sensitive user profile is stored in
/// [CacheManager].
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl({
    required CacheManager cacheManager,
    required SecureCacheManager secureCacheManager,
  }) : _cacheManager = cacheManager,
       _secureCacheManager = secureCacheManager;

  final CacheManager _cacheManager;
  final SecureCacheManager _secureCacheManager;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) => _guard('save tokens', () async {
    await _secureCacheManager.write(_accessTokenKey, accessToken);
    if (refreshToken != null) {
      await _secureCacheManager.write(_refreshTokenKey, refreshToken);
    }
  });

  @override
  Future<String?> getAccessToken() => _guard(
    'read access token',
    () => _secureCacheManager.read(_accessTokenKey),
  );

  @override
  Future<String?> getRefreshToken() => _guard(
    'read refresh token',
    () => _secureCacheManager.read(_refreshTokenKey),
  );

  @override
  Future<void> saveUser(UserModel user) =>
      _guard('save user', () => _cacheManager.setObject(CacheKeys.user, user));

  @override
  UserModel? getUser() =>
      _cacheManager.getObject(CacheKeys.user, UserModel.fromJson);

  @override
  Future<void> clearAll() => _guard('clear auth data', () async {
    await Future.wait([
      _secureCacheManager.delete(_accessTokenKey),
      _secureCacheManager.delete(_refreshTokenKey),
      _cacheManager.remove(CacheKeys.user),
    ]);
  });

  /// Awaits [body] so asynchronous storage errors are caught too, and wraps
  /// them in a [CacheException].
  Future<T> _guard<T>(String action, Future<T> Function() body) async {
    try {
      return await body();
    } on Exception catch (e) {
      throw CacheException(message: 'Failed to $action: $e');
    }
  }
}
