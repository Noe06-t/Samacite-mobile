import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_samacite/features/reports/providers/report_state.dart';
import 'package:mobile_samacite/features/reports/repositories/report_repository.dart';
import 'package:mobile_samacite/core/services/image_service.dart';
import 'package:mobile_samacite/core/services/location_service.dart';
import 'package:mobile_samacite/features/auth/providers/auth_providers.dart';

/// Provider pour le ReportNotifier
final reportNotifierProvider =
    StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  final dioService = ref.watch(dioServiceProvider);
  final reportRepository = ReportRepository(dioService);
  final imageService = ImageService();
  final locationService = LocationService();

  return ReportNotifier(reportRepository, imageService, locationService);
});

/// Notifier pour gérer l'état de création de signalement
/// 
/// Responsabilités :
/// - Orchestrer la sélection d'images
/// - Gérer la capture de localisation GPS
/// - Soumettre le signalement au backend
/// - Gérer les états (loading, success, error)
class ReportNotifier extends StateNotifier<ReportState> {
  final ReportRepository _repository;
  final ImageService _imageService;
  final LocationService _locationService;

  ReportNotifier(
    this._repository,
    this._imageService,
    this._locationService,
  ) : super(ReportState.initial());

  /// Sélectionne des images depuis la galerie
  /// 
  /// Respecte la limite de 5 images (spec.md Phase 2)
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
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Erreur lors de la sélection des images : $e',
      );
    }
  }

  /// Prend une photo avec la caméra
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

  /// Capture la position GPS actuelle
  Future<void> captureLocation() async {
    state = state.copyWith(
      isLoadingLocation: true,
      locationError: null,
    );

    try {
      final position = await _locationService.getCurrentPosition();

      state = state.copyWith(
        position: position,
        isLoadingLocation: false,
        locationError: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingLocation: false,
        locationError: e.toString(),
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
