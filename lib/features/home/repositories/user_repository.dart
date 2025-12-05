import 'package:dio/dio.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/core/models/user_model.dart';

/// Repository pour gérer les opérations du profil utilisateur
/// 
/// Endpoints utilisés :
/// - GET /api/user/profile - Récupérer profil
/// - PUT /api/user/profile - Modifier profil
/// - POST /api/user/profile/photo - Upload photo
/// - PUT /api/user/password - Changer mot de passe
class UserRepository {
  final DioService _dioService;

  UserRepository(this._dioService);

  /// Récupère le profil de l'utilisateur connecté
  /// 
  /// Throws [DioException] si erreur réseau ou 401
  Future<UserModel> getProfile() async {
    try {
      final response = await _dioService.dio.get('/user/profile');
      
      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Erreur lors de la récupération du profil');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Met à jour le profil utilisateur
  /// 
  /// [data] doit contenir : nom, prenom, email?, telephone
  /// 
  /// Throws [DioException] si erreur réseau ou validation
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dioService.dio.put(
        '/user/profile',
        data: data,
      );
      
      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Erreur lors de la mise à jour');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Upload une photo de profil
  /// 
  /// [imagePath] : Chemin local du fichier image
  /// 
  /// Returns l'URL de la photo uploadée
  /// 
  /// Throws [DioException] si erreur (max 2MB, formats: jpeg, jpg, png)
  Future<String> uploadProfilePhoto(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dioService.dio.post(
        '/user/profile/photo',
        data: formData,
      );
      
      if (response.data['success'] == true) {
        return response.data['data']['photo_url'] as String;
      } else {
        throw Exception(response.data['message'] ?? 'Erreur lors de l\'upload');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Change le mot de passe de l'utilisateur
  /// 
  /// Params :
  /// - [currentPassword] : Mot de passe actuel
  /// - [newPassword] : Nouveau mot de passe (>= 8 caractères)
  /// - [newPasswordConfirmation] : Confirmation du nouveau mot de passe
  /// 
  /// Throws [DioException] si :
  /// - Mot de passe actuel incorrect (400)
  /// - Nouveau mot de passe trop court (422)
  /// - Confirmation ne correspond pas (422)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      final response = await _dioService.dio.put(
        '/user/password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        },
      );
      
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Erreur lors du changement de mot de passe');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Gestion des erreurs Dio avec messages personnalisés
  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      String message = 'Une erreur est survenue';

      // Extraire le message d'erreur
      if (data is Map<String, dynamic>) {
        message = data['message'] ?? message;
        
        // Gérer les erreurs de validation Laravel (422)
        if (e.response!.statusCode == 422 && data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            message = firstError.first.toString();
          }
        }
      }

      return Exception(message);
    }

    // Erreurs réseau
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Délai d\'attente dépassé. Vérifiez votre connexion.');
    }

    if (e.type == DioExceptionType.connectionError) {
      return Exception('Erreur de connexion. Vérifiez votre réseau.');
    }

    return Exception('Une erreur inattendue est survenue');
  }
}
