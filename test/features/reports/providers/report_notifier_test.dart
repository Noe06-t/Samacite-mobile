import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_samacite/features/reports/providers/report_notifier.dart';
import 'package:mobile_samacite/features/reports/providers/report_state.dart';
import 'package:mobile_samacite/features/reports/repositories/report_repository.dart';
import 'package:mobile_samacite/core/services/image_service.dart';
import 'package:mobile_samacite/core/services/location_service.dart';
import 'package:mobile_samacite/core/models/report_model.dart';
import 'package:mobile_samacite/core/models/location_model.dart';

// Générer les mocks : flutter pub run build_runner build --delete-conflicting-outputs
@GenerateMocks([ReportRepository, ImageService, LocationService])
import 'report_notifier_test.mocks.dart';

void main() {
  late MockReportRepository mockRepository;
  late MockImageService mockImageService;
  late MockLocationService mockLocationService;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockReportRepository();
    mockImageService = MockImageService();
    mockLocationService = MockLocationService();

    container = ProviderContainer(
      overrides: [
        reportNotifierProvider.overrideWith(
          (ref) => ReportNotifier(
            mockRepository,
            mockImageService,
            mockLocationService,
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ReportNotifier - État initial', () {
    test('DOIT avoir un état initial vide', () {
      // ACT
      final state = container.read(reportNotifierProvider);

      // ASSERT
      expect(state.status, ReportStatus.initial);
      expect(state.selectedImages, isEmpty);
      expect(state.position, isNull);
      expect(state.errorMessage, isNull);
      expect(state.createdReport, isNull);
      expect(state.isLoadingLocation, false);
    });
  });

  group('ReportNotifier - Sélection images', () {
    test('DOIT sélectionner des images depuis la galerie', () async {
      // ARRANGE
      final mockImages = [
        XFile('/path/img1.jpg'),
        XFile('/path/img2.png'),
      ];

      when(mockImageService.pickMultipleImages(
        maxImages: anyNamed('maxImages'),
        existingCount: anyNamed('existingCount'),
      )).thenAnswer((_) async => mockImages);

      // ACT
      await container.read(reportNotifierProvider.notifier).selectImages();

      // ASSERT
      final state = container.read(reportNotifierProvider);
      expect(state.selectedImages.length, 2);
      expect(state.selectedImages[0].path, '/path/img1.jpg');
      verify(mockImageService.pickMultipleImages(
        maxImages: 5,
        existingCount: 0,
      )).called(1);
    });

    test('DOIT ajouter des images aux images existantes', () async {
      // ARRANGE
      final existingImages = [XFile('/existing/img1.jpg')];
      final newImages = [XFile('/new/img2.jpg')];

      // Initialiser l'état avec une image existante
      container.read(reportNotifierProvider.notifier).setImages(existingImages);

      when(mockImageService.pickMultipleImages(
        maxImages: anyNamed('maxImages'),
        existingCount: anyNamed('existingCount'),
      )).thenAnswer((_) async => newImages);

      // ACT
      await container.read(reportNotifierProvider.notifier).selectImages();

      // ASSERT
      final state = container.read(reportNotifierProvider);
      expect(state.selectedImages.length, 2);
    });

    test('DOIT respecter la limite de 5 images', () async {
      // ARRANGE
      final existingImages = List.generate(4, (i) => XFile('/img$i.jpg'));
      final newImages = [XFile('/new/img.jpg'), XFile('/new/img2.jpg')];

      container.read(reportNotifierProvider.notifier).setImages(existingImages);

      when(mockImageService.pickMultipleImages(
        maxImages: anyNamed('maxImages'),
        existingCount: anyNamed('existingCount'),
      )).thenAnswer((_) async => [newImages.first]); // Seulement 1 image ajoutée

      // ACT
      await container.read(reportNotifierProvider.notifier).selectImages();

      // ASSERT
      final state = container.read(reportNotifierProvider);
      expect(state.selectedImages.length, 5);
      verify(mockImageService.pickMultipleImages(
        maxImages: 5,
        existingCount: 4,
      )).called(1);
    });

    test('DOIT gérer les erreurs de sélection d\'images', () async {
      // ARRANGE
      when(mockImageService.pickMultipleImages(
        maxImages: anyNamed('maxImages'),
        existingCount: anyNamed('existingCount'),
      )).thenThrow(Exception('Permission refusée'));

      // ACT
      await container.read(reportNotifierProvider.notifier).selectImages();

      // ASSERT
      final state = container.read(reportNotifierProvider);
      expect(state.errorMessage, contains('Permission refusée'));
    });

    test('DOIT prendre une photo depuis la caméra', () async {
      // ARRANGE
      final mockPhoto = XFile('/camera/photo.jpg');

      when(mockImageService.pickImageFromCamera())
          .thenAnswer((_) async => mockPhoto);

      // ACT
      await container.read(reportNotifierProvider.notifier).takePicture();

      // ASSERT
      final state = container.read(reportNotifierProvider);
      expect(state.selectedImages.length, 1);
      expect(state.selectedImages[0].path, '/camera/photo.jpg');
      verify(mockImageService.pickImageFromCamera()).called(1);
    });

    test('DOIT supprimer une image sélectionnée', () {
      // ARRANGE
      final images = [
        XFile('/img1.jpg'),
        XFile('/img2.jpg'),
        XFile('/img3.jpg'),
      ];
      container.read(reportNotifierProvider.notifier).setImages(images);

      // ACT
      container.read(reportNotifierProvider.notifier).removeImage(1);

      // ASSERT
      final state = container.read(reportNotifierProvider);
      expect(state.selectedImages.length, 2);
      expect(state.selectedImages[0].path, '/img1.jpg');
      expect(state.selectedImages[1].path, '/img3.jpg');
    });
  });

  group('ReportNotifier - Capture localisation', () {
    test('DOIT capturer la position GPS avec succès', () async {
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

      when(mockLocationService.getCurrentPosition())
          .thenAnswer((_) async => mockPosition);

      // ACT
      await container.read(reportNotifierProvider.notifier).captureLocation();

      // ASSERT
      final state = container.read(reportNotifierProvider);
      expect(state.position, isNotNull);
      expect(state.position!.latitude, 14.6937);
      expect(state.position!.longitude, -17.4441);
      expect(state.isLoadingLocation, false);
      verify(mockLocationService.getCurrentPosition()).called(1);
    });

    test('DOIT passer en état loading pendant la capture', () async {
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

      when(mockLocationService.getCurrentPosition())
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return mockPosition;
      });

      // ACT
      final future = container.read(reportNotifierProvider.notifier).captureLocation();

      // ASSERT - Pendant le chargement
      await Future.delayed(const Duration(milliseconds: 50));
      var state = container.read(reportNotifierProvider);
      expect(state.isLoadingLocation, true);

      // Attendre la fin
      await future;
      state = container.read(reportNotifierProvider);
      expect(state.isLoadingLocation, false);
    });

    test('DOIT gérer les erreurs de permission GPS', () async {
      // ARRANGE
      when(mockLocationService.getCurrentPosition())
          .thenThrow(Exception('Permission GPS refusée'));

      // ACT
      await container.read(reportNotifierProvider.notifier).captureLocation();

      // ASSERT
      final state = container.read(reportNotifierProvider);
      expect(state.position, isNull);
      expect(state.isLoadingLocation, false);
      expect(state.locationError, contains('Permission GPS refusée'));
    });

    test('DOIT permettre de définir manuellement une position', () {
      // ARRANGE
      const latitude = 14.7000;
      const longitude = -17.5000;

      // ACT
      container.read(reportNotifierProvider.notifier).setManualLocation(
        latitude,
        longitude,
      );

      // ASSERT
      final state = container.read(reportNotifierProvider);
      expect(state.position, isNotNull);
      expect(state.position!.latitude, latitude);
      expect(state.position!.longitude, longitude);
    });
  });

  group('ReportNotifier - Soumission signalement', () {
    test('DOIT soumettre un signalement avec succès', () async {
      // ARRANGE
      final mockReport = ReportModel(
        id: 1,
        title: 'Test Report',
        description: 'Description test',
        status: 'pending',
        userId: 1,
        categoryId: 2,
        location: const LocationModel(
          latitude: 14.6937,
          longitude: -17.4441,
        ),
        createdAt: '2025-11-22T10:00:00Z',
        updatedAt: '2025-11-22T10:00:00Z',
      );

      when(mockRepository.create(any)).thenAnswer((_) async => mockReport);

      // ACT
      await container.read(reportNotifierProvider.notifier).submitReport(
        title: 'Test Report',
        description: 'Description test',
        categoryId: 2,
      );

      // ASSERT
      final state = container.read(reportNotifierProvider);
      expect(state.status, ReportStatus.success);
      expect(state.createdReport, isNotNull);
      expect(state.createdReport!.id, 1);
      verify(mockRepository.create(any)).called(1);
    });

    test('DOIT passer par les états loading et success', () async {
      // ARRANGE
      final mockReport = ReportModel(
        id: 1,
        title: 'Test',
        description: 'Test',
        status: 'pending',
        userId: 1,
        categoryId: 2,
        createdAt: '2025-11-22T10:00:00Z',
        updatedAt: '2025-11-22T10:00:00Z',
      );

      when(mockRepository.create(any)).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return mockReport;
      });

      // ACT
      final future = container.read(reportNotifierProvider.notifier).submitReport(
        title: 'Test',
        description: 'Test',
        categoryId: 2,
      );

      // ASSERT - État loading
      await Future.delayed(const Duration(milliseconds: 50));
      var state = container.read(reportNotifierProvider);
      expect(state.status, ReportStatus.submitting);

      // Attendre la fin
      await future;
      state = container.read(reportNotifierProvider);
      expect(state.status, ReportStatus.success);
    });

    test('DOIT compresser et uploader les images si présentes', () async {
      // ARRANGE
      final mockImages = [XFile('/img1.jpg'), XFile('/img2.jpg')];
      final mockReport = ReportModel(
        id: 1,
        title: 'Test',
        description: 'Test',
        status: 'pending',
        userId: 1,
        categoryId: 2,
        createdAt: '2025-11-22T10:00:00Z',
        updatedAt: '2025-11-22T10:00:00Z',
      );

      container.read(reportNotifierProvider.notifier).setImages(mockImages);

      when(mockImageService.compressMultipleImages(any))
          .thenAnswer((_) async => mockImages);
      when(mockRepository.create(any)).thenAnswer((_) async => mockReport);
      when(mockRepository.uploadImages(any, any))
          .thenAnswer((_) async => ['/url1.jpg', '/url2.jpg']);

      // ACT
      await container.read(reportNotifierProvider.notifier).submitReport(
        title: 'Test',
        description: 'Test',
        categoryId: 2,
      );

      // ASSERT
      verify(mockImageService.compressMultipleImages(mockImages)).called(1);
      verify(mockRepository.uploadImages(1, any)).called(1);
    });

    test('DOIT inclure la position GPS si disponible', () async {
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

      final mockReport = ReportModel(
        id: 1,
        title: 'Test',
        description: 'Test',
        status: 'pending',
        userId: 1,
        categoryId: 2,
        location: const LocationModel(
          latitude: 14.6937,
          longitude: -17.4441,
        ),
        createdAt: '2025-11-22T10:00:00Z',
        updatedAt: '2025-11-22T10:00:00Z',
      );

      when(mockLocationService.getCurrentPosition())
          .thenAnswer((_) async => mockPosition);
      when(mockRepository.create(any)).thenAnswer((_) async => mockReport);

      // Capturer position d'abord
      await container.read(reportNotifierProvider.notifier).captureLocation();

      // ACT
      await container.read(reportNotifierProvider.notifier).submitReport(
        title: 'Test',
        description: 'Test',
        categoryId: 2,
      );

      // ASSERT
      final capturedData = verify(mockRepository.create(captureAny)).captured.first;
      expect(capturedData['latitude'], 14.6937);
      expect(capturedData['longitude'], -17.4441);
    });

    test('DOIT gérer les erreurs de soumission', () async {
      // ARRANGE
      when(mockRepository.create(any))
          .thenThrow(Exception('Erreur réseau'));

      // ACT
      await container.read(reportNotifierProvider.notifier).submitReport(
        title: 'Test',
        description: 'Test',
        categoryId: 2,
      );

      // ASSERT
      final state = container.read(reportNotifierProvider);
      expect(state.status, ReportStatus.error);
      expect(state.errorMessage, contains('Erreur réseau'));
    });

    test('DOIT valider les champs obligatoires', () async {
      // ACT & ASSERT - Titre vide
      await container.read(reportNotifierProvider.notifier).submitReport(
        title: '',
        description: 'Description',
        categoryId: 1,
      );

      var state = container.read(reportNotifierProvider);
      expect(state.status, ReportStatus.error);
      expect(state.errorMessage, contains('titre'));

      // Reset état
      container.read(reportNotifierProvider.notifier).reset();

      // ACT & ASSERT - Description vide
      await container.read(reportNotifierProvider.notifier).submitReport(
        title: 'Titre',
        description: '',
        categoryId: 1,
      );

      state = container.read(reportNotifierProvider);
      expect(state.status, ReportStatus.error);
      expect(state.errorMessage, contains('description'));
    });
  });

  group('ReportNotifier - Réinitialisation', () {
    test('DOIT réinitialiser l\'état', () {
      // ARRANGE
      final images = [XFile('/img.jpg')];
      container.read(reportNotifierProvider.notifier).setImages(images);

      // ACT
      container.read(reportNotifierProvider.notifier).reset();

      // ASSERT
      final state = container.read(reportNotifierProvider);
      expect(state.status, ReportStatus.initial);
      expect(state.selectedImages, isEmpty);
      expect(state.position, isNull);
      expect(state.errorMessage, isNull);
      expect(state.createdReport, isNull);
    });
  });
}
