import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/features/reports/providers/report_filter_state.dart';

/// Provider pour le notifier des filtres
final reportFilterProvider = StateNotifierProvider<ReportFilterNotifier, ReportFilterState>((ref) {
  return ReportFilterNotifier();
});

/// Notifier pour gérer l'état des filtres de signalements
/// 
/// Permet de définir, modifier et réinitialiser les filtres
class ReportFilterNotifier extends StateNotifier<ReportFilterState> {
  ReportFilterNotifier() : super(ReportFilterState.initial());

  /// Définir le filtre de statut
  void setStatus(String? status) {
    state = state.copyWith(status: status);
  }

  /// Définir le filtre de catégorie
  void setCategoryId(int? categoryId) {
    state = state.copyWith(categoryId: categoryId);
  }

  /// Définir la plage de dates
  void setDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Définir la requête de recherche
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Réinitialiser tous les filtres
  void resetFilters() {
    state = ReportFilterState.initial();
  }

  /// Appliquer plusieurs filtres en une seule fois
  void applyFilters({
    String? status,
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    state = ReportFilterState(
      status: status,
      categoryId: categoryId,
      startDate: startDate,
      endDate: endDate,
      searchQuery: searchQuery ?? '',
    );
  }
}
