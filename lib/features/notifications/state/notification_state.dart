import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile_samacite/features/notifications/models/notification_model.dart';

part 'notification_state.freezed.dart';

/// État pour la gestion des notifications
@freezed
class NotificationState with _$NotificationState {
  const factory NotificationState({
    @Default([]) List<NotificationModel> notifications,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(true) bool hasMore,
    @Default(0) int unreadCount,
    @Default(1) int currentPage,
    String? errorMessage,
  }) = _NotificationState;

  const NotificationState._();

  /// État initial
  factory NotificationState.initial() => const NotificationState();

  /// État de chargement
  NotificationState get toLoading => copyWith(isLoading: true, errorMessage: null);

  /// État de chargement de plus d'éléments
  NotificationState get toLoadingMore => copyWith(isLoadingMore: true, errorMessage: null);

  /// État de succès
  NotificationState toSuccess({
    required List<NotificationModel> notifications,
    required bool hasMore,
    required int currentPage,
  }) {
    return copyWith(
      notifications: notifications,
      hasMore: hasMore,
      currentPage: currentPage,
      isLoading: false,
      isLoadingMore: false,
      errorMessage: null,
    );
  }

  /// État d'erreur
  NotificationState toError(String message) {
    return copyWith(
      isLoading: false,
      isLoadingMore: false,
      errorMessage: message,
    );
  }

  /// Met à jour le compteur de non-lus
  NotificationState updateUnreadCount(int count) {
    return copyWith(unreadCount: count);
  }

  /// Marque une notification comme lue (mise à jour optimiste)
  NotificationState markNotificationAsRead(String notificationId) {
    final updatedNotifications = notifications.map((notif) {
      if (notif.id == notificationId && notif.isUnread) {
        return notif.copyWith(readAt: DateTime.now());
      }
      return notif;
    }).toList();

    return copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount > 0 ? unreadCount - 1 : 0,
    );
  }

  /// Supprime une notification (mise à jour optimiste)
  NotificationState removeNotification(String notificationId) {
    final notificationToRemove = notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => throw Exception('Notification not found'),
    );

    final updatedNotifications = notifications.where((n) => n.id != notificationId).toList();
    final newUnreadCount = notificationToRemove.isUnread ? unreadCount - 1 : unreadCount;

    return copyWith(
      notifications: updatedNotifications,
      unreadCount: newUnreadCount > 0 ? newUnreadCount : 0,
    );
  }
}
