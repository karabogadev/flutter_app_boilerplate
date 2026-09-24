import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/routes/app_router.dart';
import 'config/routes/auth_guard.dart';
import 'core/cache/cache_manager.dart';
import 'core/cache/secure_cache_manager.dart';
import 'core/database/hive_manager.dart';
import 'core/network/dio_client.dart';
import 'core/offline/connectivity_service.dart';
import 'core/offline/offline_manager.dart';
import 'core/offline/sync_queue.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/settings/data/repositories/settings_repository.dart';

/// Service locator. Only the composition root (`main.dart` and this file)
/// resolves from it; everything else receives dependencies through its
/// constructor or, in widgets, from `RepositoryProvider`/`BlocProvider`.
final sl = GetIt.instance;

/// Registers services and repositories, then runs the async initialization
/// that must finish before the first frame.
///
/// Blocs and cubits are not registered here: they are created by
/// `BlocProvider`s in the widget tree, which also owns their lifecycle.
Future<void> initDependencies() async {
  sl
    // Core
    ..registerLazySingleton<CacheManager>(() => CacheManager(sl()))
    ..registerLazySingleton<SecureCacheManager>(SecureCacheManager.new)
    ..registerLazySingleton<DioClient>(DioClient.new)
    // Offline-first
    ..registerLazySingleton<HiveManager>(HiveManager.new)
    ..registerLazySingleton<ConnectivityService>(ConnectivityService.new)
    ..registerLazySingleton<SyncQueue>(() => SyncQueue(sl(), sl()))
    ..registerLazySingleton<OfflineManager>(
      () => OfflineManager(sl(), sl(), sl()),
    )
    // Auth
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(dioClient: sl()),
    )
    ..registerLazySingleton<AuthLocalDataSource>(
      () =>
          AuthLocalDataSourceImpl(cacheManager: sl(), secureCacheManager: sl()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        dioClient: sl(),
        syncQueue: sl(),
      ),
    )
    // Settings
    ..registerLazySingleton<SettingsRepository>(() => SettingsRepository(sl()))
    // Routing
    ..registerLazySingleton<AuthGuard>(() => AuthGuard(sl()))
    ..registerLazySingleton<AppRouter>(() => AppRouter(sl()));

  sl<DioClient>().configureTokenRefresh(
    getRefreshToken: () => sl<AuthLocalDataSource>().getRefreshToken(),
    saveTokens: (accessToken, refreshToken) => sl<AuthLocalDataSource>()
        .saveTokens(accessToken: accessToken, refreshToken: refreshToken),
    onSessionExpired: () => sl<AuthRepository>().expireSession(),
  );

  // Disk I/O that the first frame depends on, run in parallel. The network
  // connectivity check is not awaited (see ConnectivityService.init).
  final (prefs, _) = await (
    SharedPreferences.getInstance(),
    sl<OfflineManager>().init(),
  ).wait;
  sl.registerSingleton<SharedPreferences>(prefs);
}
