import 'package:equatable/equatable.dart';

import 'exceptions.dart';

/// User-facing error returned by repositories inside a `Result`.
///
/// The hierarchy is sealed so `switch` statements over a [Failure] are
/// checked for exhaustiveness by the compiler.
sealed class Failure extends Equatable {
  const Failure(this.message);

  /// Maps a data-layer exception to the matching [Failure].
  factory Failure.fromException(Exception exception) => switch (exception) {
    ServerException(:final message, :final statusCode) => ServerFailure(
      message: message,
      statusCode: statusCode,
    ),
    NetworkException(:final message) => NetworkFailure(message: message),
    CacheException(:final message) => CacheFailure(message: message),
    _ => const UnexpectedFailure(),
  };

  final String message;

  @override
  List<Object?> get props => [message];
}

final class ServerFailure extends Failure {
  const ServerFailure({
    String message = 'Server error occurred',
    this.statusCode,
  }) : super(message);

  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

final class CacheFailure extends Failure {
  const CacheFailure({String message = 'Cache error'}) : super(message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'No internet connection'})
    : super(message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure({String message = 'Validation error'})
    : super(message);
}

/// An exception the data layer did not anticipate. The original error is
/// logged where it is caught; the user only sees a generic message.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({String message = 'Something went wrong'})
    : super(message);
}
