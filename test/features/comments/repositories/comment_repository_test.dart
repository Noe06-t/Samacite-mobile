import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mobile_samacite/core/models/comment_model.dart';
import 'package:mobile_samacite/features/comments/repositories/comment_repository.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';

// Mock classes
class MockDioService extends Mock implements DioService {}
class MockDio extends Mock implements Dio {}

void main() {
  group('CommentRepository - Tests TDD Phase 4', () {
    late CommentRepository repository;
    late MockDioService mockDioService;
    late MockDio mockDio;

    setUp(() {
      mockDioService = MockDioService();
      mockDio = MockDio();
      repository = CommentRepository(mockDioService);
      
      // Configure le mock pour retourner mockDio quand on appelle .dio
      when(mockDioService.dio).thenReturn(mockDio);
    });

    group('getComments', () {
      test('devrait récupérer la liste des commentaires avec succès', () async {
        // Arrange
        final int reportId = 1;
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/reports/$reportId/comments'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'data': [
                {
                  'id': 1,
                  'content': 'Premier commentaire',
                  'report_id': reportId,
                  'user_id': 10,
                  'user': {
                    'id': 10,
                    'nom': 'Doe',
                    'prenom': 'John',
                    'email': 'john@example.com',
                    'telephone': '+221771234567',
                  },
                  'created_at': '2025-11-23T10:00:00.000000Z',
                  'updated_at': '2025-11-23T10:00:00.000000Z',
                },
                {
                  'id': 2,
                  'content': 'Deuxième commentaire',
                  'report_id': reportId,
                  'user_id': 11,
                  'user': {
                    'id': 11,
                    'nom': 'Smith',
                    'prenom': 'Jane',
                    'email': null,
                    'telephone': '+221772234567',
                  },
                  'created_at': '2025-11-23T11:00:00.000000Z',
                  'updated_at': '2025-11-23T11:00:00.000000Z',
                },
              ],
              'current_page': 1,
              'last_page': 1,
              'per_page': 10,
              'total': 2,
            },
          },
        );

        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getComments(reportId);

        // Assert
        expect(result['data'], isA<List<CommentModel>>());
        expect((result['data'] as List).length, 2);
        expect(result['current_page'], 1);
        expect(result['last_page'], 1);
        expect(result['total'], 2);
        
        final comments = result['data'] as List<CommentModel>;
        expect(comments[0].content, 'Premier commentaire');
        expect(comments[0].userId, 10);
        expect(comments[0].user?.prenom, 'John');
        
        verify(mockDio.get(
          '/reports/$reportId/comments',
          queryParameters: {
            'page': 1,
            'per_page': 10,
            'include': 'user',
          },
        )).called(1);
      });

      test('devrait gérer la pagination correctement', () async {
        // Arrange
        final int reportId = 1;
        final int page = 2;
        final int perPage = 5;
        
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/reports/$reportId/comments'),
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'data': [],
              'current_page': page,
              'last_page': 3,
              'per_page': perPage,
              'total': 15,
            },
          },
        );

        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getComments(
          reportId,
          page: page,
          perPage: perPage,
        );

        // Assert
        expect(result['current_page'], page);
        expect(result['last_page'], 3);
        expect(result['total'], 15);
        
        verify(mockDio.get(
          '/reports/$reportId/comments',
          queryParameters: {
            'page': page,
            'per_page': perPage,
            'include': 'user',
          },
        )).called(1);
      });

      test('devrait lancer une exception si success=false', () async {
        // Arrange
        final int reportId = 1;
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/reports/$reportId/comments'),
          statusCode: 200,
          data: {
            'success': false,
            'message': 'Signalement non trouvé',
          },
        );

        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.getComments(reportId),
          throwsA(isA<DioException>()),
        );
      });

      test('devrait gérer les erreurs réseau', () async {
        // Arrange
        final int reportId = 1;
        
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/reports/$reportId/comments'),
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timeout',
        ));

        // Act & Assert
        expect(
          () => repository.getComments(reportId),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('createComment', () {
      test('devrait créer un commentaire avec succès', () async {
        // Arrange
        final int reportId = 1;
        final String content = 'Mon nouveau commentaire';
        
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/reports/$reportId/comments'),
          statusCode: 201,
          data: {
            'success': true,
            'data': {
              'id': 3,
              'content': content,
              'report_id': reportId,
              'user_id': 10,
              'user': {
                'id': 10,
                'nom': 'Doe',
                'prenom': 'John',
                'email': 'john@example.com',
                'telephone': '+221771234567',
              },
              'created_at': '2025-11-23T12:00:00.000000Z',
              'updated_at': '2025-11-23T12:00:00.000000Z',
            },
          },
        );

        when(mockDio.post(
          any,
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.createComment(reportId, content);

        // Assert
        expect(result, isA<CommentModel>());
        expect(result.id, 3);
        expect(result.content, content);
        expect(result.userId, 10);
        expect(result.user?.prenom, 'John');
        
        verify(mockDio.post(
          '/reports/$reportId/comments',
          data: {'content': content},
          queryParameters: {'include': 'user'},
        )).called(1);
      });

      test('devrait rejeter un commentaire vide', () async {
        // Arrange
        final int reportId = 1;
        final String emptyContent = '   '; // Espaces

        // Act & Assert
        expect(
          () => repository.createComment(reportId, emptyContent),
          throwsA(isA<DioException>()),
        );
        
        // Vérifier qu'aucun appel API n'a été fait
        verifyNever(mockDio.post(any, data: anyNamed('data')));
      });

      test('devrait rejeter un commentaire trop long (>500 caractères)', () async {
        // Arrange
        final int reportId = 1;
        final String longContent = 'a' * 501; // 501 caractères

        // Act & Assert
        expect(
          () => repository.createComment(reportId, longContent),
          throwsA(isA<DioException>()),
        );
        
        // Vérifier qu'aucun appel API n'a été fait
        verifyNever(mockDio.post(any, data: anyNamed('data')));
      });

      test('devrait accepter un commentaire de 500 caractères exactement', () async {
        // Arrange
        final int reportId = 1;
        final String maxContent = 'a' * 500;
        
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/reports/$reportId/comments'),
          statusCode: 201,
          data: {
            'success': true,
            'data': {
              'id': 4,
              'content': maxContent,
              'report_id': reportId,
              'user_id': 10,
              'created_at': '2025-11-23T12:00:00.000000Z',
            },
          },
        );

        when(mockDio.post(
          any,
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.createComment(reportId, maxContent);

        // Assert
        expect(result.content, maxContent);
        verify(mockDio.post(any, data: anyNamed('data'), queryParameters: anyNamed('queryParameters'))).called(1);
      });

      test('devrait supprimer les espaces avant/après le commentaire', () async {
        // Arrange
        final int reportId = 1;
        final String contentWithSpaces = '  Mon commentaire  ';
        final String trimmedContent = 'Mon commentaire';
        
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/reports/$reportId/comments'),
          statusCode: 201,
          data: {
            'success': true,
            'data': {
              'id': 5,
              'content': trimmedContent,
              'report_id': reportId,
              'user_id': 10,
              'created_at': '2025-11-23T12:00:00.000000Z',
            },
          },
        );

        when(mockDio.post(
          any,
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        await repository.createComment(reportId, contentWithSpaces);

        // Assert
        verify(mockDio.post(
          any,
          data: {'content': trimmedContent},
          queryParameters: anyNamed('queryParameters'),
        )).called(1);
      });

      test('devrait gérer les erreurs serveur', () async {
        // Arrange
        final int reportId = 1;
        final String content = 'Mon commentaire';
        
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/reports/$reportId/comments'),
          statusCode: 200,
          data: {
            'success': false,
            'message': 'Erreur serveur',
          },
        );

        when(mockDio.post(
          any,
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.createComment(reportId, content),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('deleteComment', () {
      test('devrait supprimer un commentaire avec succès', () async {
        // Arrange
        final int commentId = 1;
        
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/api/comments/$commentId'),
          statusCode: 200,
          data: {
            'success': true,
            'message': 'Commentaire supprimé',
          },
        );

        when(mockDio.delete(any)).thenAnswer((_) async => mockResponse);

        // Act
        await repository.deleteComment(commentId);

        // Assert
        verify(mockDio.delete('/api/comments/$commentId')).called(1);
      });

      test('devrait lancer une exception si success=false', () async {
        // Arrange
        final int commentId = 1;
        
        final mockResponse = Response(
          requestOptions: RequestOptions(path: '/api/comments/$commentId'),
          statusCode: 200,
          data: {
            'success': false,
            'message': 'Non autorisé',
          },
        );

        when(mockDio.delete(any)).thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => repository.deleteComment(commentId),
          throwsA(isA<DioException>()),
        );
      });

      test('devrait gérer les erreurs 403 (non autorisé)', () async {
        // Arrange
        final int commentId = 1;
        
        when(mockDio.delete(any)).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/comments/$commentId'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/api/comments/$commentId'),
            statusCode: 403,
            data: {
              'message': 'Vous ne pouvez supprimer que vos propres commentaires',
            },
          ),
        ));

        // Act & Assert
        expect(
          () => repository.deleteComment(commentId),
          throwsA(isA<DioException>()),
        );
      });

      test('devrait gérer les erreurs 404 (commentaire non trouvé)', () async {
        // Arrange
        final int commentId = 999;
        
        when(mockDio.delete(any)).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/api/comments/$commentId'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/api/comments/$commentId'),
            statusCode: 404,
            data: {
              'message': 'Commentaire non trouvé',
            },
          ),
        ));

        // Act & Assert
        expect(
          () => repository.deleteComment(commentId),
          throwsA(isA<DioException>()),
        );
      });
    });
  });
}
