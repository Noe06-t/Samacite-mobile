import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_samacite/features/reports/providers/report_state.dart';
import 'package:mobile_samacite/features/reports/repositories/report_repository.dart';
import 'package:mobile_samacite/core/services/image_service.dart';
import 'package:mobile_samacite/core/services/location_service.dart';
import 'package:mobile_samacite/core/services/ai_analysis_service.dart';
import 'package:mobile_samacite/features/auth/providers/auth_providers.dart';

/// Provider pour le ReportNotifier
final reportNotifierProvider =
    StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  final dioService = ref.watch(dioServiceProvider);
  final reportRepository = ReportRepository(dioService);
  final imageService = ImageService();
  final locationService = LocationService();
  final aiAnalysisService = ref.watch(aiAnalysisServiceProvider);

  return ReportNotifier(
    reportRepository,
    imageService,
    locationService,
    aiAnalysisService,
  );
});

/// Notifier pour gérer l'état de création de signalement
/// 
/// Responsabilités :
/// - Orchestrer la sélection d'images
/// - Analyser automatiquement avec IA après ajout photo
/// - Gérer la capture de localisation GPS
/// - Soumettre le signalement au backend
/// - Gérer les états (loading, success, error)
class ReportNotifier extends StateNotifier<ReportState> {
  final ReportRepository _repository;
  final ImageService _imageService;
  final LocationService _locationService;
  final AIAnalysisService _aiAnalysisService;

  ReportNotifier(
    this._repository,
    this._imageService,
    this._locationService,
    this._aiAnalysisService,
  ) : super(ReportState.initial());

  /// Sélectionne des images depuis la galerie
  /// 
  /// Respecte la limite de 5 images (spec.md Phase 2)
  /// Lance l'analyse IA automatiquement après ajout de la première photo
  Future<void> selectImages() async {
    try {
      final images = await _imageService.pickMultipleImages(
        maxImages: 5,
        existingCount: state.selectedImages.length,
      );

      if (images.isNotEmpty) {
        final allImages = [...state.selectedImages, ...images];
        state = state.copyWith(
          selectedImages: allImages,
          errorMessage: null,
        );

        // Auto-analyse avec IA si c'est la première photo et qu'on n'a pas déjà analysé
        if (allImages.length == 1 && state.aiAnalysisResult == null) {
          await analyzeImageWithAI();
        }
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Erreur lors de la sélection des images : $e',
      );
    }
  }

  /// Prend une photo avec la caméra
  /// Lance l'analyse IA automatiquement après capture de la première photo
  Future<void> takePicture() async {
    try {
      // Vérifier qu'on ne dépasse pas la limite
      if (state.selectedImages.length >= 5) {
        state = state.copyWith(
          errorMessage: 'Vous ne pouvez ajouter que 5 images maximum',
        );
        return;
      }

      final photo = await _imageService.pickImageFromCamera();

      if (photo != null) {
        final allImages = [...state.selectedImages, photo];
        state = state.copyWith(
          selectedImages: allImages,
          errorMessage: null,
        );

        // Auto-analyse avec IA si c'est la première photo et qu'on n'a pas déjà analysé
        if (allImages.length == 1 && state.aiAnalysisResult == null) {
          await analyzeImageWithAI();
        }
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Erreur lors de la prise de photo : $e',
      );
    }
  }

  /// Supprime une image de la liste
  void removeImage(int index) {
    if (index >= 0 && index < state.selectedImages.length) {
      final images = [...state.selectedImages];
      images.removeAt(index);
      state = state.copyWith(selectedImages: images);
    }
  }

  /// Définit manuellement la liste d'images (utilisé pour les tests)
  void setImages(List<XFile> images) {
    state = state.copyWith(selectedImages: images);
  }

  /// Analyse la première image avec IA et stocke le résultat
  /// 
  /// Appelée automatiquement après ajout de la première photo
  /// Le résultat peut être utilisé pour pré-remplir le formulaire
  Future<void> analyzeImageWithAI() async {
    if (state.selectedImages.isEmpty) {
      return;
    }

    state = state.copyWith(
      isAnalyzing: true,
      aiAnalysisError: null,
    );

    try {
      final firstImagePath = state.selectedImages.first.path;
      final result = await _aiAnalysisService.analyzeImage(firstImagePath);
      
      state = state.copyWith(
        isAnalyzing: false,
        aiAnalysisResult: result,
        aiAnalysisError: null,
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        aiAnalysisError: 'Analyse IA échouée: ${e.toString()}',
      );
    }
  }

