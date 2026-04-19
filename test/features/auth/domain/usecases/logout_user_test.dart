import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app_boilerplate/core/error/failures.dart';
import 'package:flutter_app_boilerplate/core/usecases/usecase.dart';
import 'package:flutter_app_boilerplate/features/auth/domain/usecases/logout_user.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late LogoutUser usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = LogoutUser(mockRepository);
  });

  setUpAll(registerFallbackValues);

  group('LogoutUser', () {
    test('should return Unit on successful logout', () async {
      when(() => mockRepository.logout())
          .thenAnswer((_) async => const Right(unit));

      final result = await usecase(const NoParams());

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => mockRepository.logout()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return CacheFailure when local cleanup fails', () async {
      when(() => mockRepository.logout()).thenAnswer((_) async =>
          const Left(CacheFailure(message: 'Failed to clear tokens')));

      final result = await usecase(const NoParams());

      expect(result,
          const Left<Failure, Unit>(
              CacheFailure(message: 'Failed to clear tokens')));
    });
  });
}
