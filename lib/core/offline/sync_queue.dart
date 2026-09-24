import 'dart:async';

import 'package:hive_ce/hive.dart';

import '../database/hive_manager.dart';
import '../error/exceptions.dart';
import '../logging/app_logger.dart';
import '../network/dio_client.dart';
import 'sync_operation.dart';
import 'sync_status.dart';

class SyncQueue {
  SyncQueue(this._hiveManager, this._dioClient);

  final DioClient _dioClient;
  final HiveManager _hiveManager;

  bool _isProcessing = false;
  final _onQueueChanged = StreamController<int>.broadcast();

  Stream<int> get onQueueChanged => _onQueueChanged.stream;
  bool get isProcessing => _isProcessing;

  Box<SyncOperation> get _box => _hiveManager.getSyncQueueBox();

  // ─────────────────────────────────────────────────────────────
  // INITIALIZATION
  // ─────────────────────────────────────────────────────────────

  /// Recover any operations left in-progress from a previous app session
  /// (e.g., force-kill mid-sync). Resets them to pending so they retry.
  Future<void> recoverInProgressOperations() async {
    final stuckOps = _box.values
        .where((op) => op.status == SyncStatus.inProgress)
        .toList();

    for (final op in stuckOps) {
      op.status = SyncStatus.pending;
      await op.save();
    }

    if (stuckOps.isNotEmpty) {
      AppLogger.debug(
        'recovered ${stuckOps.length} stuck in-progress ops',
        name: 'sync',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // QUERIES
  // ─────────────────────────────────────────────────────────────

  List<SyncOperation> get pendingOperations {
    final now = DateTime.now();
    return _box.values
        .where((op) =>
            op.status == SyncStatus.pending && _isReadyForRetry(op, now))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  int get pendingCount =>
      _box.values.where((op) => op.status == SyncStatus.pending).length;

  List<SyncOperation> get allOperations =>
      _box.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  /// Exponential backoff: 2^retryCount seconds (2s, 4s, 8s).
  bool _isReadyForRetry(SyncOperation op, DateTime now) {
    if (op.retryCount == 0 || op.lastAttemptAt == null) return true;
    final backoff = Duration(seconds: 1 << op.retryCount);
    return now.isAfter(op.lastAttemptAt!.add(backoff));
  }

  // ─────────────────────────────────────────────────────────────
  // MUTATIONS
  // ─────────────────────────────────────────────────────────────

  Future<SyncOperation> addOperation({
    required SyncOperationType operationType,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> data,
    required String endpoint,
  }) async {
    final operation = SyncOperation.create(
      operationType: operationType,
      entityType: entityType,
      entityId: entityId,
      data: data,
      endpoint: endpoint,
    );

    await _box.put(operation.id, operation);
    _notifyQueueChanged();

    AppLogger.debug('Added ${operation.id} (${operation.operationType})', name: 'sync');

    return operation;
  }

  Future<void> removeOperation(String id) async {
    await _box.delete(id);
    _notifyQueueChanged();
  }

  Future<void> clearCompleted() async {
    final keys = _box.values
        .where((op) => op.status == SyncStatus.completed)
        .map((op) => op.id)
        .toList();
    await _box.deleteAll(keys);
    AppLogger.debug('Cleared ${keys.length} completed ops', name: 'sync');
  }

  Future<void> clearFailed() async {
    final keys = _box.values
        .where((op) => op.status == SyncStatus.failed)
        .map((op) => op.id)
        .toList();
    await _box.deleteAll(keys);
    AppLogger.debug('Cleared ${keys.length} failed ops', name: 'sync');
  }

  Future<void> clearPending() async {
    final keys = _box.values
        .where((op) => op.status == SyncStatus.pending)
        .map((op) => op.id)
        .toList();
    await _box.deleteAll(keys);
    _notifyQueueChanged();
    AppLogger.debug('Cleared ${keys.length} pending ops', name: 'sync');
  }

  Future<void> clearStale() async {
    final keys = _box.values
        .where((op) => op.isStale)
        .map((op) => op.id)
        .toList();
    await _box.deleteAll(keys);
    AppLogger.debug('Cleared ${keys.length} stale ops', name: 'sync');
  }

  // ─────────────────────────────────────────────────────────────
  // PROCESSING
  // ─────────────────────────────────────────────────────────────

  Future<SyncResult> processQueue() async {
    if (_isProcessing) {
      return const SyncResult(
        processed: 0,
        succeeded: 0,
        failed: 0,
        message: 'Queue is already being processed',
      );
    }

    _isProcessing = true;
    int processed = 0;
    int succeeded = 0;
    int failed = 0;

    try {
      final operations = pendingOperations;

      AppLogger.debug('Processing ${operations.length} operations', name: 'sync');

      for (final operation in operations) {
        processed++;
        if (await _processOperation(operation)) {
          succeeded++;
        } else {
          failed++;
        }
        // Do not notify after every operation — emit once at the end.
      }

      _notifyQueueChanged();

      return SyncResult(
        processed: processed,
        succeeded: succeeded,
        failed: failed,
        message:
            'Processed $processed: $succeeded succeeded, $failed failed',
      );
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> _processOperation(SyncOperation operation) async {
    operation.markInProgress();

    try {
      final response = switch (operation.operationType) {
        SyncOperationType.create => await _dioClient.post<dynamic>(
            operation.endpoint,
            data: operation.payloadAsMap,
          ),
        SyncOperationType.update => await _dioClient.put<dynamic>(
            operation.endpoint,
            data: operation.payloadAsMap,
          ),
        SyncOperationType.delete => await _dioClient.delete<dynamic>(
            operation.endpoint,
          ),
      };

      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        operation.markCompleted();
        return true;
      }

      operation.markFailed('Server returned $statusCode');
      return false;
    } on NetworkException catch (e) {
      operation.markFailed(e.message);
      return false;
    } on ServerException catch (e) {
      operation.markFailed(e.message);
      return false;
    } catch (e) {
      operation.markFailed(e.toString());
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // RETRY
  // ─────────────────────────────────────────────────────────────

  Future<bool> retryOperation(String id) async {
    final operation = _box.get(id);
    if (operation == null || operation.status != SyncStatus.failed) {
      return false;
    }

    operation.status = SyncStatus.pending;
    operation.retryCount = 0;
    operation.errorMessage = null;
    await operation.save();

    _notifyQueueChanged();
    return true;
  }

  Future<void> retryAllFailed() async {
    final failed =
        _box.values.where((op) => op.status == SyncStatus.failed).toList();

    for (final op in failed) {
      op.status = SyncStatus.pending;
      op.retryCount = 0;
      op.errorMessage = null;
      await op.save();
    }

    _notifyQueueChanged();
  }

  // ─────────────────────────────────────────────────────────────
  // INTERNALS
  // ─────────────────────────────────────────────────────────────

  void _notifyQueueChanged() {
    _onQueueChanged.add(pendingCount);
  }

  void dispose() {
    _onQueueChanged.close();
  }
}

class SyncResult {
  final int processed;
  final int succeeded;
  final int failed;
  final String message;

  const SyncResult({
    required this.processed,
    required this.succeeded,
    required this.failed,
    required this.message,
  });

  bool get hasFailures => failed > 0;
  bool get allSucceeded => processed > 0 && failed == 0;

  @override
  String toString() => message;
}
