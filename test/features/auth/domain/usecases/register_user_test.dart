import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app_boilerplate/core/error/failures.dart';
import 'package:flutter_app_boilerplate/features/auth/domain/entities/user.dart';
import 'package:flutter_app_boilerplate/features/auth/domain/usecases/register_user.dart';

import '../../../../mocks/mocks.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late RegisterUser usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = RegisterUser(mockRepository);
  });

  setUpAll(registerFallbackValues);

  final tUser = TestData.testUser;
  const tParams = RegisterParams(
    email: 'new@example.com',
    password: 'password123',
    name: 'New User',
  );

  group('RegisterUser', () {
    test('should return User on successful registration', () async {
      when(() => mockRepository.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
          )).thenAnswer((_) async => Right<Failure, User>(tUser));

      final result = await usecase(tParams);

      expect(result, Right<Failure, User>(tUser));
      verify(() => mockRepository.register(
            email: tParams.email,
            password: tParams.password,
            name: tParams.name,
          )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when email is already taken', () async {
      when(() => mockRepository.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
          )).thenAnswer((_) async =>
          const Left<Failure, User>(ServerFailure(message: 'Email taken')));

      final result = await usecase(tParams);

      expect(result,
          const Left<Failure, User>(ServerFailure(message: 'Email taken')));
    });

    test('should return NetworkFailure when offline', () async {
      when(() => mockRepository.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
          )).thenAnswer((_) async =>
          const Left<Failure, User>(
              NetworkFailure(message: 'No internet connection')));

      final result = await usecase(tParams);

      expect(result,
          const Left<Failure, User>(
              NetworkFailure(message: 'No internet connection')));
    });

    test('should work without optional name param', () async {
      const noNameParams = RegisterParams(
        email: 'new@example.com',
        password: 'password123',
      );
      when(() => mockRepository.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
          )).thenAnswer((_) async => Right<Failure, User>(tUser));

      await usecase(noNameParams);

      verify(() => mockRepository.register(
            email: noNameParams.email,
            password: noNameParams.password,
            name: null,
          )).called(1);
    });
  });
}
