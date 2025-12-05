import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/features/reports/repositories/like_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'like_repository_test.mocks.dart';

@GenerateMocks([DioService, Dio])
void main() {
  late LikeRepository repository;
  late MockDioService mockDioService;
  late MockDio mockDio;

  setUp(() {
    mockDioService = MockDioService();
    mockDio = MockDio();
    repository = LikeRepository(mockDioService);

    // Setup DioService to return mockDio
    when(mockDioService.dio).thenReturn(mockDio);
  });

  group('LikeRepository - likeReport', () {
    test('devrait retourner le nombre de likes après un like réussi', () async {
      // Arrange
      const reportId = 1;
      const expectedLikesCount = 5;

      final likeResponse = Response(
        data: {
          'success': true,
          'message': 'Report liked successfully',
          'data': {'id': 1, 'user_id': 1, 'report_id': reportId},
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/reports/$reportId/likes'),
      );

      final reportResponse = Response(
        data: {
          'success': true,
          'data': {
            'id': reportId,
            'title': 'Test Report',
            'likes_count': expectedLikesCount,
          },
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/reports/$reportId'),
      );

      when(mockDio.post('/reports/$reportId/likes'))
          .thenAnswer((_) async => likeResponse);

      when(mockDio.get(
        '/reports/$reportId',
        queryParameters: {'include': 'user,category,images'},
      )).thenAnswer((_) async => reportResponse);

      // Act
      final result = await repository.likeReport(reportId);

      // Assert
      expect(result, expectedLikesCount);
      verify(mockDio.post('/reports/$reportId/likes')).called(1);
      verify(mockDio.get(
        '/reports/$reportId',
        queryParameters: {'include': 'user,category,images'},
      )).called(1);
    });

    test('devrait retourner 0 si likes_count est null', () async {
      // Arrange
      const reportId = 1;

      final likeResponse = Response(
        data: {'success': true, 'message': 'Liked'},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/reports/$reportId/likes'),
      );

      final reportResponse = Response(
        data: {
          'success': true,
          'data': {
            'id': reportId,
            'title': 'Test Report',
            'likes_count': null, // null likes_count
          },
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/reports/$reportId'),
      );

      when(mockDio.post('/reports/$reportId/likes'))
          .thenAnswer((_) async => likeResponse);

      when(mockDio.get(
        '/reports/$reportId',
        queryParameters: {'include': 'user,category,images'},
      )).thenAnswer((_) async => reportResponse);

      // Act
      final result = await repository.likeReport(reportId);

      // Assert
      expect(result, 0);
    });

    test('devrait lancer une exception si success est false', () async {
      // Arrange
      const reportId = 1;

      final response = Response(
        data: {
          'success': false,
          'message': 'Vous avez déjà liké ce signalement',
        },
        statusCode: 409,
        requestOptions: RequestOptions(path: '/reports/$reportId/likes'),
      );

      when(mockDio.post('/reports/$reportId/likes'))
          .thenAnswer((_) async => response);

      // Act & Assert
      expect(
        () => repository.likeReport(reportId),
        throwsA(isA<Exception>()),
      );
    });

    test('devrait lancer une exception en cas d\'erreur réseau', () async {
      // Arrange
      const reportId = 1;

      when(mockDio.post('/reports/$reportId/likes')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/reports/$reportId/likes'),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      // Act & Assert
      expect(
        () => repository.likeReport(reportId),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('LikeRepository - unlikeReport', () {
    test('devrait retourner le nombre de likes après un unlike réussi',
        () async {
      // Arrange
      const reportId = 1;
      const expectedLikesCount = 3;

      final unlikeResponse = Response(
        data: {
          'success': true,
          'message': 'Report unliked successfully',
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/reports/$reportId/likes'),
      );

      final reportResponse = Response(
        data: {
          'success': true,
          'data': {
            'id': reportId,
            'title': 'Test Report',
            'likes_count': expectedLikesCount,
          },
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/reports/$reportId'),
      );

      when(mockDio.delete('/reports/$reportId/likes'))
          .thenAnswer((_) async => unlikeResponse);

      when(mockDio.get(
        '/reports/$reportId',
        queryParameters: {'include': 'user,category,images'},
      )).thenAnswer((_) async => reportResponse);

      // Act
      final result = await repository.unlikeReport(reportId);

      // Assert
      expect(result, expectedLikesCount);
      verify(mockDio.delete('/reports/$reportId/likes')).called(1);
      verify(mockDio.get(
        '/reports/$reportId',
        queryParameters: {'include': 'user,category,images'},
      )).called(1);
    });

    test('devrait lancer une exception si success est false', () async {
      // Arrange
      const reportId = 1;

      final response = Response(
        data: {
          'success': false,
          'message': 'Vous n\'avez pas liké ce signalement',
        },
        statusCode: 409,
        requestOptions: RequestOptions(path: '/reports/$reportId/likes'),
      );

      when(mockDio.delete('/reports/$reportId/likes'))
          .thenAnswer((_) async => response);

      // Act & Assert
      expect(
        () => repository.unlikeReport(reportId),
        throwsA(isA<Exception>()),
      );
    });

    test('devrait lancer une exception en cas d\'erreur réseau', () async {
      // Arrange
      const reportId = 1;

      when(mockDio.delete('/reports/$reportId/likes')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/reports/$reportId/likes'),
          type: DioExceptionType.connectionError,
        ),
      );

      // Act & Assert
      expect(
        () => repository.unlikeReport(reportId),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('LikeRepository - toggleLike', () {
    test('devrait liker si currentlyLiked est false', () async {
      // Arrange
      const reportId = 1;
      const currentlyLiked = false;
      const expectedLikesCount = 5;

      final likeResponse = Response(
        data: {'success': true, 'message': 'Liked'},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/reports/$reportId/likes'),
      );

      final reportResponse = Response(
        data: {
          'success': true,
          'data': {
            'id': reportId,
            'likes_count': expectedLikesCount,
          },
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/reports/$reportId'),
      );

      when(mockDio.post('/reports/$reportId/likes'))
          .thenAnswer((_) async => likeResponse);

      when(mockDio.get(
        '/reports/$reportId',
        queryParameters: {'include': 'user,category,images'},
      )).thenAnswer((_) async => reportResponse);

      // Act
      final result = await repository.toggleLike(reportId, currentlyLiked);

      // Assert
      expect(result['likes_count'], expectedLikesCount);
      expect(result['is_liked'], true);
      verify(mockDio.post('/reports/$reportId/likes')).called(1);
      verifyNever(mockDio.delete('/reports/$reportId/likes'));
    });

    test('devrait unliker si currentlyLiked est true', () async {
      // Arrange
      const reportId = 1;
      const currentlyLiked = true;
      const expectedLikesCount = 3;

      final unlikeResponse = Response(
        data: {'success': true, 'message': 'Unliked'},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/reports/$reportId/likes'),
      );

      final reportResponse = Response(
        data: {
          'success': true,
          'data': {
            'id': reportId,
            'likes_count': expectedLikesCount,
          },
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/reports/$reportId'),
      );

      when(mockDio.delete('/reports/$reportId/likes'))
          .thenAnswer((_) async => unlikeResponse);

      when(mockDio.get(
        '/reports/$reportId',
        queryParameters: {'include': 'user,category,images'},
      )).thenAnswer((_) async => reportResponse);

      // Act
      final result = await repository.toggleLike(reportId, currentlyLiked);

      // Assert
      expect(result['likes_count'], expectedLikesCount);
      expect(result['is_liked'], false);
      verify(mockDio.delete('/reports/$reportId/likes')).called(1);
      verifyNever(mockDio.post('/reports/$reportId/likes'));
    });

    test('devrait propager l\'exception en cas d\'erreur', () async {
      // Arrange
      const reportId = 1;
      const currentlyLiked = false;

      when(mockDio.post('/reports/$reportId/likes')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/reports/$reportId/likes'),
          type: DioExceptionType.badResponse,
        ),
      );

      // Act & Assert
      expect(
        () => repository.toggleLike(reportId, currentlyLiked),
        throwsA(isA<Exception>()),
      );
    });
  });
}
