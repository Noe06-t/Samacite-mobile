import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/core/constants/api_constants.dart';
import 'package:logger/logger.dart';

/// Provider pour DioService
final dioServiceProvider = Provider<DioService>((ref) {
  return DioService();
});

/// Service Dio pour gérer toutes les requêtes API
class DioService {
  late final Dio _dio;
  final Logger _logger = Logger();

  DioService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout, // Utilise la constante (2 minutes)
        sendTimeout: const Duration(minutes: 2),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('\n[DioService] 📤 ========== NOUVELLE REQUÊTE ==========');
          print('[DioService] 🔸 Méthode: ${options.method}');
          print('[DioService] 🔸 URL complète: ${options.baseUrl}${options.path}');
          print('[DioService] 🔸 Path: ${options.path}');
          print('[DioService] 🔸 Headers: ${options.headers}');
          print('[DioService] 🔸 Data: ${options.data}');
          print('[DioService] 🔸 Query Parameters: ${options.queryParameters}');
          
          _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
          _logger.d('Headers: ${options.headers}');
          _logger.d('Data: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('\n[DioService] 📥 ========== RÉPONSE REÇUE ==========');
          print('[DioService] ✅ Status Code: ${response.statusCode}');
          print('[DioService] 🔸 Path: ${response.requestOptions.path}');
          print('[DioService] 🔸 Headers: ${response.headers}');
          print('[DioService] 🔸 Data: ${response.data}');
          print('[DioService] 📥 ========================================\n');
          
          _logger.i(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
          );
          _logger.d('Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('\n[DioService] ❌ ========== ERREUR HTTP ==========');
          print('[DioService] ❌ Status Code: ${error.response?.statusCode}');
          print('[DioService] 🔸 Type: ${error.type}');
          print('[DioService] 🔸 Path: ${error.requestOptions.path}');
          print('[DioService] 🔸 Message: ${error.message}');
          print('[DioService] 🔸 Response Data: ${error.response?.data}');
          print('[DioService] 🔸 Response Headers: ${error.response?.headers}');
          print('[DioService] ❌ =====================================\n');
          
          _logger.e(
            'ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}',
          );
          _logger.e('Message: ${error.message}');
          _logger.e('Data: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );
  }

  /// Définir le token d'authentification
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Supprimer le token d'authentification
  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }
}
