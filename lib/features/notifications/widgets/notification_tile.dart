import 'package:flutter/material.dart';
import 'package:mobile_samacite/features/notifications/models/notification_model.dart';

/// Widget pour afficher une notification individuelle
class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onMarkAsRead;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      background: _buildSwipeBackground(
        color: const Color(0xFF007A3F),
        icon: Icons.done,
        text: 'Marquer comme lu',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        color: const Color(0xFFEA0707),
        icon: Icons.delete,
        text: 'Supprimer',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe vers la droite = Marquer comme lu
          if (notification.isUnread) {
            onMarkAsRead();
          }
          return false; // Ne pas supprimer le widget
        } else {
          // Swipe vers la gauche = Supprimer
          return await _showDeleteConfirmation(context);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
      },
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: notification.isUnread ? const Color(0xFFF5F5F5) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône basée sur le type
                _buildIcon(),
                const SizedBox(width: 12),

                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type de notification
                      Text(
                        _getNotificationTypeLabel(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getTypeColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Message
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: notification.isUnread ? FontWeight.w600 : FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),

                      // Titre du signalement si disponible
                      if (notification.reportTitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          notification.reportTitle!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 6),

                      // Date
                      Text(
                        _formatDate(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Indicateur non lu
                if (notification.isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFA000),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getTypeColor().withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          notification.icon,
          size: 20,
          color: _getTypeColor(),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required String text,
    required Alignment alignment,
  }) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getNotificationTypeLabel() {
    final type = notification.simpleType;
    switch (type) {
      case 'ReportCreatedNotification':
        return 'NOUVEAU SIGNALEMENT';
      case 'CommentCreatedNotification':
        return 'NOUVEAU COMMENTAIRE';
      case 'StatusChangedNotification':
        return 'CHANGEMENT DE STATUT';
      default:
        return 'NOTIFICATION';
    }
  }

  Color _getTypeColor() {
    final type = notification.simpleType;
    switch (type) {
      case 'ReportCreatedNotification':
        return const Color(0xFF007A3F);
      case 'CommentCreatedNotification':
        return const Color(0xFFFFA000);
      case 'StatusChangedNotification':
        return const Color(0xFF0023D1);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute';
    }
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer la notification'),
            content: const Text('Voulez-vous vraiment supprimer cette notification ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Color(0xFFEA0707)),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
