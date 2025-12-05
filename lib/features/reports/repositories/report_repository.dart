import 'package:dio/dio.dart';
import 'package:mobile_samacite/core/models/report_model.dart';
import 'package:hive/hive.dart';
import 'package:mobile_samacite/core/models/report_model_hive.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/core/constants/api_constants.dart';

/// Repository pour la gestion des signalements (Reports)
/// 
/// Suit le pattern Repository du backend Laravel
/// Utilise Dio pour toutes les requêtes API (spec.md)
class ReportRepository {
    // Nom des box Hive
    static const String _reportsBoxName = 'reports_box';
    static const String _reportCacheMetaKey = 'reports_meta';
    static const Duration _ttl = Duration(seconds: 60); // TTL 60s (spec.md)

    // Helper pour ouvrir la box Hive
    Future<Box> _openReportsBox() async {
      if (!Hive.isBoxOpen(_reportsBoxName)) {
        return await Hive.openBox(_reportsBoxName);
      }
      return Hive.box(_reportsBoxName);
    }
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
        // Vider TOUT le cache Hive après création pour forcer le rechargement
        print('[ReportRepository] ➕ Signalement créé - vidage complet du cache');
        final box = await _openReportsBox();
        // Supprimer toutes les clés de cache qui commencent par 'reports_'
        final keysToDelete = box.keys.where((key) => key.toString().startsWith('reports_')).toList();
        for (final key in keysToDelete) {
          await box.delete(key);
        }
        print('[ReportRepository] 🗑️ ${keysToDelete.length} clés de cache supprimées');
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

