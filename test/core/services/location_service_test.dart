import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_samacite/core/services/location_service.dart';

// Générer les mocks : flutter pub run build_runner build --delete-conflicting-outputs
@GenerateMocks([GeolocatorPlatform])
import 'location_service_test.mocks.dart';

void main() {
  late LocationService locationService;
  late MockGeolocatorPlatform mockGeolocator;

  setUp(() {
    mockGeolocator = MockGeolocatorPlatform();
    locationService = LocationService(geolocator: mockGeolocator);
  });

  group('LocationService - Permission Handling', () {
    test('should check if location services are enabled', () async {
      // ARRANGE
      when(mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);

      // ACT
      final result = await locationService.isLocationServiceEnabled();

      // ASSERT
      expect(result, true);
      verify(mockGeolocator.isLocationServiceEnabled()).called(1);
    });

    test('should return false if location services are disabled', () async {
      // ARRANGE
      when(mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => false);

      // ACT
      final result = await locationService.isLocationServiceEnabled();

      // ASSERT
      expect(result, false);
    });

    test('should check location permission status', () async {
      // ARRANGE
      when(mockGeolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);

      // ACT
      final result = await locationService.checkPermission();

      // ASSERT
      expect(result, LocationPermission.whileInUse);
      verify(mockGeolocator.checkPermission()).called(1);
    });

    test('should request location permission', () async {
      // ARRANGE
      when(mockGeolocator.requestPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);

      // ACT
      final result = await locationService.requestPermission();

      // ASSERT
      expect(result, LocationPermission.whileInUse);
      verify(mockGeolocator.requestPermission()).called(1);
    });

    test('should handle permission denied', () async {
      // ARRANGE
      when(mockGeolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);

      // ACT
      final result = await locationService.checkPermission();

      // ASSERT
      expect(result, LocationPermission.denied);
    });

    test('should handle permission denied forever', () async {
      // ARRANGE
      when(mockGeolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.deniedForever);

      // ACT
      final result = await locationService.checkPermission();

      // ASSERT
      expect(result, LocationPermission.deniedForever);
    });
  });

  group('LocationService - Get Current Position', () {
    test('should get current position successfully', () async {
      // ARRANGE
      final mockPosition = Position(
        latitude: 14.6937,
        longitude: -17.4441,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      when(mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(mockGeolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(mockGeolocator.getCurrentPosition(
        locationSettings: anyNamed('locationSettings'),
      )).thenAnswer((_) async => mockPosition);

      // ACT
      final result = await locationService.getCurrentPosition();

      // ASSERT
      expect(result, isNotNull);
      expect(result.latitude, 14.6937);
      expect(result.longitude, -17.4441);
    });

    test('should throw exception if location services are disabled', () async {
      // ARRANGE
      when(mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => false);

      // ACT & ASSERT
      expect(
        () => locationService.getCurrentPosition(),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception if permission is denied', () async {
      // ARRANGE
      when(mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(mockGeolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      when(mockGeolocator.requestPermission())
          .thenAnswer((_) async => LocationPermission.denied);

      // ACT & ASSERT
      expect(
        () => locationService.getCurrentPosition(),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception if permission is denied forever', () async {
      // ARRANGE
      when(mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(mockGeolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.deniedForever);

      // ACT & ASSERT
      expect(
        () => locationService.getCurrentPosition(),
        throwsA(isA<Exception>()),
      );
    });

    test('should request permission if not yet asked', () async {
      // ARRANGE
      final mockPosition = Position(
        latitude: 14.6937,
        longitude: -17.4441,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      when(mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(mockGeolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.denied);
      when(mockGeolocator.requestPermission())
          .thenAnswer((_) async => LocationPermission.whileInUse);
      when(mockGeolocator.getCurrentPosition(
        locationSettings: anyNamed('locationSettings'),
      )).thenAnswer((_) async => mockPosition);

      // ACT
      final result = await locationService.getCurrentPosition();

      // ASSERT
      expect(result, isNotNull);
      verify(mockGeolocator.requestPermission()).called(1);
    });
  });

  group('LocationService - Position Settings', () {
    test('should use high accuracy by default', () {
      // ACT
      final settings = locationService.getDefaultSettings();

      // ASSERT
      expect(settings.accuracy, LocationAccuracy.high);
    });

    test('should allow custom accuracy settings', () {
      // ACT
      final settings = locationService.getCustomSettings(
        accuracy: LocationAccuracy.medium,
      );

      // ASSERT
      expect(settings.accuracy, LocationAccuracy.medium);
    });

    test('should set timeout for position requests', () {
      // ACT
      final settings = locationService.getCustomSettings(
        timeLimit: const Duration(seconds: 10),
      );

      // ASSERT
      expect(settings.timeLimit, const Duration(seconds: 10));
    });
  });

  group('LocationService - Distance Calculation', () {
    test('should calculate distance between two positions (Dakar - Thies)', () {
      // ARRANGE
      const dakarLat = 14.6937; // Dakar
      const dakarLon = -17.4441;
      const thiesLat = 14.7886; // Thies
      const thiesLon = -16.9252;

      // ACT
      final distance = locationService.calculateDistance(
        dakarLat,
        dakarLon,
        thiesLat,
        thiesLon,
      );

      // ASSERT
      // Distance approximative entre Dakar et Thiès : ~60-70 km
      expect(distance, greaterThan(50000)); // > 50 km
      expect(distance, lessThan(80000)); // < 80 km
    });

    test('should return 0 for same position', () {
      // ARRANGE
      const lat = 14.6937;
      const lon = -17.4441;

      // ACT
      final distance = locationService.calculateDistance(lat, lon, lat, lon);

      // ASSERT
      expect(distance, 0.0);
    });

    test('should calculate distance in kilometers', () {
      // ARRANGE
      const dakarLat = 14.6937;
      const dakarLon = -17.4441;
      const thiesLat = 14.7886;
      const thiesLon = -16.9252;

      // ACT
      final distanceKm = locationService.calculateDistanceInKm(
        dakarLat,
        dakarLon,
        thiesLat,
        thiesLon,
      );

      // ASSERT
      expect(distanceKm, greaterThan(50)); // > 50 km
      expect(distanceKm, lessThan(80)); // < 80 km
    });
  });

  group('LocationService - Position Stream', () {
    test('should get position stream', () async {
      // ARRANGE
      final mockPosition = Position(
        latitude: 14.6937,
        longitude: -17.4441,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      when(mockGeolocator.getPositionStream(
        locationSettings: anyNamed('locationSettings'),
      )).thenAnswer((_) => Stream.value(mockPosition));

      // ACT
      final stream = locationService.getPositionStream();

      // ASSERT
      expect(stream, isA<Stream<Position>>());
      
      // Vérifier que le stream émet bien la position
      await expectLater(
        stream,
        emits(predicate<Position>((p) => 
          p.latitude == 14.6937 && p.longitude == -17.4441
        )),
      );
    });
  });

  group('LocationService - Error Handling', () {
    test('should handle geolocator exception', () async {
      // ARRANGE
      when(mockGeolocator.isLocationServiceEnabled())
          .thenThrow(Exception('GPS hardware error'));

      // ACT & ASSERT
      expect(
        () => locationService.isLocationServiceEnabled(),
        throwsA(isA<Exception>()),
      );
    });

    test('should provide user-friendly error messages', () {
      // ACT & ASSERT
      expect(
        locationService.getPermissionErrorMessage(LocationPermission.denied),
        contains('refusée'),
      );

      expect(
        locationService.getPermissionErrorMessage(LocationPermission.deniedForever),
        contains('paramètres'),
      );

      expect(
        locationService.getServiceDisabledMessage(),
        contains('activer'),
      );
    });
  });

  group('LocationService - Validation', () {
    test('should validate latitude range (-90 to 90)', () {
      // ACT & ASSERT
      expect(locationService.isValidLatitude(0), true);
      expect(locationService.isValidLatitude(14.6937), true);
      expect(locationService.isValidLatitude(90), true);
      expect(locationService.isValidLatitude(-90), true);
      expect(locationService.isValidLatitude(91), false);
      expect(locationService.isValidLatitude(-91), false);
    });

    test('should validate longitude range (-180 to 180)', () {
      // ACT & ASSERT
      expect(locationService.isValidLongitude(0), true);
      expect(locationService.isValidLongitude(-17.4441), true);
      expect(locationService.isValidLongitude(180), true);
      expect(locationService.isValidLongitude(-180), true);
      expect(locationService.isValidLongitude(181), false);
      expect(locationService.isValidLongitude(-181), false);
    });

    test('should validate coordinate pair', () {
      // ACT & ASSERT
      expect(locationService.isValidCoordinates(14.6937, -17.4441), true);
      expect(locationService.isValidCoordinates(91, -17.4441), false);
      expect(locationService.isValidCoordinates(14.6937, 181), false);
    });
  });
}
