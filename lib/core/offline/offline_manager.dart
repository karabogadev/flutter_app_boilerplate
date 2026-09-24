import 'dart:async';

import '../database/hive_manager.dart';
import '../logging/app_logger.dart';
import 'connectivity_service.dart';
import 'sync_queue.dart';
import 'sync_status.dart';

/// Orchestrates offline-first behavior by coordinating connectivity
/// monitoring and sync queue processing.
class OfflineManager {
  OfflineManager(this._hiveManager, this._connectivityService, this._syncQueue);

  final HiveManager _hiveManager;
  final ConnectivityService _connectivityService;
  final SyncQueue _syncQueue;

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  StreamSubscription<int>? _queueSubscription;
  final _statusController = StreamController<OfflineStatus>.broadcast();

  bool _isInitialized = false;

  /// Stream of offline status changes
  Stream<OfflineStatus> get onStatusChanged => _statusController.stream;

  /// Current offline status
  OfflineStatus get currentStatus => OfflineStatus(
        connectivity: _connectivityService.currentStatus,
        pendingCount: _syncQueue.pendingCount,
        isSyncing: _syncQueue.isProcessing,
      );

  /// Whether auto-sync is enabled. Set this directly to enable/disable auto-sync.
  bool autoSyncEnabled = true;

  /// Quick check if online
  bool get isOnline => _connectivityService.isOnline;

  /// Quick check if offline
  bool get isOffline => _connectivityService.isOffline;

  /// Initialize the offline manager
  Future<void> init() async {
    if (_isInitialized) return;

    await _hiveManager.init();
    _connectivityService.init();

    // Reset any operations left in-progress from a previous session.
    await _syncQueue.recoverInProgressOperations();

    _connectivitySubscription = _connectivityService.onStatusChanged.listen(
      _handleConnectivityChange,
    );
    _queueSubscription = _syncQueue.onQueueChanged.listen((_) => _emitStatus());

    _isInitialized = true;
    _emitStatus();

    AppLogger.debug('initialized', name: 'offline');
  }

  /// Handle connectivity status changes
  Future<void> _handleConnectivityChange(ConnectivityStatus status) async {
    if (status == ConnectivityStatus.online && autoSyncEnabled) {
      // Device came back online - process queue
      await processQueue();
    }

    _emitStatus();
  }

  /// Queue an operation for sync
  Future<void> queueOperation({
    required SyncOperationType operationType,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
    required String endpoint,
  }) async {
    await _syncQueue.addOperation(
      operationType: operationType,
      entityType: entityType,
      entityId: entityId,
      data: data,
      endpoint: endpoint,
    );

    _emitStatus();
  }

  /// Process the sync queue
  Future<SyncResult> processQueue() async {
    if (!_connectivityService.isOnline) {
      return const SyncResult(
        processed: 0,
        succeeded: 0,
        failed: 0,
        message: 'Cannot sync while offline',
      );
    }

    if (_syncQueue.pendingCount == 0) {
      return const SyncResult(
        processed: 0,
        succeeded: 0,
        failed: 0,
        message: 'No pending operations',
      );
    }

    _connectivityService.setSyncing();
    _emitStatus();

    try {
      final result = await _syncQueue.processQueue();
      return result;
    } finally {
      _connectivityService.setSyncComplete();
      _emitStatus();
    }
  }

  /// Force a sync even if offline (will likely fail but useful for testing)
  Future<SyncResult> forceSync() async {
    _connectivityService.setSyncing();
    _emitStatus();

    try {
      final result = await _syncQueue.processQueue();
      return result;
    } finally {
      _connectivityService.setSyncComplete();
      _emitStatus();
    }
  }

  /// Clear all synced data and queue
  Future<void> clearAll() async {
    await _hiveManager.clearAll();
    _emitStatus();
  }

  /// Get count of pending operations
  int get pendingCount => _syncQueue.pendingCount;

  /// Clear completed operations from queue
  Future<void> clearCompleted() async {
    await _syncQueue.clearCompleted();
    _emitStatus();
  }

  /// Clear failed operations from queue
  Future<void> clearFailed() async {
    await _syncQueue.clearFailed();
    _emitStatus();
  }

  /// Retry all failed operations
  Future<void> retryFailed() async {
    await _syncQueue.retryAllFailed();
    if (autoSyncEnabled && _connectivityService.isOnline) {
      await processQueue();
    }
  }

  void _emitStatus() {
    _statusController.add(currentStatus);
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _queueSubscription?.cancel();
    await _statusController.close();
    _connectivityService.dispose();
    _syncQueue.dispose();
  }
}

/// Represents the current offline status
class OfflineStatus {
  final ConnectivityStatus connectivity;
  final int pendingCount;
  final bool isSyncing;

  const OfflineStatus({
    required this.connectivity,
    required this.pendingCount,
    required this.isSyncing,
  });

  bool get isOnline => connectivity == ConnectivityStatus.online;
  bool get isOffline => connectivity == ConnectivityStatus.offline;
  bool get hasPendingOperations => pendingCount > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineStatus &&
          runtimeType == other.runtimeType &&
          connectivity == other.connectivity &&
          pendingCount == other.pendingCount &&
          isSyncing == other.isSyncing;

  @override
  int get hashCode =>
      connectivity.hashCode ^ pendingCount.hashCode ^ isSyncing.hashCode;

  @override
  String toString() =>
      'OfflineStatus(connectivity: $connectivity, pending: $pendingCount, syncing: $isSyncing)';
}
