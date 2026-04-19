import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app_boilerplate/core/error/failures.dart';
import 'package:flutter_app_boilerplate/core/usecases/usecase.dart';
import 'package:flutter_app_boilerplate/features/auth/domain/entities/user.dart';
import 'package:flutter_app_boilerplate/features/auth/domain/usecases/get_current_user.dart';

import '../../../../mocks/mocks.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late GetCurrentUser usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = GetCurrentUser(mockRepository);
  });

  setUpAll(registerFallbackValues);

  final tUser = TestData.testUser;

  group('GetCurrentUser', () {
    test('should return User when a session exists', () async {
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => Right<Failure, User?>(tUser));

      final result = await usecase(const NoParams());

      expect(result, Right<Failure, User?>(tUser));
      verify(() => mockRepository.getCurrentUser()).called(1);
    });

    test('should return null when no session exists', () async {
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => const Right<Failure, User?>(null));

      final result = await usecase(const NoParams());

      expect(result, const Right<Failure, User?>(null));
    });

    test('should return CacheFailure when reading session fails', () async {
      when(() => mockRepository.getCurrentUser()).thenAnswer((_) async =>
          const Left(CacheFailure(message: 'Failed to read cache')));

      final result = await usecase(const NoParams());

      expect(result,
          const Left<Failure, User?>(
              CacheFailure(message: 'Failed to read cache')));
    });
  });
}
