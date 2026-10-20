import 'package:dio/dio.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/core/constants/api_constants.dart';
import 'package:mobile_samacite/core/models/auth_response_model.dart';
import 'package:mobile_samacite/core/models/user_model.dart';
import 'package:mobile_samacite/core/errors/api_exception.dart';

/// Interface du repository d'authentification
abstract class IAuthRepository {
  Future<AuthResponseModel> register(Map<String, dynamic> data);
  Future<AuthResponseModel> login(String email, String password);
  Future<UserModel> getProfile();
  Future<void> logout();
}

/// Implémentation du repository d'authentification
class AuthRepository implements IAuthRepository {
  final DioService _dioService;

  AuthRepository(this._dioService);

  @override
  Future<AuthResponseModel> register(Map<String, dynamic> data) async {
    print('[AuthRepository] 📝 Début de l\'inscription');
    print('[AuthRepository] 📄 Données: $data');
    print('[AuthRepository] 🌐 URL: ${ApiConstants.register}');
    
    try {
      // Validation locale
      print('[AuthRepository] ✔️ Validation des données...');
      _validateRegisterData(data);
      print('[AuthRepository] ✅ Validation réussie');

      print('[AuthRepository] 📤 Envoi de la requête POST...');
      final response = await _dioService.dio.post(
        ApiConstants.register,
        data: data,
      );

      print('[AuthRepository] 📥 Réponse reçue');
      print('[AuthRepository] 📊 Status Code: ${response.statusCode}');
      print('[AuthRepository] 📄 Data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('[AuthRepository] ✅ Inscription réussie!');
        final responseData = response.data as Map<String, dynamic>;
        
        // Parser la réponse pour retourner AuthResponseModel
        // Si le backend retourne {user, token}, on l'utilise
        // Sinon, on retourne un modèle avec juste l'user
        if (responseData.containsKey('token')) {
          print('[AuthRepository] 🔑 Token reçu, auto-login activé');
          return AuthResponseModel.fromJson(responseData);
        } else if (responseData.containsKey('data')) {
          print('[AuthRepository] 👤 User créé, token vide (login manuel requis)');
          // Backend ne retourne pas de token, créer un modèle avec token vide
          return AuthResponseModel.fromJson({
            'user': responseData['data'],
            'token': '', // Token vide, AuthNotifier fera le login
            'token_type': 'Bearer',
          });
        } else {
          throw ApiException(
            message: 'Réponse inattendue du serveur',
            statusCode: response.statusCode,
            data: response.data,
          );
        }
      } else {
        print('[AuthRepository] ❌ Status code non attendu: ${response.statusCode}');
        throw ApiException(
          message: 'Erreur d\'inscription',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } on DioException catch (e) {
      print('[AuthRepository] ❌ DioException: ${e.type}');
      print('[AuthRepository] 📄 Message: ${e.message}');
      print('[AuthRepository] 📊 Response: ${e.response?.data}');
      print('[AuthRepository] 🔢 Status Code: ${e.response?.statusCode}');
      throw _handleDioError(e);
    } catch (e) {
      print('[AuthRepository] ❌ Erreur inattendue: $e');
      print('[AuthRepository] 📚 Type: ${e.runtimeType}');
      throw ApiException(
        message: 'Erreur inattendue: $e',
      );
    }
  }

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    print('[AuthRepository] 🔐 Début du login');
    print('[AuthRepository] 🆔 Identifiant reçu: $email');
    print('[AuthRepository] 🌐 URL: ${ApiConstants.login}');
    
    // Déterminer si c'est un email ou un téléphone (format: +221771234567)
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final isEmail = emailRegex.hasMatch(email);
    
    print('[AuthRepository] 🔍 Type d\'identifiant: ${isEmail ? "Email" : "Téléphone (+221...)"}');
    
    // Construire les données à envoyer
    final Map<String, dynamic> loginData = {
      if (isEmail) 'email': email else 'telephone': email,
      'password': password,
    };
    
    print('[AuthRepository] 📋 Données à envoyer: $loginData');
    print('[AuthRepository] 🔍 Clé utilisée: ${isEmail ? "email" : "telephone"}');
    print('[AuthRepository] 🔍 Valeur: $email');
    
    try {
      print('[AuthRepository] 📤 Envoi de la requête POST...');
      final response = await _dioService.dio.post(
        ApiConstants.login,
        data: loginData,
      );

      print('[AuthRepository] 📥 Réponse reçue');
      print('[AuthRepository] 📊 Status Code: ${response.statusCode}');
      print('[AuthRepository] 📄 Data: ${response.data}');

      if (response.statusCode == 200) {
        print('[AuthRepository] ✅ Login réussi, parsing de la réponse...');
        
        // Laravel retourne: {success: true, message: "...", data: {user: {...}, token: "..."}}
        // On doit extraire response.data['data']
        final responseData = response.data as Map<String, dynamic>;
        print('[AuthRepository] 🔍 Keys de la réponse: ${responseData.keys}');
        
        if (!responseData.containsKey('data')) {
          print('[AuthRepository] ⚠️ Clé "data" absente! Structure inattendue.');
          throw ApiException(
            message: 'Structure de réponse invalide',
            statusCode: response.statusCode,
          );
        }
        
        final authData = responseData['data'] as Map<String, dynamic>;
        print('[AuthRepository] 🔍 Keys dans data: ${authData.keys}');
        
        final authResponse = AuthResponseModel.fromJson(authData);
        print('[AuthRepository] 👤 User: ${authResponse.user.prenom} ${authResponse.user.nom}');
        print('[AuthRepository] 🔑 Token: ${authResponse.token.substring(0, 20)}...');
        return authResponse;
      } else {
        print('[AuthRepository] ❌ Status code non 200: ${response.statusCode}');
        throw ApiException(
          message: 'Erreur de connexion',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } on DioException catch (e) {
      print('[AuthRepository] ❌ DioException: ${e.type}');
      print('[AuthRepository] 📄 Message: ${e.message}');
      print('[AuthRepository] 📊 Response: ${e.response?.data}');
      print('[AuthRepository] 🔢 Status Code: ${e.response?.statusCode}');
      throw _handleDioError(e);
    } catch (e) {
      print('[AuthRepository] ❌ Erreur inattendue: $e');
      print('[AuthRepository] 📚 Stack trace: ${StackTrace.current}');
      throw ApiException(
        message: 'Erreur inattendue: $e',
      );
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await _dioService.dio.get('/user/profile');
      final responseData = response.data as Map<String, dynamic>;
      final profileData = responseData['data'] as Map<String, dynamic>;
      return UserModel.fromJson(profileData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Impossible de restaurer la session: $e');
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
    final nom = data['nom']?.toString() ?? '';
    final prenom = data['prenom']?.toString() ?? '';
    final email = data['email']?.toString() ?? '';
    final telephone = data['telephone']?.toString() ?? '';
    final password = data['password']?.toString() ?? '';
    final passwordConfirmation = data['password_confirmation']?.toString() ?? '';

    if (nom.isEmpty) {
      throw ApiException(message: 'Le nom est requis');
    }

    if (prenom.isEmpty) {
      throw ApiException(message: 'Le prénom est requis');
    }

    if (telephone.isEmpty) {
      throw ApiException(message: 'Le téléphone est requis');
    }

    // Email optionnel, mais s'il est fourni, il doit être valide
    if (email.isNotEmpty && !_isValidEmail(email)) {
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
      
      // Gestion spéciale des erreurs de validation (422)
      if (error.response!.statusCode == 422 && data is Map) {
        if (data.containsKey('errors')) {
          final errors = data['errors'] as Map<String, dynamic>;
          final firstErrorKey = errors.keys.first;
          final firstErrorMessages = errors[firstErrorKey] as List;
          
          // Traduire les erreurs communes
          String errorMessage = firstErrorMessages.first.toString();
          if (errorMessage.contains('validation.unique')) {
            if (firstErrorKey == 'email') {
              errorMessage = 'Cet email est déjà utilisé';
            } else if (firstErrorKey == 'telephone') {
              errorMessage = 'Ce numéro de téléphone est déjà utilisé';
            }
          } else if (errorMessage.contains('validation.required')) {
            errorMessage = 'Le champ $firstErrorKey est requis';
          }
          
          return ApiException(
            message: errorMessage,
            statusCode: error.response!.statusCode,
            data: data,
          );
        }
      }
      
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
