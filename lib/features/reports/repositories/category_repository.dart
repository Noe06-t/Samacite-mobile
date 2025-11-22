import 'package:dio/dio.dart';
import 'package:mobile_samacite/core/models/category_model.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/core/constants/api_constants.dart';

/// Repository pour la gestion des catégories de signalements
/// 
/// Suit le pattern Repository du backend Laravel
/// Utilise Dio pour toutes les requêtes API (spec.md)
/// Inclut un système de cache local (Phase 6 - Cache & Performance)
class CategoryRepository {
  final DioService _dioService;
  
  // Cache local simple (Phase 6 évoluera vers Cache Manager)
  List<CategoryModel>? _cachedCategories;
  DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(hours: 1); // TTL: 1h (spec.md)

  CategoryRepository(this._dioService);

  /// Récupère toutes les catégories disponibles
  /// 
  /// Utilise le cache si disponible et non expiré
  /// Sinon fait un appel API et met à jour le cache
  /// 
  /// Retourne List<CategoryModel>
  /// Lance DioException en cas d'erreur réseau
  Future<List<CategoryModel>> getCategories({bool forceRefresh = false}) async {
    // Vérifier si le cache est valide (Phase 6 - Cache & Performance)
    if (!forceRefresh && _isCacheValid()) {
      return _cachedCategories!;
    }

    try {
      final response = await _dioService.dio.get(ApiConstants.categories);

      if (response.data['success'] == true) {
        // Backend Laravel renvoie : { success, data: [...] }
        final categoriesJson = response.data['data'] as List;
        final categories = categoriesJson
            .map((json) => CategoryModel.fromJson(json))
            .toList();

        // Mettre à jour le cache
        _updateCache(categories);

        return categories;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          message: response.data['message'] ?? 'Erreur récupération catégories',
        );
      }
    } on DioException {
      // Si erreur réseau et cache disponible, retourner le cache
      if (_cachedCategories != null && _cachedCategories!.isNotEmpty) {
        return _cachedCategories!;
      }
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: ApiConstants.categories),
        message: 'Erreur inattendue: $e',
      );
    }
  }

  /// Récupère une catégorie par son ID
  /// 
  /// [id] : ID de la catégorie
  /// 
  /// Retourne CategoryModel ou null si non trouvée
  Future<CategoryModel?> getCategoryById(int id) async {
    try {
      // Chercher d'abord dans le cache
      if (_cachedCategories != null) {
        final cachedCategory = _cachedCategories!
            .where((cat) => cat.id == id)
            .firstOrNull;
        if (cachedCategory != null) {
          return cachedCategory;
        }
      }

      // Sinon appel API
      final response = await _dioService.dio.get(
        '${ApiConstants.categories}/$id',
      );

      if (response.data['success'] == true) {
        return CategoryModel.fromJson(response.data['data']);
      } else {
        return null;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: '${ApiConstants.categories}/$id'),
        message: 'Erreur inattendue: $e',
      );
    }
  }

  /// Vide le cache local
  /// 
  /// Utile pour forcer un refresh des données
  void clearCache() {
    _cachedCategories = null;
    _cacheTimestamp = null;
  }

  /// Vérifie si le cache est valide (non expiré)
  bool _isCacheValid() {
    if (_cachedCategories == null || _cacheTimestamp == null) {
      return false;
    }

    final now = DateTime.now();
    final difference = now.difference(_cacheTimestamp!);

    return difference < _cacheDuration;
  }

  /// Met à jour le cache avec les nouvelles données
  void _updateCache(List<CategoryModel> categories) {
    _cachedCategories = categories;
    _cacheTimestamp = DateTime.now();
  }

  /// Retourne les catégories en cache (si disponibles)
  /// 
  /// Utile pour affichage immédiat pendant le chargement
  /// Retourne null si pas de cache
  List<CategoryModel>? getCachedCategories() {
    return _cachedCategories;
  }

  /// Vérifie si le cache contient des données
  bool hasCachedData() {
    return _cachedCategories != null && _cachedCategories!.isNotEmpty;
  }
}
