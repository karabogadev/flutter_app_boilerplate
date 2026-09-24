import 'package:flutter_app_boilerplate/features/auth/domain/entities/user.dart';

class TestData {
  static User get testUser => User(
    id: 'test-user-id',
    email: 'test@example.com',
    name: 'Test User',
    avatarUrl: 'https://example.com/avatar.png',
    createdAt: DateTime(2024, 1, 1),
  );

  static String get validEmail => 'test@example.com';
  static String get validPassword => 'Password123';
  static String get invalidEmail => 'invalid-email';
  static String get shortPassword => '123';

  static Map<String, dynamic> get userJson => {
    'id': 'test-user-id',
    'email': 'test@example.com',
    'name': 'Test User',
    'avatar_url': 'https://example.com/avatar.png',
    'created_at': '2024-01-01T00:00:00.000Z',
  };

  static Map<String, dynamic> get authResponseJson => {
    'user': userJson,
    'access_token': 'test-access-token',
    'refresh_token': 'test-refresh-token',
  };
}
