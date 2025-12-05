import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_samacite/core/models/category_model.dart';
import 'package:mobile_samacite/core/models/category_model_hive.dart';
import 'package:mobile_samacite/features/reports/repositories/category_repository.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'category_repository_test.mocks.dart';

// Mock PathProvider
class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => './';
}

@GenerateMocks([DioService, Dio])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() async {
    PathProviderPlatform.instance = FakePathProviderPlatform();
    Hive.init('./');
    Hive.registerAdapter(CategoryModelHiveAdapter());
  });
  
  tearDownAll(() async {
    await Hive.close();
  });
  
  group('CategoryRepository Tests (TDD Phase 2)', () {
    late MockDioService mockDioService;
    late MockDio mockDio;
    late CategoryRepository repository;

    setUp(() {
      mockDioService = MockDioService();
      mockDio = MockDio();
      when(mockDioService.dio).thenReturn(mockDio);
      repository = CategoryRepository(mockDioService);
    });

    group('getCategories() - Récupération des catégories', () {
      test('DOIT récupérer la liste complète des catégories', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'data': [
            {
              'id': 1,
              'name': 'Voirie',
              'description': 'Problèmes de routes',
              'icon': 'road',
            },
            {
              'id': 2,
              'name': 'Éclairage',
              'description': 'Lampadaires défectueux',
              'icon': 'lightbulb',
            },
            {
              'id': 3,
              'name': 'Propreté',
              'description': 'Déchets et salubrité',
              'icon': 'cleaning',
            }
          ]
        };

        when(mockDio.get('/categories'))
            .thenAnswer((_) async => Response(
                  data: mockResponse,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/categories'),
                ));

        // Act
        final result = await repository.getCategories();

        // Assert
        expect(result, isA<List<CategoryModel>>());
        expect(result.length, 3);
        expect(result.first.name, 'Voirie');
        expect(result[1].name, 'Éclairage');
        verify(mockDio.get('/categories')).called(1);
      });

      test('DOIT retourner liste vide si aucune catégorie', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'data': []
        };

        when(mockDio.get('/categories'))
            .thenAnswer((_) async => Response(
                  data: mockResponse,
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/categories'),
                ));

        // Act
        final result = await repository.getCategories();

        // Assert
        expect(result, isEmpty);
      });

      test('DOIT gérer erreur réseau', () async {
        // Arrange
        when(mockDio.get('/categories'))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/categories'),
          type: DioExceptionType.connectionTimeout,
        ));

        // Act & Assert
        expect(
          () => repository.getCategories(),
          throwsA(isA<DioException>()),
        );
      });

      test('DOIT gérer erreur serveur (500)', () async {
        // Arrange
        when(mockDio.get('/categories'))
            .thenThrow(DioException(
          requestOptions: RequestOptions(path: '/categories'),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 500,
            data: {'success': false, 'message': 'Erreur serveur'},
            requestOptions: RequestOptions(path: '/categories'),
          ),
        ));

        // Act & Assert
        expect(
          () => repository.getCategories(),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('Cache des catégories', () {
      test('DOIT mettre en cache les catégories après récupération', () async {
        // TODO: Implémenter test de cache
        // Vérifier que les catégories sont stockées localement
        // et réutilisées lors des prochains appels
      });

      test('DOIT utiliser le cache si disponible', () async {
        // TODO: Implémenter test de lecture cache
        // Vérifier qu'aucune requête réseau n'est faite si cache valide
      });

      test('DOIT invalider le cache après expiration (TTL)', () async {
        // TODO: Implémenter test expiration cache
        // Vérifier qu'une nouvelle requête est faite après expiration
      });
    });
  });
}
