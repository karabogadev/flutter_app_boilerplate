import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app_boilerplate/core/offline/connectivity_cubit.dart';
import 'package:flutter_app_boilerplate/core/offline/offline_manager.dart';
import 'package:flutter_app_boilerplate/core/offline/sync_queue.dart';
import 'package:flutter_app_boilerplate/core/offline/sync_status.dart';

import '../../mocks/mocks.dart';

void main() {
  late MockOfflineManager mockOfflineManager;
  late StreamController<OfflineStatus> offlineStatusController;

  setUp(() {
    mockOfflineManager = MockOfflineManager();
    offlineStatusController = StreamController<OfflineStatus>.broadcast();

    when(() => mockOfflineManager.onStatusChanged)
        .thenAnswer((_) => offlineStatusController.stream);
    when(() => mockOfflineManager.currentStatus).thenReturn(
      const OfflineStatus(
        connectivity: ConnectivityStatus.online,
        pendingCount: 0,
        isSyncing: false,
      ),
    );
  });

  tearDown(() {
    offlineStatusController.close();
  });

  ConnectivityCubit buildCubit() =>
      ConnectivityCubit(mockOfflineManager)..init();

  group('ConnectivityCubit', () {
    test('initial state is online', () {
      final cubit = buildCubit();
      expect(cubit.state.isOnline, isTrue);
      expect(cubit.state.pendingOperations, 0);
      cubit.close();
    });

    blocTest<ConnectivityCubit, ConnectivityState>(
      'reflects offline status when OfflineManager emits offline',
      build: buildCubit,
      act: (cubit) {
        offlineStatusController.add(const OfflineStatus(
          connectivity: ConnectivityStatus.offline,
          pendingCount: 3,
          isSyncing: false,
        ));
      },
      expect: () => [
        isA<ConnectivityState>()
            .having((s) => s.isOffline, 'isOffline', isTrue)
            .having((s) => s.pendingOperations, 'pendingOperations', 3),
      ],
    );

    blocTest<ConnectivityCubit, ConnectivityState>(
      'sync() emits error when offline',
      build: buildCubit,
      seed: () => const ConnectivityState(
        status: ConnectivityStatus.offline,
        pendingOperations: 2,
      ),
      act: (cubit) => cubit.sync(),
      expect: () => [
        isA<ConnectivityState>()
            .having((s) => s.lastError, 'lastError', isNotNull),
      ],
    );

    blocTest<ConnectivityCubit, ConnectivityState>(
      'sync() while online processes queue and updates lastSyncTime',
      build: buildCubit,
      setUp: () {
        when(() => mockOfflineManager.processQueue()).thenAnswer((_) async =>
            const SyncResult(
              processed: 2,
              succeeded: 2,
              failed: 0,
              message: 'Done',
            ));
        when(() => mockOfflineManager.pendingCount).thenReturn(0);
      },
      act: (cubit) => cubit.sync(),
      expect: () => [
        isA<ConnectivityState>().having((s) => s.isSyncing, 'isSyncing', true),
        isA<ConnectivityState>()
            .having((s) => s.isSyncing, 'isSyncing', false)
            .having((s) => s.lastSyncTime, 'lastSyncTime', isNotNull),
      ],
    );
  });
}
