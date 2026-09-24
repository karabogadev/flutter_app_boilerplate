import 'package:flutter_app_boilerplate/core/cache/cache_keys.dart';
import 'package:flutter_app_boilerplate/core/cache/cache_manager.dart';
import 'package:flutter_app_boilerplate/features/auth/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late CacheManager cache;

  Future<CacheManager> build([Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    return CacheManager(await SharedPreferences.getInstance());
  }

  setUp(() async => cache = await build());

  test('round-trips primitives synchronously after a write', () async {
    await cache.setBool(CacheKeys.onboardingCompleted, value: true);
    await cache.setString(CacheKeys.themeMode, 'dark');

    expect(cache.getBool(CacheKeys.onboardingCompleted), isTrue);
    expect(cache.getString(CacheKeys.themeMode), 'dark');
  });

  test('setString(null) removes the key', () async {
    await cache.setString(CacheKeys.themeMode, 'dark');
    await cache.setString(CacheKeys.themeMode, null);

    expect(cache.getString(CacheKeys.themeMode), isNull);
  });

  test('round-trips a CacheableModel', () async {
    final user = UserModel(
      id: '1',
      email: 'a@b.c',
      createdAt: DateTime.utc(2024),
    );

    await cache.setObject(CacheKeys.user, user);

    expect(cache.getObject(CacheKeys.user, UserModel.fromJson), user);
  });

  test('returns null for JSON that no longer matches the model', () async {
    cache = await build({CacheKeys.user.key: '{"unexpected": true}'});

    expect(cache.getObject(CacheKeys.user, UserModel.fromJson), isNull);
  });
}