  /// Réinitialise les résultats de l'analyse IA (pour réanalyser)
  void clearAIAnalysis() {
    state = state.copyWith(
      aiAnalysisResult: null,
      aiAnalysisError: null,
    );
  }

  /// Capture la position GPS actuelle avec timeout et fallback
  Future<void> captureLocation() async {
    state = state.copyWith(
      isLoadingLocation: true,
      locationError: null,
    );

    try {
      // Tentative avec haute précision (timeout 10s)
      final position = await _locationService.getCurrentPosition()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () async {
              // Fallback: utiliser précision moyenne plus rapide
              try {
                return await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.medium,
                  timeLimit: const Duration(seconds: 5),
                );
              } catch (e) {
                // Dernier recours: précision basse
                return await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.low,
                  timeLimit: const Duration(seconds: 3),
                );
              }
            },
          );

      state = state.copyWith(
        position: position,
        isLoadingLocation: false,
        locationError: null,
      );
    } catch (e) {
      String errorMessage = 'Impossible de capturer votre position';
      
      if (e.toString().contains('permission')) {
        errorMessage = 'Permission de localisation refusée. Activez-la dans les paramètres.';
      } else if (e.toString().contains('service')) {
        errorMessage = 'GPS désactivé. Activez la localisation sur votre appareil.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'La capture prend trop de temps. Vérifiez votre connexion GPS.';
      }
      
      state = state.copyWith(
        isLoadingLocation: false,
        locationError: errorMessage,
      );
    }
  }

  /// Définit manuellement une position (pour sélection manuelle sur carte)
  void setManualLocation(double latitude, double longitude) {
    final position = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

    state = state.copyWith(
      position: position,
      locationError: null,
    );
  }

  /// Soumet le signalement au backend
  /// 
  /// Processus :
  /// 1. Valide les champs obligatoires
  /// 2. Compresse les images sélectionnées
  /// 3. Crée le signalement avec les données textuelles
  /// 4. Upload les images compressées
  /// 
  /// [title] : Titre du signalement (requis)
  /// [description] : Description détaillée (requis)
  /// [categoryId] : ID de la catégorie (requis)
  Future<void> submitReport({
    required String title,
    required String description,
    required int categoryId,
  }) async {
    // Validation des champs
    if (title.trim().isEmpty) {
      state = state.copyWith(
        status: ReportStatus.error,
        errorMessage: 'Le titre est obligatoire',
      );
      return;
    }

    if (description.trim().isEmpty) {
      state = state.copyWith(
        status: ReportStatus.error,
        errorMessage: 'La description est obligatoire',
      );
      return;
    }

    // Passer en état submitting
    state = state.copyWith(
      status: ReportStatus.submitting,
      errorMessage: null,
    );

    try {
      // Préparer les données du signalement
      final reportData = <String, dynamic>{
        'title': title.trim(),
        'description': description.trim(),
        'category_id': categoryId,
      };

      // Ajouter la position GPS si disponible
      if (state.position != null) {
        reportData['latitude'] = state.position!.latitude;
        reportData['longitude'] = state.position!.longitude;
      }

      // 1. Créer le signalement
      final createdReport = await _repository.create(reportData);

      // 2. Compresser et uploader les images si présentes
      if (state.selectedImages.isNotEmpty) {
        // Compresser les images
        final compressedImages = await _imageService.compressMultipleImages(
          state.selectedImages,
        );

        // Uploader les images
        final imagePaths = compressedImages.map((file) => file.path).toList();
        await _repository.uploadImages(createdReport.id, imagePaths);
      }

      // Succès !
      state = state.copyWith(
        status: ReportStatus.success,
        createdReport: createdReport,
        errorMessage: null,
      );
      
      // CORRECTION 3 : Invalider le cache de la liste pour forcer le refresh
      // Note : Cette fonctionnalité sera complétée en Phase 6 avec cache Redis
      // Pour l'instant, ReportListPage rechargera automatiquement à l'ouverture
    } catch (e) {
      state = state.copyWith(
        status: ReportStatus.error,
        errorMessage: 'Erreur lors de la création du signalement : $e',
      );
    }
  }

  /// Réinitialise l'état (utilisé après succès ou pour recommencer)
  void reset() {
    state = ReportState.initial();
  }
}
