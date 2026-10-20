import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/core/models/report_model.dart';
import 'package:mobile_samacite/features/reports/pages/report_list_page.dart';

/// Tests UI pour la liste des signalements (Phase 3)
/// 
/// Note: Les tests complets de ReportListPage avec Riverpod sont complexes
/// car ils nécessitent de mocker les providers et les appels API.
/// On se concentre sur les tests des widgets stateless (ReportItemWidget).
void main() {
  group('ReportListPage - Tests UI Phase 3 (Skipped)', () {
    testWidgets('Skip - Nécessite mock Riverpod avancé pour éviter appels API réels', (tester) async {
      // Ces tests de page complète sont skippés car ReportListPage:
      // 1. Utilise des providers Riverpod qui lancent des appels API réels dans initState
      // 2. Nécessite un mock sophistiqué de StateNotifierProvider
      // 3. Les timers Dio interfèrent avec les tests Flutter
      //
      // Solution: Tester manuellement la page ou créer des providers fake complets
    }, skip: true);
  });

  group('ReportItemWidget - Tests unitaires', () {
    testWidgets('DOIT afficher Card avec les infos du signalement', (tester) async {
      // Arrange
      const mockReport = ReportModel(
        id: 1,
        title: 'Route endommagée',
        description: 'Nids de poule dangereux',
        status: 'pending',
        categoryId: 1,
        userId: 1,
        createdAt: '2025-11-22T10:00:00Z',
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ReportItemWidget(report: mockReport),
            ),
          ),
        ),
      );
      await tester.pump();

      // Assert
      expect(find.byType(ReportItemWidget), findsOneWidget);
      expect(find.text('Route endommagée'), findsOneWidget);
    });

    testWidgets('DOIT afficher le nombre de commentaires', (tester) async {
      const mockReport = ReportModel(
        id: 1,
        title: 'Route endommagée',
        description: 'Nids de poule dangereux',
        status: 'pending',
        categoryId: 1,
        userId: 1,
        commentsCount: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportItemWidget(report: mockReport),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('DOIT afficher image placeholder si pas d\'image', (tester) async {
      // Arrange
      const mockReport = ReportModel(
        id: 1,
        title: 'Test',
        description: 'Test',
        status: 'pending',
        categoryId: 1,
        userId: 1,
        images: [], // Pas d'images
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportItemWidget(report: mockReport),
          ),
        ),
      );

      // Assert
      // Vérifier que l'icône placeholder est affichée
      expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
    });

    testWidgets('DOIT afficher la première image si disponible', (tester) async {
      // Arrange
      const mockReport = ReportModel(
        id: 1,
        title: 'Test',
        description: 'Test',
        status: 'pending',
        categoryId: 1,
        userId: 1,
        images: ['https://example.com/image1.jpg'],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportItemWidget(report: mockReport),
          ),
        ),
      );

      // Assert
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
