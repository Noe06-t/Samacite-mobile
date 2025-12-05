import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/core/services/notification_service.dart';
import 'package:mobile_samacite/features/notifications/repositories/notification_repository.dart';
import 'package:mobile_samacite/features/notifications/state/notification_state.dart';

/// Provider pour le repository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dioService = ref.watch(dioServiceProvider);
  return NotificationRepository(dioService);
});

/// Provider pour le notifier de notifications
final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository);
});

/// Notifier pour gérer l'état des notifications
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;
  static const int _perPage = 20;
  StreamSubscription<int>? _unreadCountSubscription;

  NotificationNotifier(this._repository) : super(NotificationState.initial()) {
    // Écouter les changements du compteur de notifications
    _unreadCountSubscription = NotificationService().unreadCountStream.listen((count) {
      state = state.updateUnreadCount(count);
      print('[NotificationNotifier] 🔔 Compteur mis à jour via stream: $count');
    });
  }

  @override
  void dispose() {
    _unreadCountSubscription?.cancel();
    super.dispose();
  }

  /// Charge les notifications (première page)
  Future<void> loadNotifications() async {
    print('[NotificationNotifier] 🔄 Chargement des notifications...');
    state = state.toLoading;

    try {
      print('[NotificationNotifier] 📥 Appel repository.getNotifications()...');
      final notifications = await _repository.getNotifications(page: 1, perPage: _perPage);
      print('[NotificationNotifier] ✅ ${notifications.length} notifications reçues');
      
      print('[NotificationNotifier] 📊 Récupération du compteur...');
      final unreadCount = await _repository.getUnreadCount();
      print('[NotificationNotifier] ✅ Compteur: $unreadCount');

      state = state.toSuccess(
        notifications: notifications,
        hasMore: notifications.length >= _perPage,
        currentPage: 1,
      ).updateUnreadCount(unreadCount);
      
      print('[NotificationNotifier] ✅ État mis à jour avec succès');
    } catch (e, stack) {
      print('[NotificationNotifier] ❌ ERREUR: $e');
      print('[NotificationNotifier] 📍 Stack: $stack');
      state = state.toError('Erreur lors du chargement des notifications: $e');
    }
  }

  /// Charge plus de notifications (pagination)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.toLoadingMore;

    try {
      final nextPage = state.currentPage + 1;
      final moreNotifications = await _repository.getNotifications(
        page: nextPage,
        perPage: _perPage,
      );

      final allNotifications = [...state.notifications, ...moreNotifications];

      state = state.toSuccess(
        notifications: allNotifications,
        hasMore: moreNotifications.length >= _perPage,
        currentPage: nextPage,
      ).copyWith(unreadCount: state.unreadCount);
    } catch (e) {
      state = state.toError('Erreur lors du chargement de plus de notifications');
    }
  }

  /// Rafraîchit les notifications (pull-to-refresh)
  Future<void> refresh() async {
    try {
      final notifications = await _repository.getNotifications(page: 1, perPage: _perPage);
      final unreadCount = await _repository.getUnreadCount();

      state = state.toSuccess(
        notifications: notifications,
        hasMore: notifications.length >= _perPage,
        currentPage: 1,
      ).updateUnreadCount(unreadCount);
    } catch (e) {
      state = state.toError('Erreur lors du rafraîchissement');
    }
  }

  /// Marque une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    // Mise à jour optimiste
    state = state.markNotificationAsRead(notificationId);

    try {
      await _repository.markAsRead(notificationId);
      // Mettre à jour le compteur
      final unreadCount = await _repository.getUnreadCount();
      state = state.updateUnreadCount(unreadCount);
    } catch (e) {
      // Rollback en cas d'erreur (recharger)
      await loadNotifications();
      state = state.toError('Erreur lors du marquage comme lu');
    }
  }

  /// Marque toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      await loadNotifications();
    } catch (e) {
      state = state.toError('Erreur lors du marquage de toutes les notifications');
    }
  }

  /// Supprime une notification
  Future<void> deleteNotification(String notificationId) async {
    // Mise à jour optimiste
    final previousState = state;
    state = state.removeNotification(notificationId);

    try {
      await _repository.deleteNotification(notificationId);
    } catch (e) {
      // Rollback
      state = previousState.toError('Erreur lors de la suppression');
    }
  }

  /// Supprime toutes les notifications
  Future<void> deleteAll() async {
    try {
      await _repository.deleteAllNotifications();
      state = NotificationState.initial();
    } catch (e) {
      state = state.toError('Erreur lors de la suppression de toutes les notifications');
    }
  }

  /// Met à jour le compteur de notifications non lues
  Future<void> updateUnreadCount() async {
    try {
      final count = await _repository.getUnreadCount();
      state = state.updateUnreadCount(count);
    } catch (e) {
      // Silencieux - ne pas afficher d'erreur pour le compteur
    }
  }
}
