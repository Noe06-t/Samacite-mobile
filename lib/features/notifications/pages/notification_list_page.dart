import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/features/notifications/models/notification_model.dart';
import 'package:mobile_samacite/features/notifications/state/notification_notifier.dart';
import 'package:mobile_samacite/features/notifications/widgets/notification_tile.dart';
import 'package:mobile_samacite/features/notifications/widgets/empty_notifications.dart';
import 'package:mobile_samacite/features/reports/pages/report_detail_page.dart';

/// Page d'affichage de la liste des notifications
class NotificationListPage extends ConsumerStatefulWidget {
  const NotificationListPage({super.key});

  @override
  ConsumerState<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends ConsumerState<NotificationListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Charger les notifications au démarrage
    Future.microtask(() => ref.read(notificationNotifierProvider.notifier).loadNotifications());

    // Écouter le scroll pour pagination infinie
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      // Charger plus quand on atteint 80% du scroll
      ref.read(notificationNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(notificationNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF007A3F), Color(0xFF00A854)],
            ),
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (state.notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  ref.read(notificationNotifierProvider.notifier).markAllAsRead();
                } else if (value == 'delete_all') {
                  _showDeleteAllDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, color: Color(0xFF007A3F)),
                      SizedBox(width: 8),
                      Text('Tout marquer comme lu'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Color(0xFFEA0707)),
                      SizedBox(width: 8),
                      Text('Tout supprimer'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(state) {
    // Chargement initial
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF007A3F),
        ),
      );
    }

    // Erreur
    if (state.errorMessage != null && state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFEA0707),
            ),
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              style: const TextStyle(color: Color(0xFFEA0707)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(notificationNotifierProvider.notifier).loadNotifications(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007A3F),
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    // Liste vide
    if (state.notifications.isEmpty) {
      return const EmptyNotifications();
    }

    // Liste des notifications
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF007A3F),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.notifications.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Indicateur de chargement en bas
          if (index == state.notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF007A3F),
                ),
              ),
            );
          }

          final notification = state.notifications[index];
          return NotificationTile(
            notification: notification,
            onTap: () => _onNotificationTap(notification.id),
            onDelete: () => _onNotificationDelete(notification.id),
            onMarkAsRead: () => _onNotificationMarkAsRead(notification.id),
          );
        },
      ),
    );
  }

  void _onNotificationTap(String notificationId) {
    final notification = ref.read(notificationNotifierProvider).notifications
        .firstWhere((n) => n.id == notificationId);

    // Marquer comme lu
    if (notification.isUnread) {
      ref.read(notificationNotifierProvider.notifier).markAsRead(notificationId);
    }

    // Navigation vers le signalement si report_id existe
    final reportId = notification.reportId;
    if (reportId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportDetailPage(reportId: reportId),
        ),
      );
    }
  }

  void _onNotificationDelete(String notificationId) {
    ref.read(notificationNotifierProvider.notifier).deleteNotification(notificationId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification supprimée'),
        backgroundColor: Color(0xFF007A3F),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onNotificationMarkAsRead(String notificationId) {
    ref.read(notificationNotifierProvider.notifier).markAsRead(notificationId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marqué comme lu'),
        backgroundColor: Color(0xFF007A3F),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer toutes les notifications'),
        content: const Text('Êtes-vous sûr de vouloir supprimer toutes les notifications ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(notificationNotifierProvider.notifier).deleteAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Toutes les notifications ont été supprimées'),
                  backgroundColor: Color(0xFF007A3F),
                ),
              );
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Color(0xFFEA0707)),
            ),
          ),
        ],
      ),
    );
  }
}
