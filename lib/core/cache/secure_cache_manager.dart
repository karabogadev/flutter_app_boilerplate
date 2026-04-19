import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure key-value storage backed by the platform keychain/keystore.
/// Use this for sensitive data: tokens, passwords, PII.
/// Non-sensitive preferences (theme, locale) belong in CacheManager.
class SecureCacheManager {
  SecureCacheManager._internal();
  static SecureCacheManager? _instance;

  static SecureCacheManager get instance {
    _instance ??= SecureCacheManager._internal();
    return _instance!;
  }

  factory SecureCacheManager() => instance;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();

  Future<bool> containsKey(String key) => _storage.containsKey(key: key);
}
