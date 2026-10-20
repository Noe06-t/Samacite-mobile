import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/features/reports/providers/report_list_state.dart';
import 'package:mobile_samacite/features/reports/repositories/report_repository.dart';
import 'package:mobile_samacite/features/reports/providers/report_filter_notifier.dart';

/// Notifier pour la gestion de la liste des signalements
/// 
/// Gère le chargement, la pagination et le rafraîchissement
/// de la liste des signalements avec infinite scroll et filtres
class ReportListNotifier extends StateNotifier<ReportListState> {
  final ReportRepository _repository;
  final Ref _ref;

  static const int _perPage = 15;
  static const List<String> _defaultIncludes = ['user', 'category', 'images'];

  ReportListNotifier(this._repository, this._ref) : super(ReportListState.initial());

  /// Charge la première page des signalements
  /// 
  /// Réinitialise l'état et charge depuis la page 1
  Future<void> loadReports() async {
    // Empêcher les appels multiples simultanés
    if (state.isLoading) return;

    // Passer en mode loading
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      // Récupérer les filtres actifs depuis le provider
      // Le statut n'est volontairement PAS envoyé au serveur : le backend a
      // des valeurs de statut incohérentes (anglais/français selon les
      // signalements), donc le filtrage par statut se fait côté client
      // (voir normalizeStatus / report_list_page.dart).
      final filters = _ref.read(reportFilterProvider);
      print('[ReportListNotifier] 📡 Appel getReports...');
      print('[ReportListNotifier] 🔍 Filtres: categoryId=${filters.categoryId}, search=${filters.searchQuery}');

      final result = await _repository.getReports(
        page: 1,
        perPage: _perPage,
        categoryId: filters.categoryId,
        searchQuery: filters.searchQuery,
        startDate: filters.startDate,
        endDate: filters.endDate,
        includeRelations: _defaultIncludes,
      );

      print('[ReportListNotifier] ✅ Réponse reçue');
      print('[ReportListNotifier] 🔍 Keys du result: ${result.keys}');
      
      final reports = result['data'] as List;
      print('[ReportListNotifier] 📊 Nombre de reports: ${reports.length}');
      
      final meta = result['meta'] as Map<String, dynamic>;
      print('[ReportListNotifier] 🔍 Meta: $meta');

      // Déterminer s'il reste des pages
      final currentPage = meta['current_page'] as int;
      final lastPage = meta['last_page'] as int;
      final hasMore = currentPage < lastPage;
      
      print('[ReportListNotifier] 📄 Page $currentPage/$lastPage, hasMore: $hasMore');

      state = state.copyWith(
        reports: reports.cast(),
        isLoading: false,
        hasMore: hasMore,
        currentPage: currentPage,
        errorMessage: null,
      );
    } catch (e, stackTrace) {
      // Extraire un message d'erreur clair
      print('[ReportListNotifier] ❌ ERREUR: $e');
      print('[ReportListNotifier] 📍 StackTrace: $stackTrace');
      
      String errorMessage = 'Erreur de connexion';
      
      if (e.toString().contains('DioException')) {
        errorMessage = 'Impossible de charger les signalements. Vérifiez votre connexion.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Erreur de format des données reçues';
      } else if (e.toString().contains('type \'Null\'')) {
        errorMessage = 'Aucune donnée reçue du serveur';
      } else if (e.toString().contains('type \'String\' is not a subtype')) {
        errorMessage = 'Erreur de format: ${e.toString()}';
      }
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );
    }
  }

  /// Charge la page suivante (pagination)
  /// 
  /// Ajoute les nouveaux signalements à la liste existante
  Future<void> loadMoreReports() async {
    // Ne pas charger si déjà en cours ou plus de données
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;
      
      // Récupérer les filtres actifs (statut filtré côté client, voir plus haut)
      final filters = _ref.read(reportFilterProvider);

      final result = await _repository.getReports(
        page: nextPage,
        perPage: _perPage,
        categoryId: filters.categoryId,
        searchQuery: filters.searchQuery,
        startDate: filters.startDate,
        endDate: filters.endDate,
        includeRelations: _defaultIncludes,
      );

      final newReports = result['data'] as List;
      final meta = result['meta'] as Map<String, dynamic>;

      final currentPage = meta['current_page'] as int;
      final lastPage = meta['last_page'] as int;
      final hasMore = currentPage < lastPage;

      // Ajouter les nouveaux signalements à la liste existante
      state = state.copyWith(
        reports: [...state.reports, ...newReports.cast()],
        isLoading: false,
        hasMore: hasMore,
        currentPage: currentPage,
      );
    } catch (e) {
      // Message d'erreur pour pagination
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Impossible de charger plus de signalements',
      );
    }
  }

  /// Rafraîchit la liste (pull-to-refresh)
  /// 
  /// Réinitialise complètement l'état et recharge depuis le début
  Future<void> refresh() async {
    // Réinitialiser l'état
    state = ReportListState.initial();

    // Recharger depuis la page 1
    await loadReports();
  }
}
