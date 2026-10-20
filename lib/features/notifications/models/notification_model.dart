import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

/// Modèle représentant une notification Laravel Database
/// 
/// Structure backend Laravel notifications table:
/// ```sql
/// id, type, notifiable_type, notifiable_id, data (JSON), 
/// read_at (nullable), created_at, updated_at
/// ```
/// 
/// Exemple de réponse API:
/// ```json
/// {
///   "id": "550e8400-e29b-41d4-a716-446655440000",
///   "type": "App\\Notifications\\ReportCreatedNotification",
///   "data": {
///     "message": "Nouveau signalement créé",
///     "report_id": 5,
///     "report_title": "Route dégradée"
///   },
///   "read_at": null,
///   "created_at": "2025-11-25T10:30:00.000000Z"
/// }
/// ```
@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    /// ID unique de la notification (UUID Laravel)
    required String id,
    
    /// Type de notification (classe PHP complète)
    /// Ex: "App\\Notifications\\ReportCreatedNotification"
    required String type,
    
    /// Données JSON de la notification (contenu dynamique)
    /// Contient: message, report_id, user_id, etc.
    required Map<String, dynamic> data,
    
    /// Date de lecture (null si non lue)
    @JsonKey(name: 'read_at') DateTime? readAt,
    
    /// Date de création
    @JsonKey(name: 'created_at') required DateTime createdAt,
    
    /// Date de dernière mise à jour
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}

/// Extension pour faciliter l'utilisation
extension NotificationModelX on NotificationModel {
  /// Indique si la notification a été lue
  bool get isRead => readAt != null;
  
  /// Indique si la notification est non lue
  bool get isUnread => readAt == null;
  
  /// Retourne le titre de la notification depuis data
  String get title => data['title']?.toString() ?? 'Notification';
  
  /// Retourne le corps/message de la notification depuis data
  String get body => data['body']?.toString() ?? data['message']?.toString() ?? 'Nouvelle notification';
  
  /// Retourne le message complet (pour compatibilité)
  String get message => body;
  
  /// Retourne l'ID du signalement si présent
  int? get reportId {
    final reportIdValue = data['report_id'];
    if (reportIdValue == null) return null;
    if (reportIdValue is int) return reportIdValue;
    if (reportIdValue is String) return int.tryParse(reportIdValue);
    return null;
  }
  
  /// Retourne le titre du signalement si présent
  String? get reportTitle => data['report_title']?.toString();
  
  /// Retourne le type simplifié de notification
  /// Ex: "App\\Notifications\\ReportCreatedNotification" -> "ReportCreated"
  String get simpleType {
    final parts = type.split('\\');
    final className = parts.last;
    return className.replaceAll('Notification', '');
  }
  
  /// Retourne l'icône appropriée selon le type
  IconData get icon {
    if (type.contains('ReportCreated')) return Icons.location_on;
    if (type.contains('CommentCreated')) return Icons.chat_bubble;
    if (type.contains('StatusChanged')) return Icons.sync;
    return Icons.notifications;
  }
}
