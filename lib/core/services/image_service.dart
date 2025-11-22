import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service de gestion des images
/// 
/// Responsabilités :
/// - Sélection d'images (galerie, caméra)
/// - Compression d'images
/// - Validation (format, taille, nombre)
/// - Respect de la limite de 5 images par signalement (spec.md)
class ImageService {
  final ImagePicker picker;

  /// Taille maximale par image : 5 MB (spec.md Phase 2)
  static const int maxSizeBytes = 5 * 1024 * 1024;

  /// Nombre maximum d'images par signalement (spec.md)
  static const int maxImagesCount = 5;

  /// Qualité de compression par défaut (0-100)
  static const int defaultQuality = 85;

  /// Formats d'images acceptés
  static const List<String> validFormats = ['jpg', 'jpeg', 'png'];

  ImageService({ImagePicker? picker}) : picker = picker ?? ImagePicker();

  /// Vérifie si le format de l'image est valide
  bool isValidFormat(String imagePath) {
    final extension = getExtension(imagePath).toLowerCase().replaceAll('.', '');
    return validFormats.contains(extension);
  }

  /// Vérifie si le nombre d'images est valide (max 5)
  bool isValidCount(List<String> images) {
    return images.length <= maxImagesCount;
  }

  /// Vérifie si on peut ajouter plus d'images
  bool canAddMore(List<String> currentImages, int toAdd) {
    return (currentImages.length + toAdd) <= maxImagesCount;
  }

  /// Vérifie si la taille du fichier est valide (max 5 MB)
  bool isValidSize(int sizeInBytes) {
    return sizeInBytes > 0 && sizeInBytes <= maxSizeBytes;
  }

  /// Vérifie si tous les fichiers ont un format valide
  bool areAllValidFormats(List<String> imagePaths) {
    return imagePaths.every((path) => isValidFormat(path));
  }

  /// Vérifie et demande la permission pour accéder à la galerie (photos)
  Future<bool> _requestPhotosPermission() async {
    // Android 13+ (API 33+) utilise READ_MEDIA_IMAGES
    // Versions antérieures utilisent READ_EXTERNAL_STORAGE
    PermissionStatus status = await Permission.photos.request();
    
    if (status.isDenied) {
      // Essayer avec la permission de stockage pour Android < 13
      status = await Permission.storage.request();
    }
    
    if (status.isPermanentlyDenied) {
      throw Exception(
        'Permission refusée définitivement. Veuillez autoriser l\'accès aux photos dans les paramètres de l\'application.',
      );
    }
    
    return status.isGranted || status.isLimited;
  }

  /// Vérifie et demande la permission pour accéder à la caméra
  Future<bool> _requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.request();
    
    if (status.isPermanentlyDenied) {
      throw Exception(
        'Permission refusée définitivement. Veuillez autoriser l\'accès à la caméra dans les paramètres de l\'application.',
      );
    }
    
