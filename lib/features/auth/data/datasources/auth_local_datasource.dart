import '../../../../core/cache/cache_keys.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/secure_cache_manager.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  });

  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<void> saveUser(UserModel user);

  Future<UserModel?> getUser();

  Future<void> clearAll();
}

/// Tokens are stored in the platform keychain/keystore via [SecureCacheManager].
/// Non-sensitive user data (profile) is stored in [CacheManager].
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final CacheManager cacheManager;
  final SecureCacheManager secureCacheManager;

  AuthLocalDataSourceImpl({
    required this.cacheManager,
    required this.secureCacheManager,
  });

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    try {
      await secureCacheManager.write(_accessTokenKey, accessToken);
      if (refreshToken != null) {
        await secureCacheManager.write(_refreshTokenKey, refreshToken);
      }
    } catch (e) {
      throw CacheException(message: 'Failed to save tokens: $e');
    }
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      return secureCacheManager.read(_accessTokenKey);
    } catch (e) {
      throw CacheException(message: 'Failed to get access token: $e');
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return secureCacheManager.read(_refreshTokenKey);
    } catch (e) {
      throw CacheException(message: 'Failed to get refresh token: $e');
    }
  }

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      await cacheManager.setObject(CacheKeys.user, user);
    } catch (e) {
      throw CacheException(message: 'Failed to save user: $e');
    }
  }

  @override
  Future<UserModel?> getUser() async {
    try {
      return cacheManager.getObject(
        CacheKeys.user,
        UserModel.fromJson,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to get user: $e');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await secureCacheManager.delete(_accessTokenKey);
      await secureCacheManager.delete(_refreshTokenKey);
      await cacheManager.remove(CacheKeys.user);
    } catch (e) {
      throw CacheException(message: 'Failed to clear auth data: $e');
    }
  }
}
