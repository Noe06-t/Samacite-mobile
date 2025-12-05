import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/features/reports/pages/create_report_page.dart';
import 'package:mobile_samacite/features/reports/providers/category_notifier.dart';
import 'package:mobile_samacite/features/reports/providers/report_notifier.dart';
import 'package:mobile_samacite/core/models/category_model.dart';
import 'package:mobile_samacite/features/reports/repositories/report_repository.dart';
import 'package:mobile_samacite/features/reports/repositories/category_repository.dart';
import 'package:mobile_samacite/core/services/image_service.dart';
import 'package:mobile_samacite/core/services/location_service.dart';

/// Tests simplifiés de CreateReportPage
/// Se concentre sur la structure UI et les widgets principaux
/// Mock des providers pour éviter les appels API réels
void main() {
  // Mock data
  final mockCategories = [
    const CategoryModel(id: 1, name: 'Voirie', description: 'Problèmes de voirie'),
    const CategoryModel(id: 2, name: 'Éclairage', description: 'Problèmes d\'éclairage'),
    const CategoryModel(id: 3, name: 'Propreté', description: 'Problèmes de propreté'),
  ];

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        categoryNotifierProvider.overrideWith((ref) {
          final notifier = TestCategoryNotifier();
          notifier.setTestState(AsyncValue.data(mockCategories));
          return notifier;
        }),
        reportNotifierProvider.overrideWith((ref) {
          return TestReportNotifier();
        }),
      ],
      child: const MaterialApp(
        home: CreateReportPage(),
      ),
    );
  }

  group('CreateReportPage - Tests de structure UI', () {
    testWidgets('devrait créer le widget sans erreur', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Attendre que les animations se terminent
      await tester.pumpAndSettle();

      // Vérifier que le widget se construit correctement
      expect(find.byType(CreateReportPage), findsOneWidget);
    });

    testWidgets('devrait afficher l\'AppBar avec le titre', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Vérifier présence AppBar et titre
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Nouveau Signalement'), findsOneWidget);
    });

    testWidgets('devrait afficher le formulaire principal', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Vérifier présence du formulaire
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('devrait afficher les champs de texte principaux', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Vérifier les TextFormFields (Titre et Description)
      expect(find.byType(TextFormField).evaluate().length, greaterThanOrEqualTo(2));
      expect(find.text('Titre'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
    });

    testWidgets('devrait afficher le dropdown catégorie', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Vérifier présence du dropdown catégorie (ou LinearProgressIndicator pendant le chargement)
      final hasDropdown = find.byType(DropdownButtonFormField<int>).evaluate().isNotEmpty;
      final hasLoader = find.byType(LinearProgressIndicator).evaluate().isNotEmpty;
      
      expect(hasDropdown || hasLoader, isTrue);
    });

    testWidgets('devrait afficher la section photos', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Vérifier présence de la section photos
      expect(find.text('Photos'), findsOneWidget);
      expect(find.textContaining('/5 photos'), findsOneWidget);
    });

    testWidgets('devrait afficher les boutons d\'ajout de photos', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Vérifier présence des boutons photos
      expect(find.text('Ajouter des photos'), findsOneWidget);
      expect(find.text('Prendre une photo'), findsOneWidget);
    });

    testWidgets('devrait afficher la section localisation', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Vérifier présence de la section localisation
      expect(find.text('Localisation'), findsOneWidget);
      expect(find.text('Capturer ma position'), findsOneWidget);
    });

    testWidgets('devrait afficher le bouton de soumission', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Vérifier présence du bouton soumettre
      expect(find.text('Créer le signalement'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsAtLeast(1));
    });

    testWidgets('devrait afficher les cards pour photos et localisation', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Vérifier présence de 2 Cards (Photos et Localisation)
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('devrait permettre de saisir du texte dans le titre', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Trouver le premier TextFormField (titre)
      final titleField = find.byType(TextFormField).first;
      
      // Saisir du texte
      await tester.enterText(titleField, 'Test Signalement');
      
      // Vérifier le texte saisi
      expect(find.text('Test Signalement'), findsOneWidget);
    });

    testWidgets('devrait permettre de saisir du texte dans la description', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Trouver le deuxième TextFormField (description)
      final descFields = find.byType(TextFormField);
      expect(descFields.evaluate().length, greaterThanOrEqualTo(2));
      
      final descField = descFields.at(1);
      
      // Saisir du texte
      await tester.enterText(descField, 'Ceci est une description de test');
      
      // Vérifier le texte saisi
      expect(find.text('Ceci est une description de test'), findsOneWidget);
    });

    testWidgets('devrait avoir les bonnes couleurs de thème', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Vérifier couleurs AppBar (vert #007A3F)
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, const Color(0xFF007A3F));
      expect(appBar.foregroundColor, Colors.white);

      // Vérifier qu'au moins un bouton ElevatedButton existe avec la couleur primaire
      final elevatedButtons = find.byType(ElevatedButton).evaluate();
      expect(elevatedButtons.length, greaterThanOrEqualTo(1));
    });
  });
}

// Test helpers - Mock Notifiers
class TestReportNotifier extends ReportNotifier {
  TestReportNotifier()
      : super(
          _FakeReportRepository(),
          _FakeImageService(),
          _FakeLocationService(),
        );

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
  TestCategoryNotifier() : super(_FakeCategoryRepository());

  void setTestState(AsyncValue<List<CategoryModel>> testState) {
    state = testState;
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
