import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:mobile_samacite/core/models/report_model.dart';
import 'package:mobile_samacite/core/models/report_model_hive.dart';
import 'package:mobile_samacite/features/reports/repositories/report_repository.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'report_repository_test.mocks.dart';

@GenerateMocks([DioService, Dio])
void main() {
  late MockDioService mockDioService;
  late MockDio mockDio;
  late ReportRepository repository;
  late Box reportsBox;

  setUpAll(() async {
    await setUpTestHive();
    Hive.registerAdapter(ReportModelHiveAdapter());
  });

  setUp(() async {
    mockDioService = MockDioService();
    mockDio = MockDio();
    when(mockDioService.dio).thenReturn(mockDio);
    
    // Stub par défaut pour éviter MissingStubError
    when(mockDio.get(
      any,
      data: anyNamed('data'),
      queryParameters: anyNamed('queryParameters'),
      options: anyNamed('options'),
      cancelToken: anyNamed('cancelToken'),
      onReceiveProgress: anyNamed('onReceiveProgress'),
    )).thenAnswer((_) async => Response(
      data: {'success': true, 'data': {'data': [], 'meta': {}}},
      statusCode: 200,
      requestOptions: RequestOptions(path: '/reports'),
    ));
    
    repository = ReportRepository(mockDioService);
    
    // Ouvre une box Hive en mémoire pour les tests
    if (!Hive.isBoxOpen('reports_box')) {
      reportsBox = await Hive.openBox('reports_box');
    } else {
      reportsBox = Hive.box('reports_box');
    }
  });

  tearDown(() async {
    if (Hive.isBoxOpen('reports_box')) {
      await reportsBox.clear();
      await reportsBox.close();
    }
  });

  tearDownAll(() async {
    await tearDownTestHive();
  });

  group('ReportRepository Hive Cache', () {
    test('Lit depuis le cache Hive si TTL valide', () async {
      final now = DateTime.now();
      final cacheKey = 'reports_page_1_perPage_15';
      final cacheData = {
        'timestamp': now.toIso8601String(),
        'data': [
          {
            'id': 1,
            'title': 'Signalement cache',
            'description': 'Depuis cache',
            'status': 'pending',
            'category_id': 1,
            'user_id': 1,
            'images': [],
            'created_at': now.toIso8601String(),
            'likes_count': 0,
            'is_liked': false,
          }
        ],
        'meta': {
          'current_page': 1,
          'last_page': 1,
          'total': 1,
          'per_page': 15,
        }
      };
      
      // Stocke les données dans le cache avec la bonne clé
      await reportsBox.put(cacheKey, cacheData);

      final result = await repository.getReports();
      expect(result['data'], isA<List<ReportModel>>());
      expect(result['data'].first.title, 'Signalement cache');
      expect(result['source'], 'cache');
    });

    test('Fallback sur API si cache expiré', () async {
      final oldMeta = {
        'timestamp': DateTime.now().subtract(Duration(minutes: 2)).toIso8601String(),
        'meta': {}
      };
      
      // Stocke un cache expiré
      await reportsBox.put('reports_meta', oldMeta);

      final mockResponse = {
        'success': true,
        'data': {
          'data': [
            {
              'id': 2,
              'title': 'Signalement API',
              'description': 'Depuis API',
              'status': 'pending',
              'category_id': 1,
              'user_id': 1,
            }
          ],
          'meta': {
            'current_page': 1,
            'last_page': 1,
            'total': 1,
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

      final result = await repository.getReports();
      expect(result['data'], isA<List<ReportModel>>());
      expect(result['data'].first.title, 'Signalement API');
      expect(result['source'], 'api');
    });
  });
}
