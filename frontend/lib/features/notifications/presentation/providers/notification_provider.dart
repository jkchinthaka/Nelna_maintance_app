import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/notification_entity.dart';

// ── State ─────────────────────────────────────────────────────────────

class NotificationState {
  final List<NotificationEntity> notifications;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<NotificationEntity>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────

class NotificationNotifier extends Notifier<NotificationState> {
  late final ApiClient _api;

  @override
  NotificationState build() {
    _api = ApiClient();
    return const NotificationState();
  }

  /// Fetch all notifications for the current user from the API.
  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.dio.get('/notifications');
      final list = (response.data['data'] as List?)
              ?.map(
                  (e) => NotificationEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      state = state.copyWith(notifications: list, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message']?.toString() ??
            'Failed to load notifications',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(int notificationId) async {
    try {
      await _api.dio.patch('/notifications/$notificationId/read');
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(isRead: true, readAt: DateTime.now());
          }
          return n;
        }).toList(),
      );
    } catch (_) {
      // Silently fail – the badge still reflects server state on next fetch.
    }
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    try {
      await _api.dio.patch('/notifications/read-all');
      state = state.copyWith(
        notifications: state.notifications
            .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
            .toList(),
      );
    } catch (_) {
      // Silently fail.
    }
  }

  /// Remove a notification from the local list (optimistic).
  void dismiss(int notificationId) {
    state = state.copyWith(
      notifications:
          state.notifications.where((n) => n.id != notificationId).toList(),
    );
  }
}

// ── Providers ─────────────────────────────────────────────────────────

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);
