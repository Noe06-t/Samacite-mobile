import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_samacite/core/models/report_model.dart';
import 'package:mobile_samacite/core/services/ai_analysis_service.dart';

part 'report_state.freezed.dart';

/// États possibles d'un signalement
enum ReportStatus {
  initial,      // État initial
  submitting,   // Soumission en cours
  success,      // Signalement créé avec succès
  error,        // Erreur lors de la création
}

/// État du processus de création de signalement
@freezed
class ReportState with _$ReportState {
  const factory ReportState({
    @Default(ReportStatus.initial) ReportStatus status,
    @Default([]) List<XFile> selectedImages,
    Position? position,
    @Default(false) bool isLoadingLocation,
    String? locationError,
    String? errorMessage,
    ReportModel? createdReport,
    // Analyse IA
    @Default(false) bool isAnalyzing,
    AIAnalysisResult? aiAnalysisResult,
    String? aiAnalysisError,
  }) = _ReportState;

  factory ReportState.initial() => const ReportState();
}
