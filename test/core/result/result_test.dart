import 'package:flutter_app_boilerplate/core/error/exceptions.dart';
import 'package:flutter_app_boilerplate/core/error/failures.dart';
import 'package:flutter_app_boilerplate/core/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result.guard', () {
    test('wraps the value in Ok', () async {
      expect(await Result.guard(() async => 42), const Result.ok(42));
    });

    test('maps each data-layer exception to its Failure', () async {
      final cases = <Exception, Failure>{
        const ServerException(message: 'boom', statusCode: 500):
            const ServerFailure(message: 'boom', statusCode: 500),
        const NetworkException(message: 'offline'): const NetworkFailure(
          message: 'offline',
        ),
        const CacheException(message: 'disk'): const CacheFailure(
          message: 'disk',
        ),
        const ParseException(): const UnexpectedFailure(),
        Exception('anything else'): const UnexpectedFailure(),
      };

      for (final MapEntry(key: exception, value: failure) in cases.entries) {
        expect(
          await Result.guard<int>(() async => throw exception),
          Result<int>.error(failure),
          reason: '$exception',
        );
      }
    });

    test('does not swallow Errors (programming bugs)', () {
      expect(
        Result.guard<int>(() async => throw StateError('bug')),
        throwsStateError,
      );
    });
  });

  test('switch over Result is exhaustive', () {
    String describe(Result<int> result) => switch (result) {
      Ok(:final value) => 'ok $value',
      Err(:final failure) => 'err ${failure.message}',
    };

    expect(describe(const Result.ok(1)), 'ok 1');
    expect(
      describe(const Result.error(NetworkFailure())),
      'err No internet connection',
    );
  });
}
