/// Utilitaires pour la gestion des images
class ImageUtils {
  /// URL de base du serveur (sans /api)
  static const String _baseServerUrl = 'http://10.0.2.2:8000';

  /// Convertit un chemin d'image relatif en URL complète
  /// 
  /// Exemples :
  /// - `/storage/reports/image.jpg` → `http://10.0.2.2:8000/storage/reports/image.jpg`
  /// - `http://example.com/image.jpg` → `http://example.com/image.jpg` (déjà complet)
  /// - `storage/reports/image.jpg` → `http://10.0.2.2:8000/storage/reports/image.jpg`
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
