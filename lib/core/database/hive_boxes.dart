/// Constants for Hive box names used throughout the application.
/// Centralizing box names prevents typos and makes refactoring easier.
abstract class HiveBoxes {
  /// Box for storing pending sync operations
  static const String syncQueue = 'sync_queue';

  /// Box for storing sync metadata per entity
  static const String syncMetadata = 'sync_metadata';

  /// Boxes opened at startup by `HiveManager`. Add feature boxes here only if
  /// they must be cleared by `HiveManager.clearAll`.
  static const List<String> allBoxes = [syncQueue, syncMetadata];
}

/// Type IDs for Hive TypeAdapters.
/// Keep these unique across the entire application.
abstract class HiveTypeIds {
  // Sync related (0-9)
  static const int syncOperationType = 0;
  static const int syncStatus = 1;
  static const int syncOperation = 2;
  static const int syncMetadata = 3;

  // Entities: 10-99. Cache: 100-199.
}
