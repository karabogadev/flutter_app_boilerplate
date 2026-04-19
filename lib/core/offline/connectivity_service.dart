import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'sync_status.dart';

/// Service for monitoring network connectivity status.
///
/// Uses connectivity_plus to detect network type changes and
/// performs actual connectivity checks to verify internet access.
class ConnectivityService {
  ConnectivityService();

  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _statusController = StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus _currentStatus = ConnectivityStatus.online;
  List<ConnectivityResult> _lastResults = [];

  bool _isInitialized = false;

  /// Current connectivity status
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Whether the device is currently online
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Whether the device is currently offline
  bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get onStatusChanged => _statusController.stream;

  /// Last known connectivity results (wifi, mobile, etc.)
  List<ConnectivityResult> get lastResults => _lastResults;

  /// Initialize the connectivity service
  Future<void> init() async {
    if (_isInitialized) return;

    // Get initial status
    _lastResults = await _connectivity.checkConnectivity();
    await _updateStatus(_lastResults);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );

    _isInitialized = true;

    if (kDebugMode) {
      print('ConnectivityService: Initialized with status $_currentStatus');
    }
  }

  /// Handle connectivity changes from the platform
  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    _lastResults = results;
    await _updateStatus(results);
  }

  /// Update the connectivity status based on results
  Future<void> _updateStatus(List<ConnectivityResult> results) async {
    final hasNetwork = results.any(
      (r) => r != ConnectivityResult.none,
    );

    if (!hasNetwork) {
      _setStatus(ConnectivityStatus.offline);
      return;
    }

    // Verify actual internet connectivity
    final hasInternet = await _checkInternetAccess();
    _setStatus(hasInternet ? ConnectivityStatus.online : ConnectivityStatus.offline);
  }

  /// Check if there's actual internet access by pinging a reliable host
  Future<bool> _checkInternetAccess() async {
    try {
      // Try to resolve a reliable domain
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Set the status and emit to stream
  void _setStatus(ConnectivityStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);

      if (kDebugMode) {
        print('ConnectivityService: Status changed to $status');
      }
    }
  }

  /// Set status to syncing (called by SyncQueue)
  void setSyncing() {
    _setStatus(ConnectivityStatus.syncing);
  }

  /// Set status back to online after syncing
  void setSyncComplete() {
    if (_currentStatus == ConnectivityStatus.syncing) {
      _setStatus(ConnectivityStatus.online);
    }
  }

  /// Manually trigger a connectivity check
  Future<void> checkConnectivity() async {
    _lastResults = await _connectivity.checkConnectivity();
    await _updateStatus(_lastResults);
  }

  /// Get a human-readable description of the connection type
  String getConnectionTypeDescription() {
    if (_lastResults.isEmpty || _lastResults.contains(ConnectivityResult.none)) {
      return 'No connection';
    }

    final types = _lastResults.map((r) {
      switch (r) {
        case ConnectivityResult.wifi:
          return 'WiFi';
        case ConnectivityResult.mobile:
          return 'Mobile';
        case ConnectivityResult.ethernet:
          return 'Ethernet';
        case ConnectivityResult.vpn:
          return 'VPN';
        case ConnectivityResult.bluetooth:
          return 'Bluetooth';
        case ConnectivityResult.other:
          return 'Other';
        case ConnectivityResult.none:
          return 'None';
        case ConnectivityResult.satellite:
          return 'Satellite';
      }
    }).toSet();

    return types.join(', ');
  }

  /// Dispose the service
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
