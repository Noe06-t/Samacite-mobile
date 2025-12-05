import 'package:mobile_samacite/core/services/dio_service.dart';

/// Repository pour la gestion des likes sur les signalements
/// 
/// Gère les opérations CRUD pour les likes:
/// - Liker/Unliker un signalement
/// - Vérifier si un signalement est liké
/// - Obtenir le nombre de likes
class LikeRepository {
  final DioService _dioService;

  LikeRepository(this._dioService);

  /// Like un signalement
  /// 
  /// POST /api/reports/{reportId}/likes
  /// 
  /// Retourne le nouveau nombre de likes
  Future<int> likeReport(int reportId) async {
    try {
      final response = await _dioService.dio.post(
        '/reports/$reportId/likes',
      );

      if (response.data['success'] == true) {
        // Récupérer le signalement complet pour obtenir likes_count
        final reportResponse = await _dioService.dio.get(
          '/reports/$reportId',
          queryParameters: {'include': 'user,category,images'},
        );
        
        final reportData = reportResponse.data['data'];
        return (reportData['likes_count'] as int?) ?? 0;
      } else {
        throw Exception(response.data['message'] ?? 'Erreur lors du like');
      }
    } catch (e) {
      throw Exception('Erreur lors du like: $e');
    }
  }

  /// Unlike un signalement
  /// 
  /// DELETE /api/reports/{reportId}/likes
  /// 
  /// Retourne le nouveau nombre de likes
  Future<int> unlikeReport(int reportId) async {
    try {
      final response = await _dioService.dio.delete(
        '/reports/$reportId/likes',
      );

      if (response.data['success'] == true) {
        // Récupérer le signalement complet pour obtenir likes_count
        final reportResponse = await _dioService.dio.get(
          '/reports/$reportId',
          queryParameters: {'include': 'user,category,images'},
        );
        
        final reportData = reportResponse.data['data'];
        return (reportData['likes_count'] as int?) ?? 0;
      } else {
        throw Exception(response.data['message'] ?? 'Erreur lors du unlike');
      }
    } catch (e) {
      throw Exception('Erreur lors du unlike: $e');
    }
  }

  /// Toggle like (like si pas liké, unlike si déjà liké)
  /// 
  /// Retourne le nouveau nombre de likes et le nouvel état
  Future<Map<String, dynamic>> toggleLike(int reportId, bool currentlyLiked) async {
    try {
      final newLikesCount = currentlyLiked 
          ? await unlikeReport(reportId)
          : await likeReport(reportId);

      return {
        'likes_count': newLikesCount,
        'is_liked': !currentlyLiked,
      };
    } catch (e) {
      rethrow;
    }
  }
}
