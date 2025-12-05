import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile_samacite/features/auth/providers/auth_state.dart';
import 'package:mobile_samacite/features/auth/providers/auth_providers.dart';
import 'package:mobile_samacite/core/errors/api_exception.dart';

part 'auth_notifier.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    _checkAuthStatus();
    return const AuthState.initial();
  }

  Future<void> _checkAuthStatus() async {
    final secureStorage = ref.read(secureStorageServiceProvider);
    final token = await secureStorage.getToken();

    if (token != null) {
      // ⚠️ NE PAS charger le token automatiquement ici
      // Cela empêche les nouveaux login de fonctionner avec un token expiré
      // Le token sera chargé uniquement après un login réussi
      print('[AuthNotifier] 🔑 Token trouvé dans le stockage (non chargé automatiquement)');
      // Ici, vous pourriez récupérer les infos utilisateur depuis le serveur
      // Pour l'instant, on reste en initial
    } else {
      print('[AuthNotifier] ❌ Aucun token trouvé');
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> register({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String password,
    required String passwordConfirmation,
  }) async {
    print('[AuthNotifier] 📝 Début du processus d\'inscription');
    print('[AuthNotifier] 📧 Email: $email');
    state = const AuthState.loading();

    try {
      final authRepository = ref.read(authRepositoryProvider);
      
      // Étape 1 : Inscription (ne retourne pas de token)
      print('[AuthNotifier] 📤 Envoi de la requête d\'inscription...');
      await authRepository.register({
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
      
      print('[AuthNotifier] ✅ Inscription réussie!');
      print('[AuthNotifier] 🔐 Connexion automatique en cours...');

      // Étape 2 : Login automatique pour obtenir le token
      // Utiliser email si disponible, sinon téléphone
      final identifier = email.isNotEmpty ? email : telephone;
      print('[AuthNotifier] 🆔 Identifiant pour auto-login: $identifier');
      final loginResponse = await authRepository.login(identifier, password);
      print('[AuthNotifier] ✅ Login automatique réussi!');

      // Sauvegarder le token
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.saveToken(loginResponse.token);
      await secureStorage.saveUserId(loginResponse.user.id.toString());
      if (loginResponse.user.email != null) {
        await secureStorage.saveUserEmail(loginResponse.user.email!);
      }
      print('[AuthNotifier] 💾 Token sauvegardé');

      // Configurer le token dans Dio
      final dioService = ref.read(dioServiceProvider);
      dioService.setToken(loginResponse.token);
      print('[AuthNotifier] 🔧 Token configuré dans Dio');

      state = AuthState.authenticated(loginResponse.user, loginResponse.token);
      print('[AuthNotifier] 🎉 État: authenticated');
    } on ApiException catch (e) {
      print('[AuthNotifier] ❌ ApiException: ${e.message}');
      state = AuthState.error(e.message);
    } catch (e) {
      print('[AuthNotifier] ❌ Erreur inattendue: $e');
      state = AuthState.error('Erreur inattendue: $e');
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    print('[AuthNotifier] 🚀 Début du processus de login');
    print('[AuthNotifier] 📧 Email: $email');
    print('[AuthNotifier] ⏳ Passage en état loading...');
    state = const AuthState.loading();

    try {
      print('[AuthNotifier] 📦 Récupération du authRepository...');
      final authRepository = ref.read(authRepositoryProvider);
      
      print('[AuthNotifier] 🔄 Appel de authRepository.login()...');
      final response = await authRepository.login(email, password);
      print('[AuthNotifier] ✅ Réponse reçue du repository');

      // Sauvegarder le token
      print('[AuthNotifier] 💾 Sauvegarde du token...');
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.saveToken(response.token);
      print('[AuthNotifier] ✅ Token sauvegardé');
      
      await secureStorage.saveUserId(response.user.id.toString());
      print('[AuthNotifier] ✅ User ID sauvegardé: ${response.user.id}');
      
      if (response.user.email != null) {
        await secureStorage.saveUserEmail(response.user.email!);
        print('[AuthNotifier] ✅ Email sauvegardé: ${response.user.email}');
      } else {
        print('[AuthNotifier] ℹ️ Pas d\'email à sauvegarder');
      }

      // Configurer le token dans Dio
      print('[AuthNotifier] 🔧 Configuration du token dans Dio...');
      final dioService = ref.read(dioServiceProvider);
      dioService.setToken(response.token);
      print('[AuthNotifier] ✅ Token configuré dans Dio');

      print('[AuthNotifier] 🎉 Passage en état authenticated');
      state = AuthState.authenticated(response.user, response.token);
      
      print('[AuthNotifier] ✅ Login terminé avec succès!');
    } on ApiException catch (e) {
      print('[AuthNotifier] ❌ ApiException capturée: ${e.message}');
      print('[AuthNotifier] 📊 Status Code: ${e.statusCode}');
      print('[AuthNotifier] 📄 Data: ${e.data}');
      state = AuthState.error(e.message);
    } catch (e) {
      print('[AuthNotifier] ❌ Erreur inattendue: $e');
      print('[AuthNotifier] 📚 Type: ${e.runtimeType}');
      print('[AuthNotifier] 📚 Stack trace: ${StackTrace.current}');
      state = AuthState.error('Erreur inattendue: $e');
    }
  }

  /// Met à jour les informations de l'utilisateur dans l'état
  /// (après modification du profil)
  void updateUser(user) {
    state.whenOrNull(
      authenticated: (currentUser, token) {
        print('[AuthNotifier] 🔄 Mise à jour de l\'utilisateur');
        state = AuthState.authenticated(user, token);
        print('[AuthNotifier] ✅ Utilisateur mis à jour dans l\'état');
      },
    );
  }

  Future<void> logout() async {
    print('[AuthNotifier] 🚪 Début du processus de déconnexion');
    
    // Nettoyer le stockage local
    final secureStorage = ref.read(secureStorageServiceProvider);
    await secureStorage.clearAll();
    print('[AuthNotifier] 🗑️ Storage nettoyé');

    // Nettoyer le token de Dio
    final dioService = ref.read(dioServiceProvider);
    dioService.clearToken();
    print('[AuthNotifier] 🔓 Token retiré de Dio');

    state = const AuthState.unauthenticated();
    print('[AuthNotifier] ✅ Déconnexion réussie');
    
    // Optionnel : appel backend en arrière-plan (non bloquant)
    // pour invalider le token côté serveur
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.logout().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('[AuthNotifier] ⏱️ Timeout logout backend (non bloquant)');
        },
      );
      print('[AuthNotifier] 🌐 Token invalidé côté serveur');
    } catch (e) {
      print('[AuthNotifier] ⚠️ Erreur logout backend (ignorée): $e');
      // On ignore l'erreur car la déconnexion locale est déjà faite
    }
  }
}
