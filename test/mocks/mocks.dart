import 'package:mocktail/mocktail.dart';
import 'package:flutter_app_boilerplate/core/cache/cache_manager.dart';
import 'package:flutter_app_boilerplate/features/auth/data/models/user_model.dart';
import 'package:flutter_app_boilerplate/core/cache/secure_cache_manager.dart';
import 'package:flutter_app_boilerplate/core/database/hive_manager.dart';
import 'package:flutter_app_boilerplate/core/localization/localization_manager.dart';
import 'package:flutter_app_boilerplate/core/network/dio_client.dart';
import 'package:flutter_app_boilerplate/core/offline/connectivity_cubit.dart';
import 'package:flutter_app_boilerplate/core/offline/connectivity_service.dart';
import 'package:flutter_app_boilerplate/core/offline/offline_manager.dart';
import 'package:flutter_app_boilerplate/core/offline/sync_queue.dart';
import 'package:flutter_app_boilerplate/core/usecases/usecase.dart';
import 'package:flutter_app_boilerplate/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter_app_boilerplate/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_app_boilerplate/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_app_boilerplate/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_app_boilerplate/features/auth/domain/usecases/login_user.dart';
import 'package:flutter_app_boilerplate/features/auth/domain/usecases/logout_user.dart';
import 'package:flutter_app_boilerplate/features/auth/domain/usecases/register_user.dart';
import 'package:flutter_app_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_app_boilerplate/features/settings/presentation/bloc/locale_cubit.dart';
import 'package:flutter_app_boilerplate/features/settings/presentation/bloc/theme_cubit.dart';

// Core Mocks
class MockCacheManager extends Mock implements CacheManager {}
class MockSecureCacheManager extends Mock implements SecureCacheManager {}
class MockDioClient extends Mock implements DioClient {}
class MockLocalizationManager extends Mock implements LocalizationManager {}

// Offline-First Mocks
class MockHiveManager extends Mock implements HiveManager {}
class MockConnectivityService extends Mock implements ConnectivityService {}
class MockSyncQueue extends Mock implements SyncQueue {}
class MockOfflineManager extends Mock implements OfflineManager {}
class MockConnectivityCubit extends Mock implements ConnectivityCubit {}

// Auth Feature Mocks
class MockAuthRepository extends Mock implements AuthRepository {}
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}
class MockLoginUser extends Mock implements LoginUser {}
class MockRegisterUser extends Mock implements RegisterUser {}
class MockLogoutUser extends Mock implements LogoutUser {}
class MockGetCurrentUser extends Mock implements GetCurrentUser {}
class MockAuthBloc extends Mock implements AuthBloc {}

// Settings Feature Mocks
class MockThemeCubit extends Mock implements ThemeCubit {}
class MockLocaleCubit extends Mock implements LocaleCubit {}

void registerFallbackValues() {
  registerFallbackValue(const NoParams());
  registerFallbackValue(const LoginParams(email: '', password: ''));
  registerFallbackValue(const RegisterParams(email: '', password: ''));
  registerFallbackValue(UserModel(
    id: '',
    email: '',
    createdAt: DateTime(2024),
  ));
}
