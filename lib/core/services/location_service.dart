import 'package:geolocator/geolocator.dart';

/// Service de géolocalisation
/// 
/// Responsabilités :
/// - Vérifier et demander les permissions de localisation
/// - Obtenir la position GPS actuelle
/// - Calculer les distances
/// - Valider les coordonnées
/// - Fournir un stream de positions pour le suivi en temps réel
class LocationService {
  final GeolocatorPlatform geolocator;

  LocationService({GeolocatorPlatform? geolocator})
      : geolocator = geolocator ?? GeolocatorPlatform.instance;

  /// Vérifie si les services de localisation sont activés
  Future<bool> isLocationServiceEnabled() async {
    return await geolocator.isLocationServiceEnabled();
  }

  /// Vérifie le statut des permissions de localisation
  Future<LocationPermission> checkPermission() async {
    return await geolocator.checkPermission();
  }

  /// Demande les permissions de localisation
  Future<LocationPermission> requestPermission() async {
    return await geolocator.requestPermission();
  }

  /// Obtient la position actuelle
  /// 
  /// Throws [Exception] si :
  /// - Les services de localisation sont désactivés
  /// - La permission est refusée
  /// - Une erreur se produit lors de la récupération
  Future<Position> getCurrentPosition() async {
    // Vérifier que les services de localisation sont activés
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(getServiceDisabledMessage());
    }

    // Vérifier les permissions
    LocationPermission permission = await checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(getPermissionErrorMessage(permission));
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(getPermissionErrorMessage(permission));
    }

    // Obtenir la position
    try {
      return await geolocator.getCurrentPosition(
        locationSettings: getDefaultSettings(),
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la position : $e');
    }
  }

  /// Obtient un stream de positions pour le suivi en temps réel
  Stream<Position> getPositionStream({
    LocationSettings? settings,
  }) {
    return geolocator.getPositionStream(
      locationSettings: settings ?? getDefaultSettings(),
    );
  }

  /// Paramètres par défaut (haute précision)
  LocationSettings getDefaultSettings() {
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Mise à jour tous les 10 mètres
    );
  }

  /// Paramètres personnalisés
  LocationSettings getCustomSettings({
    LocationAccuracy? accuracy,
    int? distanceFilter,
    Duration? timeLimit,
  }) {
    return LocationSettings(
      accuracy: accuracy ?? LocationAccuracy.high,
      distanceFilter: distanceFilter ?? 10,
      timeLimit: timeLimit,
    );
  }

  /// Calcule la distance en mètres entre deux positions
  /// 
  /// Utilise la formule de Haversine
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calcule la distance en kilomètres
  double calculateDistanceInKm(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    final distanceInMeters = calculateDistance(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
    return distanceInMeters / 1000;
  }

  /// Valide une latitude (-90 à 90)
  bool isValidLatitude(double latitude) {
    return latitude >= -90 && latitude <= 90;
  }

  /// Valide une longitude (-180 à 180)
  bool isValidLongitude(double longitude) {
    return longitude >= -180 && longitude <= 180;
  }

  /// Valide une paire de coordonnées
  bool isValidCoordinates(double latitude, double longitude) {
    return isValidLatitude(latitude) && isValidLongitude(longitude);
  }

  /// Message d'erreur selon le statut de permission
  String getPermissionErrorMessage(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return 'La permission de localisation a été refusée. Veuillez l\'autoriser dans les réglages.';
      case LocationPermission.deniedForever:
        return 'La permission de localisation a été refusée définitivement. Veuillez l\'activer dans les paramètres de l\'application.';
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return 'Permission accordée';
      default:
        return 'Statut de permission inconnu';
    }
  }

  /// Message si les services de localisation sont désactivés
  String getServiceDisabledMessage() {
    return 'Les services de localisation sont désactivés. Veuillez les activer dans les paramètres.';
  }

  /// Ouvre les paramètres de l'application
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Ouvre les paramètres de localisation
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
