import 'dart:developer' as developer;

/// Thin wrapper around `dart:developer` [developer.log].
///
/// Output shows up in DevTools' Logging view and the IDE debug console, and
/// costs nothing in release builds. Hook a crash reporter into [error].
abstract final class AppLogger {
  static void debug(String message, {String name = 'app'}) =>
      developer.log(message, name: name, level: 500);

  static void info(String message, {String name = 'app'}) =>
      developer.log(message, name: name, level: 800);

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = 'app',
  }) => developer.log(
    message,
    name: name,
    level: 1000,
    error: error,
    stackTrace: stackTrace,
  );
}
