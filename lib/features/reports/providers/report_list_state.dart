import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile_samacite/core/models/report_model.dart';

part 'report_list_state.freezed.dart';

/// État pour la gestion de la liste des signalements
/// 
/// Gère la pagination, le chargement, et les erreurs
/// pour l'affichage de la liste des signalements
@freezed
class ReportListState with _$ReportListState {
  const factory ReportListState({
    /// Liste des signalements chargés
    required List<ReportModel> reports,
    
    /// Indique si un chargement est en cours
    required bool isLoading,
    
    /// Indique s'il reste des données à charger
    required bool hasMore,
    
    /// Page actuelle de la pagination
    required int currentPage,
    
    /// Message d'erreur en cas de problème
    String? errorMessage,
  }) = _ReportListState;

  /// État initial avec une liste vide
  factory ReportListState.initial() => const ReportListState(
        reports: [],
        isLoading: false,
        hasMore: true,
        currentPage: 1,
        errorMessage: null,
      );
}
