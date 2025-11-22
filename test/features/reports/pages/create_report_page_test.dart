import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_samacite/features/reports/pages/create_report_page.dart';
import 'package:mobile_samacite/features/reports/providers/report_notifier.dart';
import 'package:mobile_samacite/features/reports/providers/category_notifier.dart';
import 'package:mobile_samacite/features/reports/providers/report_state.dart';
import 'package:mobile_samacite/core/models/category_model.dart';
import 'package:mobile_samacite/core/models/report_model.dart';
import 'package:mobile_samacite/core/models/location_model.dart';

@GenerateMocks([])
void main() {
  group('CreateReportPage - UI Tests', () {
    late ProviderContainer container;
    late TestReportNotifier mockReportNotifier;
    late TestCategoryNotifier mockCategoryNotifier;

    setUp(() {
      mockReportNotifier = TestReportNotifier();
      mockCategoryNotifier = TestCategoryNotifier();

      container = ProviderContainer(
        overrides: [
          reportNotifierProvider.overrideWith((ref) => mockReportNotifier),
          categoryNotifierProvider.overrideWith((ref) => mockCategoryNotifier),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget createTestWidget() {
      return ProviderScope(
        parent: container,
        child: const MaterialApp(
          home: CreateReportPage(),
        ),
      );
    }

    testWidgets('devrait afficher tous les éléments de l\'interface',
        (WidgetTester tester) async {
      // Given
      when(mockCategoryNotifier.stream)
          .thenAnswer((_) => Stream.value(const AsyncValue.data([])));
      when(mockCategoryNotifier.debugState).thenReturn(const AsyncValue.data([]));
      when(mockReportNotifier.stream)
          .thenAnswer((_) => Stream.value(ReportState.initial()));
      when(mockReportNotifier.debugState).thenReturn(ReportState.initial());

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Then - Vérifier présence de tous les widgets principaux
      expect(find.text('Nouveau Signalement'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Titre + Description
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget); // Catégorie
      expect(find.text('Ajouter des photos'), findsOneWidget);
      expect(find.text('Capturer ma position'), findsOneWidget);
      expect(find.text('Créer le signalement'), findsOneWidget);
    });

    testWidgets('devrait afficher les catégories dans le dropdown',
        (WidgetTester tester) async {
      // Given
      final categories = [
        const CategoryModel(id: 1, name: 'Voirie', description: 'Test'),
        const CategoryModel(id: 2, name: 'Éclairage', description: 'Test'),
      ];
      when(mockCategoryNotifier.stream)
          .thenAnswer((_) => Stream.value(AsyncValue.data(categories)));
      when(mockCategoryNotifier.debugState)
          .thenReturn(AsyncValue.data(categories));
      when(mockReportNotifier.stream)
          .thenAnswer((_) => Stream.value(ReportState.initial()));
      when(mockReportNotifier.debugState).thenReturn(ReportState.initial());

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
      
      // Ouvrir le dropdown
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      // Vérifier les options
      expect(find.text('Voirie'), findsOneWidget);
      expect(find.text('Éclairage'), findsOneWidget);
    });

    testWidgets('devrait valider que le titre est requis',
        (WidgetTester tester) async {
      // Given
      when(mockCategoryNotifier.stream)
          .thenAnswer((_) => Stream.value(const AsyncValue.data([])));
      when(mockCategoryNotifier.debugState).thenReturn(const AsyncValue.data([]));
      when(mockReportNotifier.stream)
          .thenAnswer((_) => Stream.value(ReportState.initial()));
      when(mockReportNotifier.debugState).thenReturn(ReportState.initial());

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Trouver le bouton et taper
      final submitButton = find.text('Créer le signalement');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Then - Vérifier message d'erreur validation
      expect(find.text('Le titre est requis'), findsOneWidget);
    });

    testWidgets('devrait valider que la description est requise',
        (WidgetTester tester) async {
      // Given
      when(mockCategoryNotifier.stream)
          .thenAnswer((_) => Stream.value(const AsyncValue.data([])));
      when(mockCategoryNotifier.debugState).thenReturn(const AsyncValue.data([]));
      when(mockReportNotifier.stream)
          .thenAnswer((_) => Stream.value(ReportState.initial()));
      when(mockReportNotifier.debugState).thenReturn(ReportState.initial());

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Remplir uniquement le titre
      await tester.enterText(find.byType(TextFormField).first, 'Test Titre');

      // Soumettre
      final submitButton = find.text('Créer le signalement');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Then
      expect(find.text('La description est requise'), findsOneWidget);
    });

    testWidgets('devrait valider que la catégorie est requise',
        (WidgetTester tester) async {
      // Given
      when(mockCategoryNotifier.stream)
          .thenAnswer((_) => Stream.value(const AsyncValue.data([])));
      when(mockCategoryNotifier.debugState).thenReturn(const AsyncValue.data([]));
      when(mockReportNotifier.stream)
          .thenAnswer((_) => Stream.value(ReportState.initial()));
      when(mockReportNotifier.debugState).thenReturn(ReportState.initial());

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Remplir titre et description
      await tester.enterText(find.byType(TextFormField).first, 'Test Titre');
      await tester.enterText(find.byType(TextFormField).last, 'Test Description');

      // Soumettre
      final submitButton = find.text('Créer le signalement');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Veuillez sélectionner une catégorie'), findsOneWidget);
    });

    testWidgets('devrait appeler selectImages quand on tape sur Ajouter photos',
        (WidgetTester tester) async {
      // Given
      when(mockCategoryNotifier.stream)
          .thenAnswer((_) => Stream.value(const AsyncValue.data([])));
      when(mockCategoryNotifier.debugState).thenReturn(const AsyncValue.data([]));
      when(mockReportNotifier.stream)
          .thenAnswer((_) => Stream.value(ReportState.initial()));
      when(mockReportNotifier.debugState).thenReturn(ReportState.initial());
      when(mockReportNotifier.selectImages()).thenAnswer((_) async {});

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Taper sur le bouton ajouter photos
      await tester.tap(find.text('Ajouter des photos'));
      await tester.pumpAndSettle();

      // Then
      verify(mockReportNotifier.selectImages()).called(1);
    });

    testWidgets('devrait afficher les photos sélectionnées',
        (WidgetTester tester) async {
      // Given
      final mockImages = [
        XFile('/path/to/image1.jpg'),
        XFile('/path/to/image2.jpg'),
      ];
      final stateWithImages = ReportState.initial().copyWith(
        selectedImages: mockImages,
      );

      when(mockCategoryNotifier.stream)
          .thenAnswer((_) => Stream.value(const AsyncValue.data([])));
      when(mockCategoryNotifier.debugState).thenReturn(const AsyncValue.data([]));
      when(mockReportNotifier.stream)
          .thenAnswer((_) => Stream.value(stateWithImages));
      when(mockReportNotifier.debugState).thenReturn(stateWithImages);

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Then - Vérifier que 2 images sont affichées
      expect(find.byType(Image), findsNWidgets(2));
    });

    testWidgets('devrait limiter à 5 photos maximum',
        (WidgetTester tester) async {
      // Given
      final mockImages = List.generate(
        5,
        (index) => XFile('/path/to/image$index.jpg'),
      );
      final stateWithMaxImages = ReportState.initial().copyWith(
        selectedImages: mockImages,
      );

      when(mockCategoryNotifier.stream)
          .thenAnswer((_) => Stream.value(const AsyncValue.data([])));
      when(mockCategoryNotifier.debugState).thenReturn(const AsyncValue.data([]));
      when(mockReportNotifier.stream)
          .thenAnswer((_) => Stream.value(stateWithMaxImages));
      when(mockReportNotifier.debugState).thenReturn(stateWithMaxImages);

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Then - Le bouton "Ajouter photos" devrait être désactivé ou masqué
      final addButton = find.text('Ajouter des photos');
      expect(addButton, findsNothing); // Masqué quand limite atteinte
      expect(find.text('5/5 photos'), findsOneWidget); // Indicateur limite
    });

    testWidgets('devrait appeler captureLocation quand on tape sur GPS',
        (WidgetTester tester) async {
      // Given
      when(mockCategoryNotifier.stream)
          .thenAnswer((_) => Stream.value(const AsyncValue.data([])));
      when(mockCategoryNotifier.debugState).thenReturn(const AsyncValue.data([]));
      when(mockReportNotifier.stream)
          .thenAnswer((_) => Stream.value(ReportState.initial()));
      when(mockReportNotifier.debugState).thenReturn(ReportState.initial());
      when(mockReportNotifier.captureLocation()).thenAnswer((_) async {});

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Taper sur le bouton GPS
      await tester.tap(find.text('Capturer ma position'));
      await tester.pumpAndSettle();

      // Then
      verify(mockReportNotifier.captureLocation()).called(1);
    });

    testWidgets('devrait afficher un indicateur de chargement GPS',
        (WidgetTester tester) async {
      // Given
      final loadingState = ReportState.initial().copyWith(
        isLoadingLocation: true,
      );

      when(mockCategoryNotifier.stream)
          .thenAnswer((_) => Stream.value(const AsyncValue.data([])));
      when(mockCategoryNotifier.debugState).thenReturn(const AsyncValue.data([]));
      when(mockReportNotifier.stream)
          .thenAnswer((_) => Stream.value(loadingState));
      when(mockReportNotifier.debugState).thenReturn(loadingState);

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Localisation en cours...'), findsOneWidget);
    });

    testWidgets('devrait afficher la position capturée',
        (WidgetTester tester) async {
      // Given
      final position = Position(
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
      final stateWithPosition = ReportState.initial().copyWith(
        position: position,
      );

      when(mockCategoryNotifier.stream)
          .thenAnswer((_) => Stream.value(const AsyncValue.data([])));
      when(mockCategoryNotifier.debugState).thenReturn(const AsyncValue.data([]));
      when(mockReportNotifier.stream)
          .thenAnswer((_) => Stream.value(stateWithPosition));
      when(mockReportNotifier.debugState).thenReturn(stateWithPosition);

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.textContaining('14.69'), findsOneWidget); // Latitude affichée
      expect(find.textContaining('-17.44'), findsOneWidget); // Longitude affichée
    });

    testWidgets('devrait soumettre avec succès quand tous les champs sont valides',
        (WidgetTester tester) async {
      // Given
      final categories = [
        const CategoryModel(id: 1, name: 'Voirie', description: 'Test'),
      ];
      when(mockCategoryNotifier.stream)
          .thenAnswer((_) => Stream.value(AsyncValue.data(categories)));
      when(mockCategoryNotifier.debugState)
          .thenReturn(AsyncValue.data(categories));
      when(mockReportNotifier.stream)
          .thenAnswer((_) => Stream.value(ReportState.initial()));
      when(mockReportNotifier.debugState).thenReturn(ReportState.initial());
      when(mockReportNotifier.submitReport(
        title: anyNamed('title'),
        description: anyNamed('description'),
        categoryId: anyNamed('categoryId'),
      )).thenAnswer((_) async {});

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Remplir le formulaire
      await tester.enterText(find.byType(TextFormField).first, 'Nid de poule');
      await tester.enterText(find.byType(TextFormField).last, 'Gros trou sur la route');

      // Sélectionner catégorie
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voirie').last);
      await tester.pumpAndSettle();

      // Soumettre
      final submitButton = find.text('Créer le signalement');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Then
      verify(mockReportNotifier.submitReport(
        title: 'Nid de poule',
        description: 'Gros trou sur la route',
        categoryId: 1,
      )).called(1);
    });

    testWidgets('devrait afficher un indicateur pendant la soumission',
        (WidgetTester tester) async {
      // Given
      final submittingState = ReportState.initial().copyWith(
        status: ReportStatus.submitting,
      );

      when(mockCategoryNotifier.stream)
          .thenAnswer((_) => Stream.value(const AsyncValue.data([])));
      when(mockCategoryNotifier.debugState).thenReturn(const AsyncValue.data([]));
      when(mockReportNotifier.stream)
          .thenAnswer((_) => Stream.value(submittingState));
      when(mockReportNotifier.debugState).thenReturn(submittingState);

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Then - Le bouton devrait être désactivé avec un loader
      final submitButton = find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(ElevatedButton),
      );
      expect(submitButton, findsOneWidget);
    });

    testWidgets('devrait afficher un SnackBar de succès après soumission',
        (WidgetTester tester) async {
      // Given
      final successState = ReportState.initial().copyWith(
        status: ReportStatus.success,
        createdReport: ReportModel(
          id: 1,
          title: 'Test',
          description: 'Test',
          status: 'pending',
          userId: 1,
          categoryId: 1,
          location: const LocationModel(latitude: 14.6937, longitude: -17.4441),
          createdAt: '2025-11-22T10:00:00Z',
          updatedAt: '2025-11-22T10:00:00Z',
        ),
      );

      when(mockCategoryNotifier.stream)
          .thenAnswer((_) => Stream.value(const AsyncValue.data([])));
      when(mockCategoryNotifier.debugState).thenReturn(const AsyncValue.data([]));
      when(mockReportNotifier.stream)
          .thenAnswer((_) => Stream.value(successState));
      when(mockReportNotifier.debugState).thenReturn(successState);

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Signalement créé avec succès'), findsOneWidget);
    });

    testWidgets('devrait afficher un SnackBar d\'erreur en cas d\'échec',
        (WidgetTester tester) async {
      // Given
      final errorState = ReportState.initial().copyWith(
        status: ReportStatus.error,
        errorMessage: 'Erreur réseau',
      );

      when(mockCategoryNotifier.stream)
          .thenAnswer((_) => Stream.value(const AsyncValue.data([])));
      when(mockCategoryNotifier.debugState).thenReturn(const AsyncValue.data([]));
      when(mockReportNotifier.stream)
          .thenAnswer((_) => Stream.value(errorState));
      when(mockReportNotifier.debugState).thenReturn(errorState);

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Erreur réseau'), findsOneWidget);
    });

    testWidgets('devrait permettre de supprimer une photo sélectionnée',
        (WidgetTester tester) async {
      // Given
      final mockImages = [
        XFile('/path/to/image1.jpg'),
      ];
      final stateWithImages = ReportState.initial().copyWith(
        selectedImages: mockImages,
      );

      when(mockCategoryNotifier.stream)
          .thenAnswer((_) => Stream.value(const AsyncValue.data([])));
      when(mockCategoryNotifier.debugState).thenReturn(const AsyncValue.data([]));
      when(mockReportNotifier.stream)
          .thenAnswer((_) => Stream.value(stateWithImages));
      when(mockReportNotifier.debugState).thenReturn(stateWithImages);
      when(mockReportNotifier.removeImage(any)).thenReturn(null);

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Taper sur le bouton supprimer (icône close)
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Then
      verify(mockReportNotifier.removeImage(0)).called(1);
    });
  });
}

// Test helpers
class TestReportNotifier extends ReportNotifier {
  ReportState _testState = ReportState.initial();
  
  TestReportNotifier()
      : super(
          reportRepository: _FakeReportRepository(),
          imageService: _FakeImageService(),
          locationService: _FakeLocationService(),
        );

  void setTestState(ReportState state) {
    _testState = state;
    state = _testState;
  }

  @override
  Future<void> selectImages() async {}

  @override
  Future<void> takePicture() async {}

  @override
  void removeImage(int index) {}

  @override
  Future<void> captureLocation() async {}

  @override
  Future<void> submitReport({
    required String title,
    required String description,
    required int categoryId,
  }) async {}
}

class TestCategoryNotifier extends CategoryNotifier {
  AsyncValue<List<CategoryModel>> _testState = const AsyncValue.data([]);

  TestCategoryNotifier() : super(categoryRepository: _FakeCategoryRepository());

  void setTestState(AsyncValue<List<CategoryModel>> state) {
    _testState = state;
    this.state = _testState;
  }

  @override
  Future<void> loadCategories({bool forceRefresh = false}) async {}
}

// Fake implementations
class _FakeReportRepository implements ReportRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeImageService implements ImageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeLocationService implements LocationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeCategoryRepository implements CategoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
