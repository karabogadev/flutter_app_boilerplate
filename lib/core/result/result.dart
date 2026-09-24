import '../error/failures.dart';
import '../logging/app_logger.dart';

/// Outcome of an operation that can fail.
///
/// Follows https://docs.flutter.dev/app-architecture/design-patterns/result:
/// repositories return a [Result] instead of throwing, which forces callers to
/// handle the failure case. Unwrap it with an exhaustive `switch`:
///
/// ```dart
/// switch (await repository.login(...)) {
///   case Ok(:final value): ...
///   case Err(:final failure): ...
/// }
/// ```
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.error(Failure failure) = Err<T>;

  /// Runs [body] and converts any thrown [Exception] into an [Err] via
  /// [Failure.fromException]. [Error]s (programming bugs) are not caught.
  static Future<Result<T>> guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on Exception catch (e, stackTrace) {
      AppLogger.error('Result.guard caught', error: e, stackTrace: stackTrace);
      return Err(Failure.fromException(e));
    }
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) => other is Err<T> && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Err($failure)';
}
