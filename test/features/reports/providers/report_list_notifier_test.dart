import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_samacite/features/reports/providers/report_list_notifier.dart';
import 'package:mobile_samacite/features/reports/providers/report_list_state.dart';
import 'package:mobile_samacite/features/reports/repositories/report_repository.dart';
import 'package:mobile_samacite/core/models/report_model.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'report_list_notifier_test.mocks.dart';

@GenerateMocks([ReportRepository])
void main() {
  group('ReportListNotifier - Tests TDD Phase 3', () {
    late MockReportRepository mockRepository;
    late ReportListNotifier notifier;

    setUp(() {
      mockRepository = MockReportRepository();
      notifier = ReportListNotifier(mockRepository);
    });

    group('État initial', () {
      test('DOIT démarrer avec un état initial vide', () {
        // Assert
        expect(notifier.state.reports, isEmpty);
        expect(notifier.state.isLoading, false);
        expect(notifier.state.hasMore, true);
        expect(notifier.state.currentPage, 1);
        expect(notifier.state.errorMessage, isNull);
      });
    });

    group('loadReports() - Chargement initial', () {
      test('DOIT charger la première page avec succès', () async {
        // Arrange
        final mockReports = [
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

        final mockResponse = {
          'data': mockReports,
          'meta': {
            'current_page': 1,
            'last_page': 5,
            'total': 50,
            'per_page': 15,
          }
        };

        when(mockRepository.getReports(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
          includeRelations: anyNamed('includeRelations'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        await notifier.loadReports();

        // Assert
        expect(notifier.state.reports, hasLength(2));
        expect(notifier.state.isLoading, false);
        expect(notifier.state.hasMore, true);
        expect(notifier.state.currentPage, 1);
        expect(notifier.state.errorMessage, isNull);
      });

      test('DOIT passer en état loading pendant le chargement', () async {
        // Arrange
        final mockResponse = {
          'data': [],
          'meta': {'current_page': 1, 'last_page': 1}
        };

        when(mockRepository.getReports(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
          includeRelations: anyNamed('includeRelations'),
        )).thenAnswer((_) async {
          // Vérifier l'état loading pendant l'appel
          expect(notifier.state.isLoading, true);
          return mockResponse;
        });

        // Act
        await notifier.loadReports();

        // Assert
        expect(notifier.state.isLoading, false);
      });

      test('DOIT gérer les erreurs réseau', () async {
        // Arrange
        when(mockRepository.getReports(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
          includeRelations: anyNamed('includeRelations'),
        )).thenThrow(Exception('Erreur réseau'));

        // Act
        await notifier.loadReports();

        // Assert
        expect(notifier.state.errorMessage, isNotNull);
        expect(notifier.state.isLoading, false);
        expect(notifier.state.reports, isEmpty);
      });

      test('DOIT détecter la dernière page (hasMore=false)', () async {
        // Arrange
        final mockResponse = {
          'data': [
            const ReportModel(
              id: 1,
              title: 'Test',
              description: 'Test',
              status: 'pending',
              categoryId: 1,
              userId: 1,
            )
          ],
          'meta': {
            'current_page': 3,
            'last_page': 3,
            'total': 30,
            'per_page': 15,
          }
        };

        when(mockRepository.getReports(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
          includeRelations: anyNamed('includeRelations'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        await notifier.loadReports();

        // Assert
        expect(notifier.state.hasMore, false);
      });
    });

    group('loadMoreReports() - Pagination', () {
      test('DOIT charger la page suivante', () async {
        // Arrange - Charger page 1
        final page1Response = {
          'data': [
            const ReportModel(
              id: 1,
              title: 'Signalement 1',
              description: 'Desc 1',
              status: 'pending',
              categoryId: 1,
              userId: 1,
            )
          ],
          'meta': {
            'current_page': 1,
            'last_page': 3,
            'total': 30,
            'per_page': 15,
          }
        };

        when(mockRepository.getReports(
          page: 1,
          perPage: anyNamed('perPage'),
          includeRelations: anyNamed('includeRelations'),
        )).thenAnswer((_) async => page1Response);

        await notifier.loadReports();

        // Arrange - Préparer page 2
        final page2Response = {
          'data': [
            const ReportModel(
              id: 2,
              title: 'Signalement 2',
              description: 'Desc 2',
              status: 'resolved',
              categoryId: 1,
              userId: 1,
            )
          ],
          'meta': {
            'current_page': 2,
            'last_page': 3,
            'total': 30,
            'per_page': 15,
          }
        };

        when(mockRepository.getReports(
          page: 2,
          perPage: anyNamed('perPage'),
          includeRelations: anyNamed('includeRelations'),
        )).thenAnswer((_) async => page2Response);

        // Act
        await notifier.loadMoreReports();

        // Assert
        expect(notifier.state.reports, hasLength(2));
        expect(notifier.state.currentPage, 2);
        expect(notifier.state.hasMore, true);
      });

      test('NE DOIT PAS charger si déjà en cours de chargement', () async {
        // Arrange
        when(mockRepository.getReports(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
          includeRelations: anyNamed('includeRelations'),
        )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return {
            'data': [],
            'meta': {'current_page': 1, 'last_page': 1}
          };
        });

        // Act - Appeler deux fois rapidement
        notifier.loadReports();
        await notifier.loadReports();

        // Assert - Vérifier qu'une seule requête a été faite
        verify(mockRepository.getReports(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
          includeRelations: anyNamed('includeRelations'),
        )).called(1);
      });

      test('NE DOIT PAS charger si hasMore=false', () async {
        // Arrange - État initial avec hasMore=false
        notifier.state = notifier.state.copyWith(hasMore: false);

        // Act
        await notifier.loadMoreReports();

        // Assert
        verifyNever(mockRepository.getReports(
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
          includeRelations: anyNamed('includeRelations'),
        ));
      });
    });

    group('refresh() - Rafraîchissement', () {
      test('DOIT réinitialiser et recharger depuis la page 1', () async {
        // Arrange - État initial avec page 3
        notifier.state = notifier.state.copyWith(
          currentPage: 3,
          reports: [
            const ReportModel(
              id: 10,
              title: 'Old',
              description: 'Old',
              status: 'pending',
              categoryId: 1,
              userId: 1,
            )
          ],
        );

        final refreshResponse = {
          'data': [
            const ReportModel(
              id: 1,
              title: 'Nouveau',
              description: 'Nouveau',
              status: 'pending',
              categoryId: 1,
              userId: 1,
            )
          ],
          'meta': {
            'current_page': 1,
            'last_page': 5,
            'total': 50,
            'per_page': 15,
          }
        };

        when(mockRepository.getReports(
          page: 1,
          perPage: anyNamed('perPage'),
          includeRelations: anyNamed('includeRelations'),
        )).thenAnswer((_) async => refreshResponse);

        // Act
        await notifier.refresh();

        // Assert
        expect(notifier.state.currentPage, 1);
        expect(notifier.state.reports, hasLength(1));
        expect(notifier.state.reports.first.title, 'Nouveau');
        expect(notifier.state.hasMore, true);
      });

      test('DOIT effacer les erreurs précédentes lors du refresh', () async {
        // Arrange
        notifier.state = notifier.state.copyWith(
          errorMessage: 'Erreur précédente',
        );

        final refreshResponse = {
          'data': [],
          'meta': {'current_page': 1, 'last_page': 1}
        };

        when(mockRepository.getReports(
          page: 1,
          perPage: anyNamed('perPage'),
          includeRelations: anyNamed('includeRelations'),
        )).thenAnswer((_) async => refreshResponse);

        // Act
        await notifier.refresh();

        // Assert
        expect(notifier.state.errorMessage, isNull);
      });
    });
  });
}
