import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_samacite/core/models/category_model.dart';
import 'package:mobile_samacite/core/models/report_model.dart';
import 'package:mobile_samacite/core/models/location_model.dart';
import 'package:mobile_samacite/features/reports/repositories/report_repository.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';

import 'report_repository_test.mocks.dart';

@GenerateMocks([DioService, Dio])
void main() {
  group('ReportRepository Tests (TDD Phase 2)', () {
    late MockDioService mockDioService;
    late MockDio mockDio;
    late ReportRepository repository;

    setUp(() {
      mockDioService = MockDioService();
      mockDio = MockDio();
      when(mockDioService.dio).thenReturn(mockDio);
      repository = ReportRepository(mockDioService);
    });

    group('create() - Création de signalement', () {
      test('DOIT créer un signalement avec données valides', () async {
        // Arrange
        final reportData = {
          'title': 'Route endommagée',
          'description': 'Nids de poule dangereux',
          'category_id': 1,
          'latitude': 14.6937,
          'longitude': -17.4441,
        };

        final mockResponse = {
          'success': true,
          'message': 'Signalement créé avec succès',
          'data': {
            'id': 1,
            'title': 'Route endommagée',
            'description': 'Nids de poule dangereux',
            'status': 'pending',
            'category_id': 1,
            'user_id': 1,
            'created_at': '2025-11-22T10:00:00Z',
          }
        };

        when(mockDio.post('/reports', data: anyNamed('data')))
            .thenAnswer((_) async => Response(
                  data: mockResponse,
                  statusCode: 201,
                  requestOptions: RequestOptions(path: '/reports'),
                ));

        // Act
        final result = await repository.create(reportData);

        // Assert
        expect(result, isA<ReportModel>());
        expect(result.id, 1);
        expect(result.title, 'Route endommagée');
        expect(result.status, 'pending');
        verify(mockDio.post('/reports', data: reportData)).called(1);
      });

      test('DOIT échouer avec données invalides (titre manquant)', () async {
        // Arrange
        final invalidData = {
          'description': 'Description sans titre',
          'category_id': 1,
        };

        // Act & Assert
        expect(
          () => repository.create(invalidData),
          throwsA(isA<Exception>()),
        );
      });

      test('DOIT gérer erreur réseau (timeout)', () async {
        // Arrange
        final reportData = {
          'title': 'Test',
          'description': 'Test',
          'category_id': 1,
        };

        when(mockDio.post('/reports', data: anyNamed('data')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/reports'),
          type: DioExceptionType.connectionTimeout,
        ));

        // Act & Assert
        expect(
          () => repository.create(reportData),
          throwsA(isA<DioException>()),
        );
      });

      test('DOIT gérer erreur serveur (422 validation)', () async {
        // Arrange
        final reportData = {
          'title': '',
          'description': 'Test',
          'category_id': 1,
        };

        when(mockDio.post('/reports', data: anyNamed('data')))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/reports'),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 422,
            data: {
              'success': false,
              'message': 'Le titre est requis',
            },
            requestOptions: RequestOptions(path: '/reports'),
          ),
        ));

        // Act & Assert
        expect(
          () => repository.create(reportData),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('uploadImages() - Upload des images', () {
      test('DOIT uploader 1 image avec succès', () async {}, skip: 'Nécessite ImageService mocké - à implémenter dans prochaine tâche');

      test('DOIT uploader 5 images maximum', () async {}, skip: 'Nécessite ImageService mocké - à implémenter dans prochaine tâche');

      test('DOIT échouer si plus de 5 images', () async {
        // Arrange
        const reportId = 1;
        final imagePaths = List.generate(6, (i) => '/path/image$i.jpg');

        // Act & Assert
        expect(
          () => repository.uploadImages(reportId, imagePaths),
          throwsA(isA<Exception>()),
        );
      });

      test('DOIT compresser les images avant upload', () async {}, skip: 'Nécessite ImageService mocké - à implémenter dans prochaine tâche');
    });

    group('getReports() - Récupération liste signalements', () {
      test('DOIT récupérer la liste paginée de signalements', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'data': {
            'data': [
              {
                'id': 1,
                'title': 'Signalement 1',
                'description': 'Description 1',
                'status': 'pending',
                'category_id': 1,
                'user_id': 1,
              },
              {
                'id': 2,
                'title': 'Signalement 2',
                'description': 'Description 2',
                'status': 'in_progress',
                'category_id': 2,
                'user_id': 1,
              }
            ],
            'meta': {
              'current_page': 1,
              'last_page': 5,
              'total': 10,
              'per_page': 15,
            }
          }
        };

        when(mockDio.get('/reports', queryParameters: anyNamed('queryParameters')))
            .thenAnswer((_) async => Response(
                  data: mockResponse,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/reports'),
                ));

        // Act
        final result = await repository.getReports();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['data'], isA<List<ReportModel>>());
        final reports = result['data'] as List<ReportModel>;
        expect(reports.length, 2);
        expect(reports.first.title, 'Signalement 1');
        expect(result['meta'], isNotEmpty);
        expect(result['meta']['current_page'], 1);
      });

      test('DOIT inclure les relations (user, images, category)', () async {
        // TODO: Implémenter test avec eager-loading
        // Vérifier que les relations sont bien chargées
      });
    });
  });
}
