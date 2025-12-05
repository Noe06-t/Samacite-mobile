import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mobile_samacite/features/notifications/models/notification_model.dart';
import 'package:mobile_samacite/features/notifications/repositories/notification_repository.dart';
import 'package:mobile_samacite/features/notifications/state/notification_notifier.dart';
import 'package:mobile_samacite/features/notifications/state/notification_state.dart';

@GenerateMocks([NotificationRepository])
import 'notification_notifier_test.mocks.dart';

void main() {
  late MockNotificationRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockNotificationRepository();
    container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('NotificationNotifier -', () {
    group('loadNotifications', () {
      test('DOIT charger les notifications avec succès', () async {
        // Arrange
        final mockNotifications = [
          NotificationModel(
            id: 'notif-1',
            type: 'App\\Notifications\\ReportCreatedNotification',
            data: {'message': 'Nouveau signalement', 'report_id': 5},
            createdAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getNotifications(page: anyNamed('page'), perPage: anyNamed('perPage')))
            .thenAnswer((_) async => mockNotifications);
        when(mockRepository.getUnreadCount())
            .thenAnswer((_) async => 1);

        // Act
        await container.read(notificationNotifierProvider.notifier).loadNotifications();

        // Assert
        final state = container.read(notificationNotifierProvider);
        expect(state.notifications, mockNotifications);
        expect(state.isLoading, false);
        expect(state.errorMessage, null);
        verify(mockRepository.getNotifications(page: 1, perPage: 20)).called(1);
        verify(mockRepository.getUnreadCount()).called(1);
      });

      test('DOIT gérer l\'erreur lors du chargement', () async {
        // Arrange
        when(mockRepository.getNotifications(page: anyNamed('page'), perPage: anyNamed('perPage')))
            .thenThrow(Exception('Network error'));

        // Act
        await container.read(notificationNotifierProvider.notifier).loadNotifications();

        // Assert
        final state = container.read(notificationNotifierProvider);
        expect(state.isLoading, false);
        expect(state.errorMessage, isNotNull);
      });
    });

    group('loadMore', () {
      test('DOIT charger plus de notifications', () async {
        // Arrange - Créer une liste de 20 notifications pour la première page
        final initialNotifications = List.generate(
          20,
          (index) => NotificationModel(
            id: 'notif-${index + 1}',
            type: 'App\\Notifications\\ReportCreatedNotification',
            data: {'message': 'Notification ${index + 1}', 'report_id': index + 1},
            createdAt: DateTime.now(),
          ),
        );

        final moreNotifications = [
          NotificationModel(
            id: 'notif-21',
            type: 'App\\Notifications\\CommentCreatedNotification',
            data: {'message': 'Notification 21', 'report_id': 21},
            createdAt: DateTime.now(),
          ),
        ];

        // Premier chargement (20 notifications = hasMore true)
        when(mockRepository.getNotifications(page: 1, perPage: anyNamed('perPage')))
            .thenAnswer((_) async => initialNotifications);
        when(mockRepository.getUnreadCount()).thenAnswer((_) async => 21);

        await container.read(notificationNotifierProvider.notifier).loadNotifications();

        // Deuxième chargement
        when(mockRepository.getNotifications(page: 2, perPage: anyNamed('perPage')))
            .thenAnswer((_) async => moreNotifications);

        // Act
        await container.read(notificationNotifierProvider.notifier).loadMore();

        // Assert
        final state = container.read(notificationNotifierProvider);
        expect(state.notifications.length, 21);
        expect(state.currentPage, 2);
        expect(state.isLoadingMore, false);
      });

      test('NE DOIT PAS charger si hasMore est false', () async {
        // Arrange - État initial sans hasMore
        final notifier = container.read(notificationNotifierProvider.notifier);
        notifier.state = NotificationState.initial().copyWith(hasMore: false);

        // Act
        await notifier.loadMore();

        // Assert
        verifyNever(mockRepository.getNotifications(page: anyNamed('page'), perPage: anyNamed('perPage')));
      });
    });

    group('markAsRead', () {
      test('DOIT marquer notification comme lue avec mise à jour optimiste', () async {
        // Arrange
        final notification = NotificationModel(
          id: 'notif-1',
          type: 'App\\Notifications\\ReportCreatedNotification',
          data: {'message': 'Test', 'report_id': 1},
          readAt: null,
          createdAt: DateTime.now(),
        );

        when(mockRepository.getNotifications(page: anyNamed('page'), perPage: anyNamed('perPage')))
            .thenAnswer((_) async => [notification]);
        when(mockRepository.getUnreadCount()).thenAnswer((_) async => 1);

        await container.read(notificationNotifierProvider.notifier).loadNotifications();

        when(mockRepository.markAsRead('notif-1')).thenAnswer((_) async => {});
        when(mockRepository.getUnreadCount()).thenAnswer((_) async => 0);

        // Act
        await container.read(notificationNotifierProvider.notifier).markAsRead('notif-1');

        // Assert
        final state = container.read(notificationNotifierProvider);
        expect(state.notifications.first.isRead, true);
        expect(state.unreadCount, 0);
        verify(mockRepository.markAsRead('notif-1')).called(1);
      });
    });

    group('deleteNotification', () {
      test('DOIT supprimer notification avec mise à jour optimiste', () async {
        // Arrange
        final notifications = [
          NotificationModel(
            id: 'notif-1',
            type: 'App\\Notifications\\ReportCreatedNotification',
            data: {'message': 'Notification 1', 'report_id': 1},
            createdAt: DateTime.now(),
          ),
          NotificationModel(
            id: 'notif-2',
            type: 'App\\Notifications\\CommentCreatedNotification',
            data: {'message': 'Notification 2', 'report_id': 2},
            createdAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getNotifications(page: anyNamed('page'), perPage: anyNamed('perPage')))
            .thenAnswer((_) async => notifications);
        when(mockRepository.getUnreadCount()).thenAnswer((_) async => 0);

        await container.read(notificationNotifierProvider.notifier).loadNotifications();

        when(mockRepository.deleteNotification('notif-1')).thenAnswer((_) async => {});

        // Act
        await container.read(notificationNotifierProvider.notifier).deleteNotification('notif-1');

        // Assert
        final state = container.read(notificationNotifierProvider);
        expect(state.notifications.length, 1);
        expect(state.notifications.first.id, 'notif-2');
        verify(mockRepository.deleteNotification('notif-1')).called(1);
      });
    });

    group('refresh', () {
      test('DOIT rafraîchir les notifications', () async {
        // Arrange
        final mockNotifications = [
          NotificationModel(
            id: 'notif-1',
            type: 'App\\Notifications\\ReportCreatedNotification',
            data: {'message': 'Rafraîchi', 'report_id': 1},
            createdAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getNotifications(page: 1, perPage: anyNamed('perPage')))
            .thenAnswer((_) async => mockNotifications);
        when(mockRepository.getUnreadCount()).thenAnswer((_) async => 1);

        // Act
        await container.read(notificationNotifierProvider.notifier).refresh();

        // Assert
        final state = container.read(notificationNotifierProvider);
        expect(state.notifications, mockNotifications);
        expect(state.currentPage, 1);
        verify(mockRepository.getNotifications(page: 1, perPage: 20)).called(1);
      });
    });
  });
}
