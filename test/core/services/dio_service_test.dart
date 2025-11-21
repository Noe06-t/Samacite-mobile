import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/core/constants/api_constants.dart';

void main() {
  group('DioService', () {
    late DioService dioService;

    setUp(() {
      dioService = DioService();
    });

    test('should initialize Dio with correct base URL', () {
      expect(dioService.dio.options.baseUrl, ApiConstants.baseUrl);
    });

    test('should have correct timeout settings', () {
      expect(dioService.dio.options.connectTimeout, ApiConstants.connectTimeout);
      expect(dioService.dio.options.receiveTimeout, ApiConstants.receiveTimeout);
    });

    test('should have correct headers', () {
      expect(dioService.dio.options.headers['Accept'], 'application/json');
      expect(dioService.dio.options.headers['Content-Type'], 'application/json');
    });

    test('should set authorization token', () {
      const token = 'test-token-123';
      dioService.setToken(token);
      
      expect(dioService.dio.options.headers['Authorization'], 'Bearer $token');
    });

    test('should clear authorization token', () {
      const token = 'test-token-123';
      dioService.setToken(token);
      dioService.clearToken();
      
      expect(dioService.dio.options.headers.containsKey('Authorization'), false);
    });
  });
}
