import 'package:flutter/material.dart';
import 'package:mobile_samacite/features/reports/pages/report_detail_page.dart';

/// Handler pour gérer la navigation depuis les notifications push
/// 
/// Parse les données de notification et navigue vers la page appropriée
/// 
/// Structure attendue des data Firebase:
/// ```json
/// {
///   "type": "new_report" | "new_comment" | "status_changed",
///   "report_id": "123",
///   "title": "Titre du signalement",
///   "category_id": "5"  // Optionnel
/// }
/// ```
class NotificationNavigationHandler {
  /// Naviguer vers la page appropriée selon le type de notification
  /// 
  /// [context] : BuildContext pour la navigation
  /// [data] : Map de données de la notification Firebase
  static void handleNotificationTap(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    print('[NotificationNav] 📱 Traitement notification: $data');

    try {
      final String? type = data['type'] as String?;
      final String? reportIdStr = data['report_id'] as String?;

      if (type == null || reportIdStr == null) {
        print('[NotificationNav] ⚠️ Données incomplètes');
        return;
      }

      final int reportId = int.parse(reportIdStr);

      switch (type) {
        case 'new_report':
          _navigateToReportDetail(context, reportId, 'Nouveau signalement');
          break;

        case 'new_comment':
          _navigateToReportDetail(context, reportId, 'Nouveau commentaire');
          break;

        case 'status_changed':
          _navigateToReportDetail(context, reportId, 'Statut mis à jour');
          break;

        default:
          print('[NotificationNav] ⚠️ Type inconnu: $type');
          _navigateToReportDetail(context, reportId, 'Notification');
      }
    } catch (e) {
      print('[NotificationNav] ❌ Erreur parsing: $e');
    }
  }

  /// Naviguer vers la page détail d'un signalement
  static void _navigateToReportDetail(
    BuildContext context,
    int reportId,
    String source,
  ) {
    print('[NotificationNav] ➡️ Navigation vers signalement $reportId ($source)');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReportDetailPage(reportId: reportId),
      ),
    );
  }

  /// Afficher un SnackBar si la navigation échoue
  static void showNavigationError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impossible d\'ouvrir cette notification'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
