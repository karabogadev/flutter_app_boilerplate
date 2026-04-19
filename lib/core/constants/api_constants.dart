/// API constants. Override BASE_URL via --dart-define or --dart-define-from-file.
///
/// Usage:
///   flutter run --dart-define-from-file=.env.dev
///   flutter build apk --dart-define-from-file=.env.prod
///
/// .env.dev example:
///   { "BASE_URL": "https://dev-api.example.com" }
abstract class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String user = '/user';
  static const String users = '/users';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Headers
  static const String contentType = 'application/json';
  static const String accept = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';
}
