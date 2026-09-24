import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'offline_manager.dart';
import 'sync_status.dart';

/// State for connectivity cubit
class ConnectivityState extends Equatable {
  final ConnectivityStatus status;
  final int pendingOperations;
  final bool isSyncing;
  final String? lastError;
  final DateTime? lastSyncTime;

  const ConnectivityState({
    required this.status,
    this.pendingOperations = 0,
    this.isSyncing = false,
    this.lastError,
    this.lastSyncTime,
  });

  factory ConnectivityState.initial() =>
      const ConnectivityState(status: ConnectivityStatus.online);

  bool get isOnline => status == ConnectivityStatus.online;
  bool get isOffline => status == ConnectivityStatus.offline;
  bool get hasPendingOperations => pendingOperations > 0;

  ConnectivityState copyWith({
    ConnectivityStatus? status,
    int? pendingOperations,
    bool? isSyncing,
    String? lastError,
    DateTime? lastSyncTime,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      isSyncing: isSyncing ?? this.isSyncing,
      lastError: lastError ?? this.lastError,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  @override
  List<Object?> get props => [
    status,
    pendingOperations,
    isSyncing,
    lastError,
    lastSyncTime,
  ];
}

/// Cubit for managing connectivity state in the UI.
///
/// Usage:
/// ```dart
/// BlocProvider<ConnectivityCubit>(
///   create: (_) => ConnectivityCubit(offlineManager)..init(),
/// ),
///
/// // In widget:
/// BlocBuilder<ConnectivityCubit, ConnectivityState>(
///   builder: (context, state) {
///     if (state.isOffline) {
///       return OfflineBanner();
///     }
///     return child;
///   },
/// )
/// ```
class ConnectivityCubit extends Cubit<ConnectivityState> {
  final OfflineManager _offlineManager;
  StreamSubscription<OfflineStatus>? _subscription;

  ConnectivityCubit(this._offlineManager) : super(ConnectivityState.initial());

  /// Initialize and start listening to connectivity changes
  void init() {
    // Set initial state
    _updateFromOfflineStatus(_offlineManager.currentStatus);

    // Listen to changes
    _subscription = _offlineManager.onStatusChanged.listen(
      _updateFromOfflineStatus,
    );
  }

  void _updateFromOfflineStatus(OfflineStatus status) {
    emit(
      state.copyWith(
        status: status.connectivity,
        pendingOperations: status.pendingCount,
        isSyncing: status.isSyncing,
      ),
    );
  }

  /// Manually trigger a sync
  Future<void> sync() async {
    if (state.isOffline) {
      emit(state.copyWith(lastError: 'Cannot sync while offline'));
      return;
    }

    emit(state.copyWith(isSyncing: true, lastError: null));

    try {
      final result = await _offlineManager.processQueue();

      emit(
        state.copyWith(
          isSyncing: false,
          pendingOperations: _offlineManager.pendingCount,
          lastSyncTime: DateTime.now(),
          lastError: result.hasFailures ? result.message : null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSyncing: false, lastError: e.toString()));
    }
  }

  /// Retry failed operations
  Future<void> retryFailed() async {
    await _offlineManager.retryFailed();
  }

  /// Clear completed operations
  Future<void> clearCompleted() async {
    await _offlineManager.clearCompleted();
  }

  /// Clear failed operations
  Future<void> clearFailed() async {
    await _offlineManager.clearFailed();
  }

  /// Toggle auto-sync
  void setAutoSync(bool enabled) {
    _offlineManager.autoSyncEnabled = enabled;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
