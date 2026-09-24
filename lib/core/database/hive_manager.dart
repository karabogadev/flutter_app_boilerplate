import 'package:hive_ce_flutter/hive_flutter.dart';

import '../logging/app_logger.dart';
import '../offline/sync_operation.dart';
import '../offline/sync_status.dart';
import 'hive_boxes.dart';

/// Manages Hive database initialization and provides access to boxes.
///
/// Register this via GetIt and call [init] during app startup.
class HiveManager {
  HiveManager();

  bool _isInitialized = false;

  /// Check if Hive has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize Hive and register all TypeAdapters.
  /// Must be called before using any Hive boxes.
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize Hive for Flutter
    await Hive.initFlutter();

    // Register TypeAdapters
    _registerAdapters();

    // Open required boxes
    await _openBoxes();

    _isInitialized = true;

    AppLogger.debug('initialized', name: 'hive');
  }

  /// Register all TypeAdapters for custom objects
  void _registerAdapters() {
    // Sync related adapters
    if (!Hive.isAdapterRegistered(HiveTypeIds.syncOperationType)) {
      Hive.registerAdapter(SyncOperationTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.syncStatus)) {
      Hive.registerAdapter(SyncStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.syncOperation)) {
      Hive.registerAdapter(SyncOperationAdapter());
    }

    // Add more adapters here as needed
    // Example:
    // if (!Hive.isAdapterRegistered(HiveTypeIds.user)) {
    //   Hive.registerAdapter(UserAdapter());
    // }
  }

  /// Opens the boxes the sync queue needs at startup. Feature boxes should
  /// be opened on demand with [openBox] / [openLazyBox].
  Future<void> _openBoxes() async {
    await Future.wait([Hive.openBox<SyncOperation>(HiveBoxes.syncQueue)]);
  }

  // ─────────────────────────────────────────────────────────────
  // BOX ACCESSORS
  // ─────────────────────────────────────────────────────────────

  /// Get the sync queue box for pending operations
  Box<SyncOperation> getSyncQueueBox() {
    _ensureInitialized();
    return Hive.box<SyncOperation>(HiveBoxes.syncQueue);
  }

  /// Open a typed box on demand
  Future<Box<T>> openBox<T>(String name) async {
    _ensureInitialized();
    if (Hive.isBoxOpen(name)) {
      return Hive.box<T>(name);
    }
    return Hive.openBox<T>(name);
  }

  /// Open a lazy box for large datasets
  Future<LazyBox<T>> openLazyBox<T>(String name) async {
    _ensureInitialized();
    if (Hive.isBoxOpen(name)) {
      return Hive.lazyBox<T>(name);
    }
    return Hive.openLazyBox<T>(name);
  }

  // ─────────────────────────────────────────────────────────────
  // UTILITY METHODS
  // ─────────────────────────────────────────────────────────────

  /// Clear all data from the core boxes
  Future<void> clearAll() async {
    _ensureInitialized();
    for (final boxName in HiveBoxes.allBoxes) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box<dynamic>(boxName).clear();
      }
    }

    AppLogger.debug('all boxes cleared', name: 'hive');
  }

  /// Clear a specific box
  Future<void> clearBox(String boxName) async {
    _ensureInitialized();
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box<dynamic>(boxName).clear();
    }
  }

  /// Close all boxes (useful for cleanup)
  Future<void> closeAll() async {
    await Hive.close();
    _isInitialized = false;

    AppLogger.debug('all boxes closed', name: 'hive');
  }

  /// Delete a box from disk completely
  Future<void> deleteBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box<dynamic>(boxName).deleteFromDisk();
    } else {
      await Hive.deleteBoxFromDisk(boxName);
    }
  }

  /// Compact a box to reduce file size
  Future<void> compactBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box<dynamic>(boxName).compact();
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('HiveManager is not initialized. Call init() first.');
    }
  }
}
