import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_provider.dart';

/// A bottom-sheet that displays the user's notifications.
///
/// Call [NotificationPanel.show] from any widget that has access to a
/// [BuildContext].
class NotificationPanel extends ConsumerStatefulWidget {
  const NotificationPanel({super.key});

  /// Convenience method to open the panel as a modal bottom-sheet.
  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => NotificationPanel._(controller: controller),
      ),
    );
  }

  /// Internal named constructor used by the DraggableScrollableSheet.
  const NotificationPanel._({
    super.key,
    required this.controller,
  });

  final ScrollController? controller;

  @override
  ConsumerState<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends ConsumerState<NotificationPanel> {
  @override
  void initState() {
    super.initState();
    // Load notifications when the panel opens.
    Future.microtask(
        () => ref.read(notificationProvider.notifier).fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Handle ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // ── Header ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Text(
                'Notifications',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              if (state.unreadCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              if (state.unreadCount > 0)
                TextButton(
                  onPressed: () =>
                      ref.read(notificationProvider.notifier).markAllAsRead(),
                  child: const Text('Mark all read'),
                ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Body ──────────────────────────────────────────────────
        Expanded(child: _buildBody(state, theme)),
      ],
    );
  }

  Widget _buildBody(NotificationState state, ThemeData theme) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref
                    .read(notificationProvider.notifier)
                    .fetchNotifications(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No notifications yet',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: widget.controller,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: state.notifications.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final n = state.notifications[index];
        return _NotificationTile(
          notification: n,
          onTap: () {
            if (!n.isRead) {
              ref.read(notificationProvider.notifier).markAsRead(n.id);
            }
          },
          onDismiss: () =>
              ref.read(notificationProvider.notifier).dismiss(n.id),
        );
      },
    );
  }
}

// ── Single notification tile ──────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAgo = _formatTimeAgo(notification.createdAt);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error.withOpacity(0.15),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notification.isRead
              ? Colors.transparent
              : AppColors.info.withOpacity(0.06),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _typeIcon(notification.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: notification.isRead
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      createdAgo,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 8),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeIcon(String type) {
    final IconData icon;
    final Color color;
    switch (type) {
      case 'SERVICE_REQUEST':
        icon = Icons.build_outlined;
        color = AppColors.info;
        break;
      case 'INVENTORY_ALERT':
        icon = Icons.inventory_2_outlined;
        color = AppColors.warning;
        break;
      case 'VEHICLE_REMINDER':
        icon = Icons.directions_car_outlined;
        color = AppColors.accent;
        break;
      case 'MACHINE_BREAKDOWN':
        icon = Icons.warning_amber_outlined;
        color = AppColors.error;
        break;
      default:
        icon = Icons.notifications_outlined;
        color = AppColors.primary;
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
