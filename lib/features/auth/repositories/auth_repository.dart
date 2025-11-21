import 'package:dio/dio.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/core/constants/api_constants.dart';
import 'package:mobile_samacite/core/models/auth_response_model.dart';
import 'package:mobile_samacite/core/errors/api_exception.dart';

/// Interface du repository d'authentification
abstract class IAuthRepository {
  Future<AuthResponseModel> register(Map<String, dynamic> data);
  Future<AuthResponseModel> login(String email, String password);
  Future<void> logout();
}

/// Implémentation du repository d'authentification
class AuthRepository implements IAuthRepository {
  final DioService _dioService;

  AuthRepository(this._dioService);

  @override
  Future<AuthResponseModel> register(Map<String, dynamic> data) async {
    try {
      // Validation locale
      _validateRegisterData(data);

      final response = await _dioService.dio.post(
        ApiConstants.register,
        data: data,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AuthResponseModel.fromJson(response.data);
      } else {
        throw ApiException(
          message: 'Erreur d\'inscription',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(
        message: 'Erreur inattendue: $e',
      );
    }
  }

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final response = await _dioService.dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return AuthResponseModel.fromJson(response.data);
      } else {
        throw ApiException(
          message: 'Erreur de connexion',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(
        message: 'Erreur inattendue: $e',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dioService.dio.post(ApiConstants.logout);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  void _validateRegisterData(Map<String, dynamic> data) {
    final name = data['name']?.toString() ?? '';
    final email = data['email']?.toString() ?? '';
    final password = data['password']?.toString() ?? '';
    final passwordConfirmation = data['password_confirmation']?.toString() ?? '';

    if (name.isEmpty) {
      throw ApiException(message: 'Le nom est requis');
    }

    if (email.isEmpty) {
      throw ApiException(message: 'L\'email est requis');
    }

    if (!_isValidEmail(email)) {
      throw ApiException(message: 'Email invalide');
    }

    if (password.isEmpty) {
      throw ApiException(message: 'Le mot de passe est requis');
    }

    if (password.length < 8) {
      throw ApiException(message: 'Le mot de passe doit contenir au moins 8 caractères');
    }

    if (password != passwordConfirmation) {
      throw ApiException(message: 'Les mots de passe ne correspondent pas');
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  ApiException _handleDioError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      final message = data is Map && data.containsKey('message')
          ? data['message']
          : 'Erreur de connexion au serveur';

      return ApiException(
        message: message,
        statusCode: error.response!.statusCode,
        data: data,
      );
    } else {
      return ApiException(
        message: 'Erreur de connexion réseau',
      );
    }
  }
}
