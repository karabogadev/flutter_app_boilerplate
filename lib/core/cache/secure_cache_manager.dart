import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure key-value storage backed by the platform keychain/keystore.
/// Use this for sensitive data: tokens, passwords, PII.
/// Non-sensitive preferences (theme, onboarding) belong in `CacheManager`.
class SecureCacheManager {
  SecureCacheManager([FlutterSecureStorage? storage])
    : _storage = storage ?? _defaultStorage;

  static const _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final FlutterSecureStorage _storage;

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();

  Future<bool> containsKey(String key) => _storage.containsKey(key: key);
}
