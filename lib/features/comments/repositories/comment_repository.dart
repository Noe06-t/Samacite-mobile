import 'package:dio/dio.dart';
import 'package:mobile_samacite/core/models/comment_model.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/core/constants/api_constants.dart';

/// Repository pour gérer les commentaires sur les signalements
/// 
/// Endpoints API:
/// - GET /api/reports/{reportId}/comments - Liste commentaires avec pagination
/// - POST /api/reports/{reportId}/comments - Créer un commentaire
/// - DELETE /api/comments/{commentId} - Supprimer son propre commentaire
class CommentRepository {
  final DioService _dioService;

  CommentRepository(this._dioService);

  /// Récupère la liste des commentaires d'un signalement
  /// 
  /// [reportId] : ID du signalement
  /// [page] : Numéro de page (pagination)
  /// [perPage] : Nombre de commentaires par page
  /// 
  /// Retourne une Map contenant:
  /// - 'data': List<CommentModel>
  /// - 'current_page': int
  /// - 'last_page': int
  /// - 'total': int
  Future<Map<String, dynamic>> getComments(
    int reportId, {
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await _dioService.dio.get(
        '${ApiConstants.reports}/$reportId/comments',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'include': 'user', // Eager load user relation
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        
        // Si data est une liste directement (pas de pagination)
        if (data is List) {
          final comments = data
              .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
              .toList();
          
          return {
            'data': comments,
            'current_page': 1,
            'last_page': 1,
            'total': comments.length,
          };
        }
        
        // Si data contient la structure de pagination
        if (data is Map<String, dynamic>) {
          final commentsJson = data['data'] as List;
          final comments = commentsJson
              .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
              .toList();

          return {
            'data': comments,
            'current_page': data['current_page'] ?? 1,
            'last_page': data['last_page'] ?? 1,
            'total': data['total'] ?? 0,
          };
        }
        
        // Fallback si structure inconnue
        return {
          'data': <CommentModel>[],
          'current_page': 1,
          'last_page': 1,
          'total': 0,
        };
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          message: response.data['message'] ?? 'Erreur lors de la récupération des commentaires',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(
          path: '${ApiConstants.reports}/$reportId/comments',
        ),
        message: 'Erreur inattendue: $e',
      );
    }
  }

  /// Crée un nouveau commentaire sur un signalement
  /// 
  /// [reportId] : ID du signalement
  /// [content] : Contenu du commentaire (1-500 caractères)
  /// 
  /// Retourne le CommentModel créé avec l'utilisateur
  Future<CommentModel> createComment(int reportId, String content) async {
    // Validation locale
    if (content.trim().isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(
          path: '${ApiConstants.reports}/$reportId/comments',
        ),
        message: 'Le commentaire ne peut pas être vide',
      );
    }

    if (content.length > 500) {
      throw DioException(
        requestOptions: RequestOptions(
          path: '${ApiConstants.reports}/$reportId/comments',
        ),
        message: 'Le commentaire ne peut pas dépasser 500 caractères',
      );
    }

    try {
      final response = await _dioService.dio.post(
        '${ApiConstants.reports}/$reportId/comments',
        data: {
          'content': content.trim(),
        },
        queryParameters: {
          'include': 'user', // Inclure l'utilisateur dans la réponse
        },
      );

      if (response.data['success'] == true) {
        final commentData = response.data['data'] as Map<String, dynamic>;
        
        // Si le backend ne retourne pas 'user', ajouter un objet user vide pour éviter le crash
        final mutableData = Map<String, dynamic>.from(commentData);
        if (!mutableData.containsKey('user') || mutableData['user'] == null) {
          // Ajouter un user minimal avec juste l'ID (convertir en int si nécessaire)
          final userId = mutableData['user_id'];
          mutableData['user'] = {
            'id': userId is String ? int.parse(userId) : userId,
            'name': null,
            'email': null,
          };
        }
        
        return CommentModel.fromJson(mutableData);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          message: response.data['message'] ?? 'Erreur lors de la création du commentaire',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(
          path: '${ApiConstants.reports}/$reportId/comments',
        ),
        message: 'Erreur inattendue: $e',
      );
    }
  }

  /// Supprime un commentaire (uniquement si l'utilisateur en est l'auteur)
  /// 
  /// [commentId] : ID du commentaire à supprimer
  /// 
  /// Le backend vérifie que l'utilisateur connecté est bien l'auteur
  Future<void> deleteComment(int commentId) async {
    try {
      final response = await _dioService.dio.delete(
        '/comments/$commentId',
      );

      if (response.data['success'] != true) {
        throw DioException(
          requestOptions: response.requestOptions,
          message: response.data['message'] ?? 'Erreur lors de la suppression du commentaire',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(
          path: '/api/comments/$commentId',
        ),
        message: 'Erreur inattendue: $e',
      );
    }
  }
}
