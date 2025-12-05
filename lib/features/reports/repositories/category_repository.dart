import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:mobile_samacite/core/models/category_model.dart';
import 'package:mobile_samacite/core/models/category_model_hive.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/core/constants/api_constants.dart';

/// Repository pour la gestion des catégories de signalements
/// 
/// Suit le pattern Repository du backend Laravel
/// Utilise Dio pour toutes les requêtes API (spec.md)
/// Cache Hive avec TTL 60s (Phase 6 - spec.md)
class CategoryRepository {
  final DioService _dioService;
  
  // Nom des box Hive
  static const String _categoriesBoxName = 'categories_box';
  static const String _categoriesCacheMetaKey = 'categories_meta';
  static const Duration _ttl = Duration(seconds: 60); // TTL 60s (spec.md)

  // Helper pour ouvrir la box Hive
  Future<Box> _openCategoriesBox() async {
    if (!Hive.isBoxOpen(_categoriesBoxName)) {
      return await Hive.openBox(_categoriesBoxName);
    }
    return Hive.box(_categoriesBoxName);
  }

  CategoryRepository(this._dioService);

  /// Récupère toutes les catégories disponibles
  /// 
  /// Utilise le cache Hive si disponible et TTL valide (60s)
  /// Sinon fait un appel API et met à jour le cache
  /// 
  /// Retourne List<CategoryModel>
  /// Lance DioException en cas d'erreur réseau
  Future<List<CategoryModel>> getCategories({bool forceRefresh = false}) async {
    print('[CategoryRepository] 🔍 getCategories appelé (forceRefresh: $forceRefresh)');
    
    if (!forceRefresh) {
      final box = await _openCategoriesBox();
      final now = DateTime.now();
      final cacheMeta = box.get(_categoriesCacheMetaKey);
      final cacheTime = cacheMeta != null ? DateTime.tryParse(cacheMeta['timestamp'] ?? '') : null;
      final isCacheValid = cacheTime != null && now.difference(cacheTime) < _ttl;

      print('[CategoryRepository] 📊 Cache check: meta=$cacheMeta');
      print('[CategoryRepository] 📊 TTL diff: ${cacheTime != null ? now.difference(cacheTime).inSeconds : "N/A"}s, valid: $isCacheValid');

      // Si cache valide, retourner les données locales
      if (isCacheValid) {
        print('[CategoryRepository] ✅ CACHE HIT - Lecture depuis Hive');
        final cachedCategories = box.values
            .where((item) => item is CategoryModelHive)
            .cast<CategoryModelHive>()
            .map((hiveCategory) => hiveCategory.toCategoryModel())
            .toList();
        print('[CategoryRepository] ✅ Retour cache: ${cachedCategories.length} catégories');
        return cachedCategories;
      }
    }

    // Sinon, requête API et mise à jour du cache
    print('[CategoryRepository] ⚠️ CACHE MISS - Appel API');
    try {
      final response = await _dioService.dio.get(ApiConstants.categories);

      if (response.data['success'] == true) {
        // Backend Laravel renvoie : { success, data: [...] }
        final categoriesJson = response.data['data'] as List;
        final categories = categoriesJson
            .map((json) => CategoryModel.fromJson(json))
            .toList();

        // Mettre à jour le cache Hive
        final box = await _openCategoriesBox();
        await box.clear();
        for (final category in categories) {
          final hiveCategory = CategoryModelHive.fromCategoryModel(category);
          await box.put(hiveCategory.id, hiveCategory);
        }
        await box.put(_categoriesCacheMetaKey, {
          'timestamp': DateTime.now().toIso8601String(),
        });
        print('[CategoryRepository] ✅ Cache mis à jour: ${categories.length} catégories');

        return categories;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          message: response.data['message'] ?? 'Erreur récupération catégories',
        );
      }
    } on DioException {
      // Si erreur réseau et cache disponible, retourner le cache
      final box = await _openCategoriesBox();
      final cachedCategories = box.values
          .where((item) => item is CategoryModelHive)
          .cast<CategoryModelHive>()
          .map((hiveCategory) => hiveCategory.toCategoryModel())
          .toList();
      
      if (cachedCategories.isNotEmpty) {
        print('[CategoryRepository] ⚠️ Erreur API, retour cache: ${cachedCategories.length} catégories');
        return cachedCategories;
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
      // Chercher d'abord dans le cache Hive
      final box = await _openCategoriesBox();
      final hiveCategory = box.get(id);
      if (hiveCategory != null && hiveCategory is CategoryModelHive) {
        return hiveCategory.toCategoryModel();
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

  /// Vide le cache Hive local
  /// 
  /// Utile pour forcer un refresh des données
  Future<void> clearCache() async {
    final box = await _openCategoriesBox();
    await box.clear();
  }
}
