import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mobile_samacite/features/auth/repositories/auth_repository.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/core/models/auth_response_model.dart';
import 'package:mobile_samacite/core/errors/api_exception.dart';
import 'package:dio/dio.dart';

@GenerateMocks([DioService, Dio])
import 'auth_repository_test.mocks.dart';

void main() {
  group('AuthRepository', () {
    late AuthRepository authRepository;
    late MockDioService mockDioService;
    late MockDio mockDio;

    setUp(() {
      mockDioService = MockDioService();
      mockDio = MockDio();
      when(mockDioService.dio).thenReturn(mockDio);
      authRepository = AuthRepository(mockDioService);
    });

    group('register', () {
      test('should return AuthResponseModel on successful registration', () async {
        // Arrange
        final registerData = {
          'name': 'Test User',
          'email': 'test@example.com',
          'password': 'password123',
          'password_confirmation': 'password123',
        };

        final mockResponse = {
          'user': {
            'id': 1,
            'name': 'Test User',
            'email': 'test@example.com',
          },
          'token': 'test-token-123',
          'token_type': 'Bearer',
        };

        when(mockDio.post(
          any,
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              data: mockResponse,
              statusCode: 201,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act
        final result = await authRepository.register(registerData);

        // Assert
        expect(result, isA<AuthResponseModel>());
        expect(result.user.name, 'Test User');
        expect(result.user.email, 'test@example.com');
        expect(result.token, 'test-token-123');
      });

      test('should throw ApiException on registration failure', () async {
        // Arrange
        final registerData = {
          'name': 'Test User',
          'email': 'test@example.com',
          'password': 'password123',
          'password_confirmation': 'password123',
        };

        when(mockDio.post(
          any,
          data: anyNamed('data'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            statusCode: 422,
            data: {'message': 'Validation error'},
            requestOptions: RequestOptions(path: ''),
          ),
        ));

        // Act & Assert
        expect(
          () => authRepository.register(registerData),
          throwsA(isA<ApiException>()),
        );
      });

      test('should validate required fields', () async {
        // Arrange
        final invalidData = {
          'name': '',
          'email': 'invalid-email',
          'password': '123',
        };

        // Act & Assert
        expect(
          () => authRepository.register(invalidData),
          throwsA(isA<ApiException>()),
        );
      });

      test('should validate password confirmation match', () async {
        // Arrange
        final invalidData = {
          'name': 'Test User',
          'email': 'test@example.com',
          'password': 'password123',
          'password_confirmation': 'different-password',
        };

        when(mockDio.post(
          any,
          data: anyNamed('data'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            statusCode: 422,
            data: {'message': 'Password confirmation does not match'},
            requestOptions: RequestOptions(path: ''),
          ),
        ));

        // Act & Assert
        expect(
          () => authRepository.register(invalidData),
          throwsA(isA<ApiException>()),
        );
      });
    });
  });
}
