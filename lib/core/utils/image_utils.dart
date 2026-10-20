import 'package:mobile_samacite/core/constants/api_constants.dart';

/// Utilitaires pour la gestion des images
class ImageUtils {
  /// URL de base du serveur (sans /api), dérivée de ApiConstants.baseUrl
  /// pour ne jamais être désynchronisée de l'URL de l'API utilisée.
  static String get _baseServerUrl {
    final apiUrl = ApiConstants.baseUrl;
    return apiUrl.endsWith('/api') ? apiUrl.substring(0, apiUrl.length - 4) : apiUrl;
  }

  /// Convertit un chemin d'image relatif en URL complète
  ///
  /// Exemples (avec l'URL de l'API en production) :
  /// - `/storage/reports/image.jpg` → `https://samacite.artist-dev.com/storage/reports/image.jpg`
  /// - `http://example.com/image.jpg` → `http://example.com/image.jpg` (déjà complet)
  /// - `storage/reports/image.jpg` → `https://samacite.artist-dev.com/storage/reports/image.jpg`
  static String getFullImageUrl(String imagePath) {
    // Si déjà une URL complète (commence par http:// ou https://)
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Sinon, ajouter l'URL de base
    // Retirer le / initial si présent pour éviter les doubles /
    final cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    return '$_baseServerUrl/$cleanPath';
  }

  /// Convertit une liste de chemins d'images en URLs complètes
  static List<String> getFullImageUrls(List<String> imagePaths) {
    return imagePaths.map((path) => getFullImageUrl(path)).toList();
  }
}
