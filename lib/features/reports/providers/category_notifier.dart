import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/core/models/category_model.dart';
import 'package:mobile_samacite/features/reports/repositories/category_repository.dart';
import 'package:mobile_samacite/features/auth/providers/auth_providers.dart';

/// Provider pour le CategoryNotifier
final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<List<CategoryModel>>>(
  (ref) {
    final dioService = ref.watch(dioServiceProvider);
    final categoryRepository = CategoryRepository(dioService);
    return CategoryNotifier(categoryRepository);
  },
);

/// Notifier pour gérer les catégories
/// 
/// Utilise le cache du CategoryRepository (TTL 1h selon spec.md Phase 6)
class CategoryNotifier extends StateNotifier<AsyncValue<List<CategoryModel>>> {
  final CategoryRepository _repository;

  CategoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    print('[CategoryNotifier] 🚀 Constructor appelé - début chargement catégories');
    // Charger les catégories au démarrage
    loadCategories();
  }

  /// Charge les catégories depuis le repository (avec cache)
  Future<void> loadCategories({bool forceRefresh = false}) async {
    print('[CategoryNotifier] 📞 loadCategories appelé (forceRefresh: $forceRefresh)');
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final result = await _repository.getCategories(forceRefresh: forceRefresh);
      print('[CategoryNotifier] ✅ Catégories chargées: ${result.length}');
      return result;
    });
  }

  /// Rafraîchit les catégories (force le rechargement)
  Future<void> refresh() async {
    await loadCategories(forceRefresh: true);
  }
}