  /// Génère une clé de cache unique basée sur les paramètres de requête
  String _generateCacheKey({
    int page = 1,
    int perPage = 15,
    String? status,
    int? userId,
    int? categoryId,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final parts = <String>[
      'reports',
      'page_$page',
      'perPage_$perPage',
      if (status != null && status.isNotEmpty) 'status_$status',
      if (userId != null) 'userId_$userId',
      if (categoryId != null) 'categoryId_$categoryId',
      if (searchQuery != null && searchQuery.isNotEmpty) 'search_$searchQuery',
      if (startDate != null) 'startDate_${startDate.toIso8601String().split('T')[0]}',
      if (endDate != null) 'endDate_${endDate.toIso8601String().split('T')[0]}',
    ];
    return parts.join('_');
  }

  /// Récupère la liste paginée des signalements
  /// 
  /// [page] : Numéro de page (défaut: 1)
  /// [perPage] : Nombre d'éléments par page (défaut: 15)
  /// [status] : Filtre par statut ('pending', 'in_progress', 'resolved')
  /// [userId] : Filtre par utilisateur (pour "Mes signalements")
  /// [categoryId] : Filtre par catégorie
  /// [searchQuery] : Recherche textuelle (titre ou description)
  /// [startDate] : Date de début pour filtre par plage
  /// [endDate] : Date de fin pour filtre par plage
  /// [includeRelations] : Relations à charger (user, category, images)
  /// 
  /// Retourne une Map avec :
  /// - 'data': List<ReportModel>
  /// - 'meta': { current_page, last_page, total, per_page }
  Future<Map<String, dynamic>> getReports({
    int page = 1,
    int perPage = 15,
    String? status,
    int? userId,
    int? categoryId,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? includeRelations,
  }) async {
    print('[ReportRepository] 🔍 getReports appelé');
    
    // Générer une clé de cache unique pour cette combinaison de filtres
    final cacheKey = _generateCacheKey(
      page: page,
      perPage: perPage,
      status: status,
      userId: userId,
      categoryId: categoryId,
      searchQuery: searchQuery,
      startDate: startDate,
      endDate: endDate,
    );
    print('[ReportRepository] 🔑 Clé de cache: $cacheKey');
    
    final box = await _openReportsBox();
    final now = DateTime.now();
    final cacheMeta = box.get(cacheKey);
    final cacheTime = cacheMeta != null ? DateTime.tryParse(cacheMeta['timestamp'] ?? '') : null;
    final isCacheValid = cacheTime != null && now.difference(cacheTime) < _ttl;
    
    print('[ReportRepository] 📊 Cache check: meta=$cacheMeta');
    print('[ReportRepository] 📊 Cache time: $cacheTime, now: $now');
    print('[ReportRepository] 📊 TTL diff: ${cacheTime != null ? now.difference(cacheTime).inSeconds : "N/A"}s, valid: $isCacheValid');

    // Si cache valide, retourner les données locales
    if (isCacheValid) {
      print('[ReportRepository] ✅ CACHE HIT - Lecture depuis Hive');
      final cachedData = cacheMeta?['data'] as List?;
      if (cachedData != null) {
        final cachedReports = cachedData
            .map((item) => ReportModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        final meta = cacheMeta?['meta'] ?? {};
        print('[ReportRepository] ✅ Retour cache: ${cachedReports.length} reports');
        return {
          'data': cachedReports,
          'meta': meta,
          'source': 'cache',
        };
      }
    }

    // Sinon, requête API et mise à jour du cache
    print('[ReportRepository] ⚠️ CACHE MISS - Appel API');
    try {
      // ...existing code for API request and parsing...
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      
      // Filtres spec.md Phase 3
      if (status != null && status.isNotEmpty) {
        queryParams['filter[status]'] = status;
      }
      if (userId != null) {
        queryParams['user_id'] = userId;
      }
      if (categoryId != null) {
        queryParams['filter[category_id]'] = categoryId.toString();
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }
      if (startDate != null) {
        queryParams['filter[start_date]'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['filter[end_date]'] = endDate.toIso8601String().split('T')[0];
      }
      
      if (includeRelations != null && includeRelations.isNotEmpty) {
        queryParams['include'] = includeRelations.join(',');
      }
      final response = await _dioService.dio.get(
        ApiConstants.reports,
        queryParameters: queryParams,
      );
      if (response.data['success'] == true) {
        // ...existing code for parsing reportsJson and meta...
        final dataField = response.data['data'];
        final List reportsJson;
        final Map<String, dynamic> meta;
        if (dataField is Map && dataField.containsKey('data')) {
          reportsJson = dataField['data'] as List;
          meta = {
            'current_page': dataField['current_page'] ?? page,
            'last_page': dataField['last_page'] ?? page,
            'per_page': dataField['per_page'] ?? perPage,
            'total': dataField['total'] ?? reportsJson.length,
          };
        } else if (dataField is List) {
          reportsJson = dataField;
          meta = {
            'current_page': page,
            'last_page': page,
            'per_page': perPage,
            'total': reportsJson.length,
          };
        } else {
          throw Exception('Format de données inattendu: ${dataField.runtimeType}');
        }
        final reports = reportsJson.map((json) {
          // ...existing code for parsing each report...
          if (json['images'] != null && json['images'] is List) {
            final imagesList = json['images'] as List;
            json['images'] = imagesList.map((img) {
              if (img is Map && img.containsKey('image_url')) {
                return img['image_url'] as String;
              }
              return img.toString();
            }).toList();
          } else {
            json['images'] = [];
          }
          if (json['latitude'] != null && json['longitude'] != null) {
            final lat = json['latitude'] is String ? double.parse(json['latitude']) : json['latitude'];
            final lng = json['longitude'] is String ? double.parse(json['longitude']) : json['longitude'];
            json['location'] = {
              'latitude': lat,
              'longitude': lng,
              'address': json['address'],
            };
          }
          return ReportModel.fromJson(json);
        }).toList();
        
        // Mettre à jour le cache Hive avec clé spécifique aux filtres
        // Convertir en JSON pur (sans objets Freezed) pour Hive
        final jsonData = reportsJson.map((json) {
          // Copier les données brutes JSON du backend (déjà en format pur)
          return Map<String, dynamic>.from(json as Map);
        }).toList();
        
        await box.put(cacheKey, {
          'timestamp': now.toIso8601String(),
          'meta': meta,
          'data': jsonData,
        });
        
        print('[ReportRepository] 💾 Cache mis à jour avec clé: $cacheKey');
        
        return {
          'data': reports,
          'meta': meta,
          'source': 'api',
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
    final box = await _openReportsBox();
    final cachedReport = box.get(id);
    final cacheMeta = box.get(_reportCacheMetaKey);
    final cacheTime = cacheMeta != null ? DateTime.tryParse(cacheMeta['timestamp'] ?? '') : null;
    final now = DateTime.now();
    final isCacheValid = cacheTime != null && now.difference(cacheTime) < _ttl;

    // Si cache valide et report trouvé, retourner local
    if (isCacheValid && cachedReport != null && cachedReport is ReportModelHive) {
      return cachedReport.toReportModel();
    }

    // Sinon, requête API et mise à jour du cache
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
        final originalJson = response.data['data'] as Map<String, dynamic>;
        final json = Map<String, dynamic>.from(originalJson);
        if (json['images'] != null && json['images'] is List) {
          final imagesList = json['images'] as List;
          json['images'] = imagesList.map((img) {
            if (img is Map && img.containsKey('image_url')) {
              return img['image_url'] as String;
            }
            return img.toString();
          }).toList();
        } else {
          json['images'] = [];
        }
        if (json['latitude'] != null && json['longitude'] != null) {
          final lat = json['latitude'] is String ? double.parse(json['latitude']) : json['latitude'];
          final lng = json['longitude'] is String ? double.parse(json['longitude']) : json['longitude'];
          json['location'] = {
            'latitude': lat,
            'longitude': lng,
            'address': json['address'],
          };
        }
        final report = ReportModel.fromJson(json);
        // Mettre à jour le cache Hive
        final hiveReport = ReportModelHive.fromReportModel(report);
        await box.put(hiveReport.id, hiveReport);
        return report;
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
        // Vider TOUT le cache Hive après mise à jour pour forcer le rechargement
        print('[ReportRepository] 🔄 Statut mis à jour - vidage complet du cache');
        final box = await _openReportsBox();
        // Supprimer toutes les clés de cache qui commencent par 'reports_'
        final keysToDelete = box.keys.where((key) => key.toString().startsWith('reports_')).toList();
        for (final key in keysToDelete) {
          await box.delete(key);
        }
        print('[ReportRepository] 🗑️ ${keysToDelete.length} clés de cache supprimées');
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

      // Vider TOUT le cache Hive après suppression pour forcer le rechargement
      print('[ReportRepository] 🗑️ Signalement supprimé - vidage complet du cache');
      final box = await _openReportsBox();
      // Supprimer toutes les clés de cache qui commencent par 'reports_'
      final keysToDelete = box.keys.where((key) => key.toString().startsWith('reports_')).toList();
      for (final key in keysToDelete) {
        await box.delete(key);
      }
      print('[ReportRepository] 🗑️ ${keysToDelete.length} clés de cache supprimées');
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
