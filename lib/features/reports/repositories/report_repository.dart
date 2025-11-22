import 'package:dio/dio.dart';
import 'package:mobile_samacite/core/models/report_model.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/core/constants/api_constants.dart';

/// Repository pour la gestion des signalements (Reports)
/// 
/// Suit le pattern Repository du backend Laravel
/// Utilise Dio pour toutes les requêtes API (spec.md)
class ReportRepository {
  final DioService _dioService;

  ReportRepository(this._dioService);

  /// Crée un nouveau signalement
  /// 
  /// [reportData] doit contenir:
  /// - title: String
  /// - description: String
  /// - category_id: int
  /// - latitude: double (optionnel)
  /// - longitude: double (optionnel)
  /// - address: String (optionnel)
  /// 
  /// Retourne le ReportModel créé
  /// Lance DioException en cas d'erreur
  Future<ReportModel> create(Map<String, dynamic> reportData) async {
    try {
      final response = await _dioService.dio.post(
        ApiConstants.reports,
        data: reportData,
      );

      // Backend Laravel renvoie : { success, message, data: {...} }
      if (response.data['success'] == true) {
        return ReportModel.fromJson(response.data['data']);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          message: response.data['message'] ?? 'Erreur lors de la création',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: ApiConstants.reports),
        message: 'Erreur inattendue: $e',
      );
    }
  }

  /// Upload des images pour un signalement existant
  /// 
  /// [reportId] : ID du signalement
  /// [imagePaths] : Liste des chemins locaux des images (max 5)
  /// 
  /// Retourne la liste des URLs des images uploadées
  /// Lance DioException si > 5 images ou erreur réseau
  /// 
  /// IMPORTANT : Le backend Laravel attend le champ 'image' (singulier)
  /// donc on envoie chaque image dans une requête séparée
  Future<List<String>> uploadImages(int reportId, List<String> imagePaths) async {
    // Validation : max 5 images (spec.md - Mobile Flutter)
    if (imagePaths.length > 5) {
      throw DioException(
        requestOptions: RequestOptions(path: '${ApiConstants.reports}/$reportId/images'),
        message: 'Maximum 5 images autorisées',
      );
    }

    if (imagePaths.isEmpty) {
      return [];
    }

    try {
      final uploadedUrls = <String>[];
      
      // Upload chaque image individuellement car le backend attend 'image' (singulier)
      for (var i = 0; i < imagePaths.length; i++) {
        final formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(
            imagePaths[i],
            filename: 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          ),
        });

        final response = await _dioService.dio.post(
          '${ApiConstants.reports}/$reportId/images',
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
            headers: {
              'Accept': 'application/json',
            },
          ),
        );

        if (response.data['success'] == true) {
          // Backend renvoie : { success, data: { image: 'url' } } ou { images: ['url'] }
          final data = response.data['data'];
          
          // Gérer les deux formats possibles de réponse
          if (data is Map && data.containsKey('image')) {
            uploadedUrls.add(data['image'].toString());
          } else if (data is Map && data.containsKey('images')) {
            final images = data['images'] as List;
            uploadedUrls.addAll(images.map((url) => url.toString()));
          } else {
            // Fallback : prendre toute la data comme URL
            uploadedUrls.add(data.toString());
          }
        } else {
          throw DioException(
            requestOptions: response.requestOptions,
            message: response.data['message'] ?? 'Erreur upload image ${i + 1}',
          );
        }
      }

      return uploadedUrls;
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: '${ApiConstants.reports}/$reportId/images'),
        message: 'Erreur upload: $e',
      );
    }
  }

  /// Récupère la liste paginée des signalements
  /// 
  /// [page] : Numéro de page (défaut: 1)
  /// [perPage] : Nombre d'éléments par page (défaut: 15)
  /// [status] : Filtre par statut ('pending', 'in_progress', 'resolved')
  /// [includeRelations] : Relations à charger (user, category, images)
  /// 
  /// Retourne une Map avec :
  /// - 'data': List<ReportModel>
  /// - 'meta': { current_page, last_page, total, per_page }
  Future<Map<String, dynamic>> getReports({
    int page = 1,
    int perPage = 15,
    String? status,
    List<String>? includeRelations,
  }) async {
    try {
      // Construction des query params
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      // Eager-loading pour éviter N+1 (spec.md - Backend Repository Pattern)
      if (includeRelations != null && includeRelations.isNotEmpty) {
        queryParams['include'] = includeRelations.join(',');
      }

      final response = await _dioService.dio.get(
        ApiConstants.reports,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        // Parser la liste de reports
        final reportsJson = response.data['data']['data'] as List;
        final reports = reportsJson
            .map((json) => ReportModel.fromJson(json))
            .toList();

        return {
          'data': reports,
          'meta': response.data['data']['meta'] ?? {},
        };
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          message: response.data['message'] ?? 'Erreur récupération',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: ApiConstants.reports),
        message: 'Erreur inattendue: $e',
      );
    }
  }

  /// Récupère un signalement par son ID avec relations
  /// 
  /// [id] : ID du signalement
  /// [includeRelations] : Relations à charger (user, category, location, images)
  /// 
  /// Retourne le ReportModel ou lance DioException si non trouvé
  Future<ReportModel> getReportById(
    int id, {
    List<String>? includeRelations,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (includeRelations != null && includeRelations.isNotEmpty) {
        queryParams['include'] = includeRelations.join(',');
      }

      final response = await _dioService.dio.get(
        '${ApiConstants.reports}/$id',
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        return ReportModel.fromJson(response.data['data']);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          message: response.data['message'] ?? 'Signalement non trouvé',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: '${ApiConstants.reports}/$id'),
        message: 'Erreur inattendue: $e',
      );
    }
  }

  /// Met à jour le statut d'un signalement (admin uniquement)
  /// 
  /// [id] : ID du signalement
  /// [status] : Nouveau statut ('pending', 'in_progress', 'resolved')
  /// 
  /// Retourne le ReportModel mis à jour
  Future<ReportModel> updateStatus(int id, String status) async {
    try {
      final response = await _dioService.dio.patch(
        '${ApiConstants.reports}/$id/status',
        data: {'status': status},
      );

      if (response.data['success'] == true) {
        return ReportModel.fromJson(response.data['data']);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          message: response.data['message'] ?? 'Erreur mise à jour',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: '${ApiConstants.reports}/$id/status'),
        message: 'Erreur inattendue: $e',
      );
    }
  }

  /// Supprime un signalement (créateur uniquement)
  /// 
  /// [id] : ID du signalement à supprimer
  /// 
  /// Lance DioException en cas d'erreur ou si non autorisé
  Future<void> delete(int id) async {
    try {
      final response = await _dioService.dio.delete(
        '${ApiConstants.reports}/$id',
      );

      if (response.data['success'] != true) {
        throw DioException(
          requestOptions: response.requestOptions,
          message: response.data['message'] ?? 'Erreur suppression',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: '${ApiConstants.reports}/$id'),
        message: 'Erreur inattendue: $e',
      );
    }
  }
}
