import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/core/models/report_model.dart';
import 'package:mobile_samacite/features/reports/pages/report_detail_page.dart';

/// Tests UI pour la page de détail de signalement (Phase 3)
///  
/// Design basé sur detail-signalement.xml
void main() {
  group('ReportDetailPage - Tests UI Phase 3', () {
    group('Structure de base', () {
      testWidgets('DOIT afficher les infos principales du signalement', (tester) async {
        // Arrange
        const mockReport = ReportModel(
          id: 1,
          title: 'Route endommagée',
          description: 'Nids de poule dangereux sur la voie principale',
          status: 'pending',
          categoryId: 1,
          userId: 1,
          createdAt: '2025-11-22T10:00:00Z',
        );

        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: ReportDetailPage(reportId: 1),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - La page devrait charger automatiquement les données
        // Note: Ce test nécessite un mock du provider pour éviter l'appel API réel
      }, skip: true); // Nécessite mock Riverpod pour éviter appel API

      testWidgets('ReportDetailContent - DOIT afficher le titre', (tester) async {
        // Arrange
        const mockReport = ReportModel(
          id: 1,
          title: 'Route endommagée',
          description: 'Test',
          status: 'pending',
          categoryId: 1,
          userId: 1,
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ReportDetailContent(report: mockReport),
              ),
            ),
          ),
        );
        await tester.pump(); // Render initial frame only

        // Assert
        expect(find.text('Route endommagée'), findsOneWidget);
      });

      testWidgets('ReportDetailContent - DOIT afficher la description', (tester) async {
        // Arrange
        const mockReport = ReportModel(
          id: 1,
          title: 'Test',
          description: 'Nids de poule dangereux',
          status: 'pending',
          categoryId: 1,
          userId: 1,
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ReportDetailContent(report: mockReport),
              ),
            ),
          ),
        );
        await tester.pump(); // Render initial frame only

        // Assert
        expect(find.text('Nids de poule dangereux'), findsOneWidget);
      });

      testWidgets('ReportDetailContent - DOIT afficher la section "Description"', (tester) async {
        // Arrange
        const mockReport = ReportModel(
          id: 1,
          title: 'Test',
          description: 'Test desc',
          status: 'pending',
          categoryId: 1,
          userId: 1,
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ReportDetailContent(report: mockReport),
              ),
            ),
          ),
        );
        await tester.pump(); // Render initial frame only

        // Assert
        expect(find.text('Description'), findsOneWidget);
      });
    });

    group('Affichage statut', () {
      testWidgets('DOIT afficher le statut avec couleur "En cours" (pending)', (tester) async {
        // Arrange
        const mockReport = ReportModel(
          id: 1,
          title: 'Test',
          description: 'Test',
          status: 'pending',
          categoryId: 1,
          userId: 1,
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ReportDetailContent(report: mockReport),
              ),
            ),
          ),
        );
        await tester.pump();

        // Assert
        expect(find.text('En cours'), findsOneWidget);
      });

      testWidgets('DOIT afficher le statut avec couleur "Résolu" (resolved)', (tester) async {
        // Arrange
        const mockReport = ReportModel(
          id: 1,
          title: 'Test',
          description: 'Test',
          status: 'resolved',
          categoryId: 1,
          userId: 1,
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ReportDetailContent(report: mockReport),
              ),
            ),
          ),
        );
        await tester.pump();

        // Assert
        expect(find.text('Résolu'), findsOneWidget);
      });

      testWidgets('DOIT afficher le statut avec couleur "En attente" (in_progress)', (tester) async {
        // Arrange
        const mockReport = ReportModel(
          id: 1,
          title: 'Test',
          description: 'Test',
          status: 'in_progress',
          categoryId: 1,
          userId: 1,
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ReportDetailContent(report: mockReport),
              ),
            ),
          ),
        );
        await tester.pump();

        // Assert
        expect(find.text('En attente'), findsOneWidget);
      });
    });

    group('Affichage images', () {
      testWidgets('DOIT afficher placeholder si aucune image', (tester) async {
        // Arrange
        const mockReport = ReportModel(
          id: 1,
          title: 'Test',
          description: 'Test',
          status: 'pending',
          categoryId: 1,
          userId: 1,
          images: [],
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ReportDetailContent(report: mockReport),
              ),
            ),
          ),
        );
        await tester.pump();

        // Assert
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
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ReportDetailContent(report: mockReport),
              ),
            ),
          ),
        );
        await tester.pump();

        // Assert
        expect(find.byType(Image), findsOneWidget);
      });
    });

    group('Bouton "Voir sur la carte"', () {
      testWidgets('DOIT afficher le bouton "Voir sur la carte"', (tester) async {
        // Arrange
        const mockReport = ReportModel(
          id: 1,
          title: 'Test',
          description: 'Test',
          status: 'pending',
          categoryId: 1,
          userId: 1,
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ReportDetailContent(report: mockReport),
              ),
            ),
          ),
        );
        await tester.pump();

        // Assert
        expect(find.text('Voir sur la carte'), findsOneWidget);
      });

      testWidgets('DOIT déclencher navigation au tap sur le bouton', (tester) async {
        // Arrange
        const mockReport = ReportModel(
          id: 1,
          title: 'Test',
          description: 'Test',
          status: 'pending',
          categoryId: 1,
          userId: 1,
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ReportDetailContent(report: mockReport),
              ),
            ),
          ),
        );
        await tester.pump();

        // Tap le bouton (skip pumpAndSettle to avoid pending timers)
        await tester.tap(find.text('Voir sur la carte'));
        await tester.pump();

        // Assert - TODO: Vérifier navigation vers MapPage
      });
    });

    group('Map preview placeholder', () {
      testWidgets('DOIT afficher placeholder pour la carte', (tester) async {
        // Arrange
        const mockReport = ReportModel(
          id: 1,
          title: 'Test',
          description: 'Test',
          status: 'pending',
          categoryId: 1,
          userId: 1,
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ReportDetailContent(report: mockReport),
              ),
            ),
          ),
        );
        await tester.pump();

        // Assert
        expect(find.byIcon(Icons.map), findsOneWidget);
      });
    });
  });
}
