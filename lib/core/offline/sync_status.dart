import 'package:hive_ce/hive.dart';

part 'sync_status.g.dart';

/// Type of sync operation to be performed
@HiveType(typeId: 0)
enum SyncOperationType {
  @HiveField(0)
  create,

  @HiveField(1)
  update,

  @HiveField(2)
  delete,
}

/// Current status of a sync operation
@HiveType(typeId: 1)
enum SyncStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  inProgress,

  @HiveField(2)
  completed,

  @HiveField(3)
  failed,
}

/// Overall connectivity status of the app
enum ConnectivityStatus { online, offline, syncing }

extension SyncOperationTypeX on SyncOperationType {
  String get displayName {
    switch (this) {
      case SyncOperationType.create:
        return 'Create';
      case SyncOperationType.update:
        return 'Update';
      case SyncOperationType.delete:
        return 'Delete';
    }
  }

  String get httpMethod {
    switch (this) {
      case SyncOperationType.create:
        return 'POST';
      case SyncOperationType.update:
        return 'PUT';
      case SyncOperationType.delete:
        return 'DELETE';
    }
  }
}

extension SyncStatusX on SyncStatus {
  bool get isPending => this == SyncStatus.pending;
  bool get isInProgress => this == SyncStatus.inProgress;
  bool get isCompleted => this == SyncStatus.completed;
  bool get isFailed => this == SyncStatus.failed;
}

extension ConnectivityStatusX on ConnectivityStatus {
  bool get isOnline => this == ConnectivityStatus.online;
  bool get isOffline => this == ConnectivityStatus.offline;
  bool get isSyncing => this == ConnectivityStatus.syncing;
}
