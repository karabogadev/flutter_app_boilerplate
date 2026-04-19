import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter_app_boilerplate/core/offline/sync_operation.dart';
import 'package:flutter_app_boilerplate/core/offline/sync_status.dart';

// Pure logic tests for SyncQueue that don't require DI or Hive.
// These test the backoff logic and data structures.
// Full integration tests require resolving the DI singleton issue (Issue 1).
void main() {
  group('SyncOperation backoff logic', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = Directory.systemTemp.createTempSync('hive_test_');
      Hive.init(tempDir.path);

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(SyncOperationTypeAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(SyncStatusAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SyncOperationAdapter());
      }
    });

    tearDownAll(() async {
      await Hive.close();
      tempDir.deleteSync(recursive: true);
    });

    SyncOperation makeOp({
      int retryCount = 0,
      DateTime? lastAttemptAt,
      SyncStatus status = SyncStatus.pending,
    }) {
      return SyncOperation(
        id: 'test-id',
        operationType: SyncOperationType.create,
        entityType: 'test',
        entityId: '1',
        payload: '{}',
        endpoint: '/test',
        createdAt: DateTime.now(),
        retryCount: retryCount,
        status: status,
        lastAttemptAt: lastAttemptAt,
      );
    }

    group('markFailed()', () {
      late Box<SyncOperation> box;

      setUp(() async {
        box = await Hive.openBox<SyncOperation>('test_markfailed_${DateTime.now().millisecondsSinceEpoch}');
      });

      tearDown(() async {
        await box.clear();
        await box.close();
      });

      test('increments retryCount', () async {
        final op = makeOp();
        await box.add(op);
        op.markFailed('Network error');
        expect(op.retryCount, 1);
        expect(op.errorMessage, 'Network error');
      });

      test('stays pending below maxRetries', () async {
        final op = makeOp();
        await box.add(op);
        op.markFailed('Error');
        expect(op.status, SyncStatus.pending);
      });

      test('becomes failed at maxRetries', () async {
        final op = makeOp(retryCount: 2);
        await box.add(op);
        op.markFailed('Error'); // retryCount becomes 3 = maxRetries
        expect(op.status, SyncStatus.failed);
      });
    });

    group('isStale', () {
      test('returns false for recent operations', () {
        final op = SyncOperation.create(
          operationType: SyncOperationType.create,
          entityType: 'test',
          entityId: '1',
          data: {},
          endpoint: '/test',
        );
        expect(op.isStale, isFalse);
      });

      test('returns true for operations older than 7 days', () {
        final op = SyncOperation(
          id: 'old-op',
          operationType: SyncOperationType.create,
          entityType: 'test',
          entityId: '1',
          payload: '{}',
          endpoint: '/test',
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
        );
        expect(op.isStale, isTrue);
      });
    });

    group('payloadAsMap', () {
      test('decodes JSON payload', () {
        final op = SyncOperation.create(
          operationType: SyncOperationType.create,
          entityType: 'test',
          entityId: '1',
          data: {'key': 'value', 'count': 42},
          endpoint: '/test',
        );
        expect(op.payloadAsMap, {'key': 'value', 'count': 42});
      });

      test('returns empty map on corrupted payload', () {
        final op = SyncOperation(
          id: 'bad-op',
          operationType: SyncOperationType.update,
          entityType: 'test',
          entityId: '1',
          payload: 'NOT_JSON',
          endpoint: '/test',
          createdAt: DateTime.now(),
        );
        expect(op.payloadAsMap, isEmpty);
      });
    });

    group('SyncOperation.create()', () {
      test('generates a unique UUID id', () {
        final op1 = SyncOperation.create(
          operationType: SyncOperationType.create,
          entityType: 'test',
          entityId: '1',
          data: {},
          endpoint: '/test',
        );
        final op2 = SyncOperation.create(
          operationType: SyncOperationType.create,
          entityType: 'test',
          entityId: '2',
          data: {},
          endpoint: '/test',
        );
        expect(op1.id, isNot(equals(op2.id)));
        expect(op1.id, isNotEmpty);
      });

      test('sets status to pending by default', () {
        final op = SyncOperation.create(
          operationType: SyncOperationType.delete,
          entityType: 'test',
          entityId: '1',
          data: {},
          endpoint: '/test',
        );
        expect(op.status, SyncStatus.pending);
        expect(op.retryCount, 0);
      });
    });
  });
}
