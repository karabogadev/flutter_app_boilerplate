import 'package:auto_route/auto_route.dart';
import 'package:flutter_app_boilerplate/core/cache/cache_manager.dart';
import 'package:flutter_app_boilerplate/core/cache/secure_cache_manager.dart';
import 'package:flutter_app_boilerplate/core/database/hive_manager.dart';
import 'package:flutter_app_boilerplate/core/network/dio_client.dart';
import 'package:flutter_app_boilerplate/core/offline/connectivity_service.dart';
import 'package:flutter_app_boilerplate/core/offline/offline_manager.dart';
import 'package:flutter_app_boilerplate/core/offline/sync_queue.dart';
import 'package:flutter_app_boilerplate/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter_app_boilerplate/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_app_boilerplate/features/auth/data/models/user_model.dart';
import 'package:mocktail/mocktail.dart';

// Mocks are for collaborators at the edge of the system (storage, network,
// router). For repositories prefer the fakes in `test/fakes/`.

// Core
class MockCacheManager extends Mock implements CacheManager {}

class MockSecureCacheManager extends Mock implements SecureCacheManager {}

class MockDioClient extends Mock implements DioClient {}

// Offline-first
class MockHiveManager extends Mock implements HiveManager {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncQueue extends Mock implements SyncQueue {}

class MockOfflineManager extends Mock implements OfflineManager {}

// Auth data sources
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

// Routing
class MockNavigationResolver extends Mock implements NavigationResolver {}

class MockStackRouter extends Mock implements StackRouter {}

class FakePageRouteInfo extends Fake implements PageRouteInfo<dynamic> {}

void registerFallbackValues() {
  registerFallbackValue(
    UserModel(id: '', email: '', createdAt: DateTime(2024)),
  );
  registerFallbackValue(FakePageRouteInfo());
}