    return status.isGranted;
  }

  /// Sélectionne une image depuis la galerie
  Future<XFile?> pickImageFromGallery() async {
    try {
      // Demander la permission avant d'accéder à la galerie
      final hasPermission = await _requestPhotosPermission();
      if (!hasPermission) {
        throw Exception('Permission refusée pour accéder à la galerie');
      }

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );
      return image;
    } catch (e) {
      throw Exception('Erreur lors de la sélection de l\'image : $e');
    }
  }

  /// Sélectionne une image depuis la caméra
  Future<XFile?> pickImageFromCamera() async {
    try {
      // Demander la permission avant d'accéder à la caméra
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        throw Exception('Permission refusée pour accéder à la caméra');
      }

      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
      );
      return image;
    } catch (e) {
      throw Exception('Erreur lors de la prise de photo : $e');
    }
  }

  /// Sélectionne plusieurs images depuis la galerie
  /// 
  /// [maxImages] : Nombre maximum d'images à sélectionner (défaut: 5)
  /// [existingCount] : Nombre d'images déjà sélectionnées
  Future<List<XFile>> pickMultipleImages({
    int maxImages = maxImagesCount,
    int existingCount = 0,
  }) async {
    try {
      final List<XFile> images = await picker.pickMultiImage();

      // Calculer le nombre d'images qu'on peut encore ajouter
      final int remainingSlots = maxImages - existingCount;

      // Limiter le nombre d'images sélectionnées
      if (images.length > remainingSlots) {
        return images.sublist(0, remainingSlots);
      }

      return images;
    } catch (e) {
      throw Exception('Erreur lors de la sélection multiple d\'images : $e');
    }
  }

  /// Compresse une image
  /// 
  /// [file] : Fichier image à compresser
  /// [quality] : Qualité de compression (0-100, défaut: 85)
  /// 
  /// Returns: Fichier image compressé
  Future<XFile> compressImage(
    XFile file, {
    int quality = defaultQuality,
  }) async {
    try {
      // Vérifier que le fichier existe
      final fileExists = await File(file.path).exists();
      if (!fileExists) {
        throw Exception('Le fichier n\'existe pas : ${file.path}');
      }

      // Obtenir le répertoire temporaire
      final tempDir = await getTemporaryDirectory();

      // Générer un nom unique pour le fichier compressé
      final extension = getExtension(file.path).replaceAll('.', '');
      final targetFileName = generateUniqueFilename(extension);
      final targetPath = path.join(tempDir.path, targetFileName);

      // Compresser l'image
      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: quality,
        format: _getCompressFormat(extension),
      );

      if (compressedFile == null) {
        throw Exception('Échec de la compression de l\'image');
      }

      return compressedFile;
    } catch (e) {
      throw Exception('Erreur lors de la compression de l\'image : $e');
    }
  }

  /// Compresse plusieurs images
  Future<List<XFile>> compressMultipleImages(
    List<XFile> files, {
    int quality = defaultQuality,
  }) async {
    final List<XFile> compressedFiles = [];

    for (final file in files) {
      try {
        final compressed = await compressImage(file, quality: quality);
        compressedFiles.add(compressed);
      } catch (e) {
        // Log l'erreur mais continue avec les autres fichiers
        print('Erreur lors de la compression de ${file.path}: $e');
        // Ajouter le fichier original si la compression échoue
        compressedFiles.add(file);
      }
    }

    return compressedFiles;
  }

  /// Obtient l'extension d'un fichier
  String getExtension(String filePath) {
    return path.extension(filePath).toLowerCase();
  }

  /// Génère un nom de fichier unique
  String generateUniqueFilename(String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'compressed_$timestamp.$extension';
  }

  /// Détermine le format de compression en fonction de l'extension
  CompressFormat _getCompressFormat(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return CompressFormat.png;
      case 'jpg':
      case 'jpeg':
        return CompressFormat.jpeg;
      default:
        return CompressFormat.jpeg;
    }
  }

  /// Obtient la taille d'un fichier en bytes
  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    return await file.length();
  }

  /// Valide un fichier image (format + taille)
  Future<bool> validateImageFile(XFile file) async {
    // Vérifier le format
    if (!isValidFormat(file.path)) {
      return false;
    }

    // Vérifier la taille
    final fileSize = await getFileSize(file.path);
    if (!isValidSize(fileSize)) {
      return false;
    }

    return true;
  }

  /// Valide plusieurs fichiers images
  Future<List<String>> validateMultipleImages(List<XFile> files) async {
    final List<String> errors = [];

    // Vérifier le nombre
    if (!isValidCount(files.map((f) => f.path).toList())) {
      errors.add('Vous ne pouvez sélectionner que $maxImagesCount images maximum');
      return errors;
    }

    // Vérifier chaque fichier
    for (int i = 0; i < files.length; i++) {
      final file = files[i];

      // Vérifier le format
      if (!isValidFormat(file.path)) {
        errors.add('Image ${i + 1} : Format invalide. Utilisez jpg, jpeg ou png');
      }

      // Vérifier la taille
      final fileSize = await getFileSize(file.path);
      if (!isValidSize(fileSize)) {
        final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
        errors.add('Image ${i + 1} : Taille trop grande ($sizeMB MB). Maximum 5 MB');
      }
    }

    return errors;
  }
}
