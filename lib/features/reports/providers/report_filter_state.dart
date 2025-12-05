import 'package:freezed_annotation/freezed_annotation.dart';

part 'report_filter_state.freezed.dart';

/// État des filtres pour les signalements
/// 
/// Suit spec.md : filtres par statut, catégorie, date
@freezed
class ReportFilterState with _$ReportFilterState {
  const ReportFilterState._(); // Permet les extensions/méthodes
  
  const factory ReportFilterState({
    /// Filtre par statut (null = tous)
    /// Valeurs possibles: 'pending', 'in_progress', 'resolved'
    String? status,
    
    /// Filtre par catégorie ID (null = toutes)
    int? categoryId,
    
    /// Date de début (pour filtrer par plage)
    DateTime? startDate,
    
    /// Date de fin (pour filtrer par plage)
    DateTime? endDate,
    
    /// Recherche textuelle (titre ou description)
    @Default('') String searchQuery,
  }) = _ReportFilterState;

  factory ReportFilterState.initial() => const ReportFilterState();

  /// Retourne true si au moins un filtre est actif
  bool get hasActiveFilters {
    return status != null ||
        categoryId != null ||
        startDate != null ||
        endDate != null ||
        searchQuery.isNotEmpty;
  }

  /// Nombre de filtres actifs
  int get activeFiltersCount {
    int count = 0;
    if (status != null) count++;
    if (categoryId != null) count++;
    if (startDate != null || endDate != null) count++;
    if (searchQuery.isNotEmpty) count++;
    return count;
  }

  /// Convertit les filtres en query parameters pour l'API
  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> params = {};

    if (status != null) {
      params['filter[status]'] = status;
    }

    if (categoryId != null) {
      params['filter[category_id]'] = categoryId.toString();
    }

    if (startDate != null) {
      params['filter[start_date]'] = startDate!.toIso8601String().split('T')[0];
    }

    if (endDate != null) {
      params['filter[end_date]'] = endDate!.toIso8601String().split('T')[0];
    }

    if (searchQuery.isNotEmpty) {
      params['search'] = searchQuery;
    }

    return params;
  }
}
