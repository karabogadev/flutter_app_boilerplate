import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../offline/connectivity_cubit.dart';

/// A banner that shows when the device is offline.
///
/// Usage:
/// ```dart
/// Scaffold(
///   body: Column(
///     children: [
///       const OfflineBanner(),
///       Expanded(child: content),
///     ],
///   ),
/// )
/// ```
class OfflineBanner extends StatelessWidget {
  final bool showPendingCount;
  final VoidCallback? onTap;

  const OfflineBanner({super.key, this.showPendingCount = true, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        if (state.isOnline && !state.isSyncing) {
          return const SizedBox.shrink();
        }

        return MaterialBanner(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          content: Row(
            children: [
              _buildIcon(state),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getMessage(state),
                      style: TextStyle(
                        color: _getTextColor(context, state),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (showPendingCount && state.hasPendingOperations)
                      Text(
                        '${state.pendingOperations} pending operations',
                        style: TextStyle(
                          color: _getTextColor(
                            context,
                            state,
                          ).withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: _getBackgroundColor(context, state),
          actions: [
            if (state.isOffline)
              TextButton(
                onPressed: onTap,
                child: Text(
                  'Dismiss',
                  style: TextStyle(color: _getTextColor(context, state)),
                ),
              ),
            if (state.isSyncing)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildIcon(ConnectivityState state) {
    if (state.isSyncing) {
      return const SyncingIcon();
    }

    return Icon(
      state.isOffline ? Icons.cloud_off : Icons.cloud_done,
      color: Colors.white,
    );
  }

  String _getMessage(ConnectivityState state) {
    if (state.isSyncing) {
      return 'Syncing...';
    }
    if (state.isOffline) {
      return 'You are offline';
    }
    return 'Connected';
  }

  Color _getBackgroundColor(BuildContext context, ConnectivityState state) {
    if (state.isSyncing) {
      return Colors.blue.shade600;
    }
    if (state.isOffline) {
      return Colors.grey.shade700;
    }
    return Colors.green.shade600;
  }

  Color _getTextColor(BuildContext context, ConnectivityState state) {
    return Colors.white;
  }
}

/// Animated syncing icon
class SyncingIcon extends StatefulWidget {
  final Color color;
  final double size;

  const SyncingIcon({super.key, this.color = Colors.white, this.size = 24});

  @override
  State<SyncingIcon> createState() => _SyncingIconState();
}

class _SyncingIconState extends State<SyncingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(Icons.sync, color: widget.color, size: widget.size),
    );
  }
}

/// Small indicator dot for status bar or app bar
class OfflineIndicatorDot extends StatelessWidget {
  final double size;

  const OfflineIndicatorDot({super.key, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        Color color;

        if (state.isSyncing) {
          color = Colors.blue;
        } else if (state.isOffline) {
          color = Colors.red;
        } else if (state.hasPendingOperations) {
          color = Colors.orange;
        } else {
          color = Colors.green;
        }

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
      },
    );
  }
}

/// Widget that shows offline status in the app bar
class OfflineAppBarIndicator extends StatelessWidget {
  const OfflineAppBarIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        if (state.isOnline && !state.isSyncing && !state.hasPendingOperations) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.isSyncing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (state.isOffline)
                const Icon(Icons.cloud_off, size: 20)
              else if (state.hasPendingOperations)
                Badge(
                  label: Text('${state.pendingOperations}'),
                  child: const Icon(Icons.sync, size: 20),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Wrapper widget that disables child when offline
class OfflineAwareButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool disableWhenOffline;
  final String? offlineMessage;

  const OfflineAwareButton({
    super.key,
    required this.child,
    this.onPressed,
    this.disableWhenOffline = true,
    this.offlineMessage,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        final isDisabled = disableWhenOffline && state.isOffline;

        return GestureDetector(
          onTap: isDisabled
              ? () {
                  if (offlineMessage != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(offlineMessage!)));
                  }
                }
              : onPressed,
          child: Opacity(opacity: isDisabled ? 0.5 : 1.0, child: child),
        );
      },
    );
  }
}

/// Listener that shows snackbars on connectivity changes
class ConnectivityListener extends StatelessWidget {
  final Widget child;
  final bool showOnlineMessage;
  final bool showOfflineMessage;

  const ConnectivityListener({
    super.key,
    required this.child,
    this.showOnlineMessage = true,
    this.showOfflineMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityCubit, ConnectivityState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.isSyncing != current.isSyncing,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);

        if (state.isSyncing) {
          messenger.showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Syncing...'),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
          );
        } else if (state.isOffline && showOfflineMessage) {
          messenger.showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.cloud_off, color: Colors.white),
                  SizedBox(width: 12),
                  Text('You are offline'),
                ],
              ),
              backgroundColor: Colors.grey.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state.isOnline && showOnlineMessage) {
          messenger.showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.cloud_done, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Back online'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: child,
    );
  }
}
