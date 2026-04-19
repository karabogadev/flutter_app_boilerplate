import 'package:get_it/get_it.dart';

import 'config/routes/app_router.dart';
import 'core/cache/cache_manager.dart';
import 'core/cache/secure_cache_manager.dart';
import 'core/database/hive_manager.dart';
import 'core/localization/localization_manager.dart';
import 'core/network/dio_client.dart';
import 'core/offline/connectivity_cubit.dart';
import 'core/offline/connectivity_service.dart';
import 'core/offline/offline_manager.dart';
import 'core/offline/sync_queue.dart';
// Features
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/login_user.dart';
import 'features/auth/domain/usecases/logout_user.dart';
import 'features/auth/domain/usecases/register_user.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/settings/presentation/bloc/locale_cubit.dart';
import 'features/settings/presentation/bloc/theme_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  //==============================
  // CORE
  //==============================
  sl.registerLazySingleton<CacheManager>(() => CacheManager.instance);
  sl.registerLazySingleton<SecureCacheManager>(() => SecureCacheManager.instance);
  sl.registerLazySingleton<DioClient>(() => DioClient.instance);
  sl.registerLazySingleton<LocalizationManager>(() => LocalizationManager.instance);
  sl.registerLazySingleton<AppRouter>(() => AppRouter());

  //==============================
  // OFFLINE-FIRST
  //==============================
  await _initOfflineFirst();

  //==============================
  // FEATURES
  //==============================
  await _initAuthFeature();
  await _initSettingsFeature();
}

Future<void> _initOfflineFirst() async {
  sl.registerLazySingleton<HiveManager>(() => HiveManager.instance);
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService.instance);
  sl.registerLazySingleton<SyncQueue>(() => SyncQueue.instance);
  sl.registerLazySingleton<OfflineManager>(() => OfflineManager.instance);

  await sl<OfflineManager>().init();

  sl.registerFactory<ConnectivityCubit>(() => ConnectivityCubit(sl())..init());
}

Future<void> _initAuthFeature() async {
  // DataSources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      cacheManager: sl(),
      secureCacheManager: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        dioClient: sl(),
        syncQueue: sl(),
      ));

  // UseCases
  sl.registerLazySingleton<LoginUser>(() => LoginUser(sl()));
  sl.registerLazySingleton<RegisterUser>(() => RegisterUser(sl()));
  sl.registerLazySingleton<LogoutUser>(() => LogoutUser(sl()));
  sl.registerLazySingleton<GetCurrentUser>(() => GetCurrentUser(sl()));

  // BLoC
  sl.registerFactory<AuthBloc>(() => AuthBloc(
        loginUser: sl(),
        registerUser: sl(),
        logoutUser: sl(),
        getCurrentUser: sl(),
      ));

  // Wire token refresh into DioClient now that auth datasource is available.
  sl<DioClient>().configureTokenRefresh(
    getRefreshToken: () => sl<AuthLocalDataSource>().getRefreshToken(),
    saveTokens: (access, refresh) async {
      await sl<AuthLocalDataSource>().saveTokens(
        accessToken: access,
        refreshToken: refresh,
      );
      sl<DioClient>().setAuthToken(access);
    },
    onLogout: () async {
      await sl<AuthLocalDataSource>().clearAll();
      await sl<SyncQueue>().clearPending();
      sl<DioClient>().clearAuthToken();
    },
  );
}

Future<void> _initSettingsFeature() async {
  // LazySingleton: these hold app-wide persistent state.
  // registerFactory would create a fresh instance each time sl<ThemeCubit>()
  // is called, silently diverging from the BlocProvider-owned instance.
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(sl()));
  sl.registerLazySingleton<LocaleCubit>(() => LocaleCubit(sl()));
}
