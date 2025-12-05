import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_samacite/features/reports/providers/report_list_state.dart';
import 'package:mobile_samacite/core/models/report_model.dart';

/// Tests TDD pour ReportListState (Phase 3)
/// 
/// État pour la gestion de la liste des signalements
/// avec pagination et filtrage
void main() {
  group('ReportListState - Tests TDD Phase 3', () {
    group('État initial', () {
      test('DOIT avoir un état initial vide', () {
        // Act
        final state = ReportListState.initial();

        // Assert
        expect(state.reports, isEmpty);
        expect(state.isLoading, false);
        expect(state.hasMore, true);
        expect(state.currentPage, 1);
        expect(state.errorMessage, isNull);
      });
    });

    group('Chargement', () {
      test('DOIT passer en état de chargement', () {
        // Arrange
        final state = ReportListState.initial();

        // Act
        final loadingState = state.copyWith(isLoading: true);

        // Assert
        expect(loadingState.isLoading, true);
        expect(loadingState.reports, isEmpty);
      });

      test('DOIT conserver les signalements existants pendant le chargement', () {
        // Arrange
        final mockReports = [
          const ReportModel(
            id: 1,
            title: 'Test',
            description: 'Test',
            status: 'pending',
            categoryId: 1,
            userId: 1,
          )
        ];
        final state = ReportListState.initial().copyWith(reports: mockReports);

        // Act
        final loadingState = state.copyWith(isLoading: true);

        // Assert
        expect(loadingState.isLoading, true);
        expect(loadingState.reports.length, 1);
      });
    });

    group('Ajout de signalements', () {
      test('DOIT ajouter des signalements à la liste', () {
        // Arrange
        final state = ReportListState.initial();
        final newReports = [
          const ReportModel(
            id: 1,
            title: 'Signalement 1',
            description: 'Description 1',
            status: 'pending',
            categoryId: 1,
            userId: 1,
          ),
          const ReportModel(
            id: 2,
            title: 'Signalement 2',
            description: 'Description 2',
            status: 'in_progress',
            categoryId: 2,
            userId: 1,
          ),
        ];

        // Act
        final updatedState = state.copyWith(
          reports: newReports,
          isLoading: false,
          currentPage: 1,
        );

        // Assert
        expect(updatedState.reports.length, 2);
        expect(updatedState.reports.first.title, 'Signalement 1');
        expect(updatedState.isLoading, false);
      });

      test('DOIT ajouter des signalements à la liste existante (pagination)', () {
        // Arrange
        final existingReports = [
          const ReportModel(
            id: 1,
            title: 'Signalement 1',
            description: 'Description 1',
            status: 'pending',
            categoryId: 1,
            userId: 1,
          ),
        ];
        final state = ReportListState.initial().copyWith(
          reports: existingReports,
          currentPage: 1,
        );

        final newReports = [
          const ReportModel(
            id: 2,
            title: 'Signalement 2',
            description: 'Description 2',
            status: 'pending',
            categoryId: 1,
            userId: 1,
          ),
        ];

        // Act
        final updatedState = state.copyWith(
          reports: [...state.reports, ...newReports],
          currentPage: 2,
        );

        // Assert
        expect(updatedState.reports.length, 2);
        expect(updatedState.currentPage, 2);
      });
    });

    group('Pagination', () {
      test('DOIT incrémenter la page courante', () {
        // Arrange
        final state = ReportListState.initial();

        // Act
        final updatedState = state.copyWith(currentPage: 2);

        // Assert
        expect(updatedState.currentPage, 2);
      });

      test('DOIT indiquer quand il n\'y a plus de données', () {
        // Arrange
        final state = ReportListState.initial();

        // Act
        final updatedState = state.copyWith(hasMore: false);

        // Assert
        expect(updatedState.hasMore, false);
      });
    });

    group('Gestion des erreurs', () {
      test('DOIT stocker le message d\'erreur', () {
        // Arrange
        final state = ReportListState.initial();
        const errorMessage = 'Erreur réseau';

        // Act
        final errorState = state.copyWith(
          errorMessage: errorMessage,
          isLoading: false,
        );

        // Assert
        expect(errorState.errorMessage, errorMessage);
        expect(errorState.isLoading, false);
      });

      test('DOIT effacer l\'erreur lors du rechargement', () {
        // Arrange
        final state = ReportListState.initial().copyWith(
          errorMessage: 'Erreur',
        );

        // Act
        final reloadState = state.copyWith(
          errorMessage: null,
          isLoading: true,
        );

        // Assert
        expect(reloadState.errorMessage, isNull);
        expect(reloadState.isLoading, true);
      });
    });

    group('Rafraîchissement', () {
      test('DOIT réinitialiser la pagination lors du refresh', () {
        // Arrange
        final state = ReportListState.initial().copyWith(
          currentPage: 3,
          hasMore: false,
          reports: [
            const ReportModel(
              id: 1,
              title: 'Test',
              description: 'Test',
              status: 'pending',
              categoryId: 1,
              userId: 1,
            )
          ],
        );

        // Act
        final refreshState = state.copyWith(
          currentPage: 1,
          hasMore: true,
          reports: [],
        );

        // Assert
        expect(refreshState.currentPage, 1);
        expect(refreshState.hasMore, true);
        expect(refreshState.reports, isEmpty);
      });
    });
  });
}
