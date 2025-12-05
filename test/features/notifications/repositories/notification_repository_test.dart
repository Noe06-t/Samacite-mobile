import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/features/notifications/models/notification_model.dart';
import 'package:mobile_samacite/features/notifications/repositories/notification_repository.dart';

@GenerateMocks([DioService, Dio])
import 'notification_repository_test.mocks.dart';

void main() {
  late NotificationRepository repository;
  late MockDioService mockDioService;
  late MockDio mockDio;

  setUp(() {
    mockDioService = MockDioService();
    mockDio = MockDio();
    when(mockDioService.dio).thenReturn(mockDio);
    repository = NotificationRepository(mockDioService);
  });

  group('NotificationRepository -', () {
    group('getNotifications', () {
      test('DOIT retourner liste de notifications avec succès', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'data': [
            {
              'id': 'notif-1',
              'type': 'App\\Notifications\\ReportCreatedNotification',
              'data': {
                'message': 'Nouveau signalement créé',
                'report_id': 5,
              },
              'read_at': null,
              'created_at': '2025-11-25T10:00:00.000000Z',
            },
            {
              'id': 'notif-2',
              'type': 'App\\Notifications\\CommentCreatedNotification',
              'data': {
                'message': 'Nouveau commentaire',
                'report_id': 3,
              },
              'read_at': '2025-11-25T11:00:00.000000Z',
              'created_at': '2025-11-25T10:30:00.000000Z',
            },
          ],
        };

        when(mockDio.get(
          '/notifications',
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: mockResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: '/notifications'),
            ));

        // Act
        final result = await repository.getNotifications();

        // Assert
        expect(result, isA<List<NotificationModel>>());
        expect(result.length, 2);
        expect(result[0].id, 'notif-1');
        expect(result[0].isUnread, true);
        expect(result[1].id, 'notif-2');
        expect(result[1].isRead, true);
        verify(mockDio.get(
          '/notifications',
          queryParameters: anyNamed('queryParameters'),
        )).called(1);
      });

      test('DOIT retourner liste vide si aucune notification', () async {
        // Arrange
        when(mockDio.get(
          '/notifications',
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: {'success': true, 'data': []},
              statusCode: 200,
              requestOptions: RequestOptions(path: '/notifications'),
            ));

        // Act
        final result = await repository.getNotifications();

        // Assert
        expect(result, isEmpty);
      });

      test('DOIT lancer exception si erreur serveur', () async {
        // Arrange
        when(mockDio.get(
          '/notifications',
          queryParameters: anyNamed('queryParameters'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/notifications'),
            response: Response(
              statusCode: 500,
              requestOptions: RequestOptions(path: '/notifications'),
            ),
          ),
        );

        // Act & Assert
        expect(
          () => repository.getNotifications(),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('getUnreadCount', () {
      test('DOIT retourner nombre de notifications non lues', () async {
        // Arrange
        when(mockDio.get('/notifications/unread-count'))
            .thenAnswer((_) async => Response(
                  data: {'success': true, 'data': {'unread_count': 5}},
                  statusCode: 200,
                  requestOptions:
                      RequestOptions(path: '/notifications/unread-count'),
                ));

        // Act
        final result = await repository.getUnreadCount();

        // Assert
        expect(result, 5);
        verify(mockDio.get('/notifications/unread-count')).called(1);
      });

      test('DOIT retourner 0 si aucune notification non lue', () async {
        // Arrange
        when(mockDio.get('/notifications/unread-count'))
            .thenAnswer((_) async => Response(
                  data: {'success': true, 'data': {'unread_count': 0}},
                  statusCode: 200,
                  requestOptions:
                      RequestOptions(path: '/notifications/unread-count'),
                ));

        // Act
        final result = await repository.getUnreadCount();

        // Assert
        expect(result, 0);
      });
    });

    group('markAsRead', () {
      test('DOIT marquer notification comme lue avec succès', () async {
        // Arrange
        const notificationId = 'notif-123';
        when(mockDio.patch('/notifications/$notificationId/read'))
            .thenAnswer((_) async => Response(
                  data: {
                    'success': true,
                    'message': 'Notification marquée comme lue'
                  },
                  statusCode: 200,
                  requestOptions: RequestOptions(
                      path: '/notifications/$notificationId/read'),
                ));

        // Act
        await repository.markAsRead(notificationId);

        // Assert
        verify(mockDio.patch('/notifications/$notificationId/read')).called(1);
      });

      test('DOIT lancer exception si notification introuvable', () async {
        // Arrange
        const notificationId = 'fake-id';
        when(mockDio.patch('/notifications/$notificationId/read')).thenThrow(
          DioException(
            requestOptions:
                RequestOptions(path: '/notifications/$notificationId/read'),
            response: Response(
              statusCode: 404,
              requestOptions:
                  RequestOptions(path: '/notifications/$notificationId/read'),
            ),
          ),
        );

        // Act & Assert
        expect(
          () => repository.markAsRead(notificationId),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('markAllAsRead', () {
      test('DOIT marquer toutes les notifications comme lues', () async {
        // Arrange
        when(mockDio.patch('/notifications/mark-all-read'))
            .thenAnswer((_) async => Response(
                  data: {
                    'success': true,
                    'message': 'Toutes les notifications marquées comme lues'
                  },
                  statusCode: 200,
                  requestOptions:
                      RequestOptions(path: '/notifications/mark-all-read'),
                ));

        // Act
        await repository.markAllAsRead();

        // Assert
        verify(mockDio.patch('/notifications/mark-all-read')).called(1);
      });
    });

    group('deleteNotification', () {
      test('DOIT supprimer notification avec succès', () async {
        // Arrange
        const notificationId = 'notif-456';
        when(mockDio.delete('/notifications/$notificationId'))
            .thenAnswer((_) async => Response(
                  data: {'success': true, 'message': 'Notification supprimée'},
                  statusCode: 200,
                  requestOptions:
                      RequestOptions(path: '/notifications/$notificationId'),
                ));

        // Act
        await repository.deleteNotification(notificationId);

        // Assert
        verify(mockDio.delete('/notifications/$notificationId')).called(1);
      });
    });

    group('deleteAllNotifications', () {
      test('DOIT supprimer toutes les notifications', () async {
        // Arrange
        when(mockDio.delete('/notifications'))
            .thenAnswer((_) async => Response(
                  data: {
                    'success': true,
                    'message': 'Toutes les notifications supprimées'
                  },
                  statusCode: 200,
                  requestOptions: RequestOptions(path: '/notifications'),
                ));

        // Act
        await repository.deleteAllNotifications();

        // Assert
        verify(mockDio.delete('/notifications')).called(1);
      });
    });
  });
}
