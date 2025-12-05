import 'dart:convert';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/features/notifications/models/notification_model.dart';

/// Repository pour gérer les notifications (approche Laravel Database)
class NotificationRepository {
  final DioService _dioService;

  NotificationRepository(this._dioService);

  /// Récupère la liste des notifications
  /// GET /api/notifications
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      print('[NotificationRepository] 📥 Récupération des notifications...');
      final response = await _dioService.dio.get(
        '/notifications',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      print('[NotificationRepository] ✅ Réponse reçue');
      print('[NotificationRepository] 🔍 Type response.data: ${response.data.runtimeType}');
      
      // Gérer 2 formats: {success, data: []} OU directement []
      final List data;
      if (response.data is List) {
        data = response.data as List;
      } else if (response.data is Map) {
        final map = response.data as Map<String, dynamic>;
        if (map.containsKey('data') && map['data'] is Map && (map['data'] as Map).containsKey('data')) {
          // Pagination Laravel: data.data
          data = map['data']['data'] as List;
        } else if (map.containsKey('data') && map['data'] is List) {
          // Simple: {success, data: []}
          data = map['data'] as List;
        } else {
          throw Exception('Format de réponse inattendu');
        }
      } else {
        throw Exception('Format de réponse invalide');
      }
      print('[NotificationRepository] 📊 Nombre de notifications: ${data.length}');
      
      // Parser chaque notification avec gestion d'erreurs
      final notifications = <NotificationModel>[];
      for (var i = 0; i < data.length; i++) {
        try {
          var json = data[i] as Map<String, dynamic>;
          print('[NotificationRepository] 🔄 Parsing notification $i: ${json['id']}');
          print('[NotificationRepository] 🔍 Data keys: ${json.keys}');
          print('[NotificationRepository] 🔍 Data.data type: ${json['data'].runtimeType}');
          print('[NotificationRepository] 🔍 Data.data value: ${json['data']}');
          
          // FIX: Gestion du double-encodage Laravel
          var dataField = json['data'];
          if (dataField is String) {
            print('[NotificationRepository] ⚠️ Double-encodage JSON détecté !');
            try {
              dataField = jsonDecode(dataField) as Map<String, dynamic>;
              json = Map<String, dynamic>.from(json);
              json['data'] = dataField;
              print('[NotificationRepository] ✅ Double-encodage corrigé');
            } catch (e) {
              print('[NotificationRepository] ❌ Erreur décodage: $e');
              json['data'] = {'title': 'Notification', 'body': 'Erreur contenu'};
            }
          }
          
          final notification = NotificationModel.fromJson(json);
          notifications.add(notification);
          print('[NotificationRepository] ✅ Notification $i parsée');
        } catch (e, stack) {
          print('[NotificationRepository] ❌ Erreur parsing notification $i: $e');
          print('[NotificationRepository] 📍 Stack: $stack');
        }
      }
      
      print('[NotificationRepository] ✅ Total parsé: ${notifications.length}');
      return notifications;
    } catch (e, stack) {
      print('[NotificationRepository] ❌ Erreur globale: $e');
      print('[NotificationRepository] 📍 Stack: $stack');
      rethrow;
    }
  }

  /// Récupère le nombre de notifications non lues
  /// GET /api/notifications/unread-count
  Future<int> getUnreadCount() async {
    try {
      final response = await _dioService.dio.get('/notifications/unread-count');
      return response.data['data']['unread_count'] as int;
    } catch (e) {
      rethrow;
    }
  }

  /// Marque une notification comme lue
  /// PATCH /api/notifications/{id}/read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _dioService.dio.patch('/notifications/$notificationId/read');
    } catch (e) {
      rethrow;
    }
  }

  /// Marque toutes les notifications comme lues
  /// PATCH /api/notifications/mark-all-read
  Future<void> markAllAsRead() async {
    try {
      await _dioService.dio.patch('/notifications/mark-all-read');
    } catch (e) {
      rethrow;
    }
  }

  /// Supprime une notification
  /// DELETE /api/notifications/{id}
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _dioService.dio.delete('/notifications/$notificationId');
    } catch (e) {
      rethrow;
    }
  }

  /// Supprime toutes les notifications
  /// DELETE /api/notifications
  Future<void> deleteAllNotifications() async {
    try {
      await _dioService.dio.delete('/notifications');
    } catch (e) {
      rethrow;
    }
  }
}
