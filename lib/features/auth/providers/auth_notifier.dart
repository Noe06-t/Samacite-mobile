import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile_samacite/features/auth/providers/auth_state.dart';
import 'package:mobile_samacite/features/auth/providers/auth_providers.dart';
import 'package:mobile_samacite/core/errors/api_exception.dart';

part 'auth_notifier.g.dart';

@riverpod
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
      final dioService = ref.read(dioServiceProvider);
      dioService.setToken(token);
      // Ici, vous pourriez récupérer les infos utilisateur depuis le serveur
      // Pour l'instant, on reste en initial
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    state = const AuthState.loading();

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final response = await authRepository.register({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });

      // Sauvegarder le token
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.saveToken(response.token);
      await secureStorage.saveUserId(response.user.id.toString());
      await secureStorage.saveUserEmail(response.user.email);

      // Configurer le token dans Dio
      final dioService = ref.read(dioServiceProvider);
      dioService.setToken(response.token);

      state = AuthState.authenticated(response.user, response.token);
    } on ApiException catch (e) {
      state = AuthState.error(e.message);
    } catch (e) {
      state = AuthState.error('Erreur inattendue: $e');
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();

    try {
      final authRepository = ref.read(authRepositoryProvider);
      final response = await authRepository.login(email, password);

      // Sauvegarder le token
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.saveToken(response.token);
      await secureStorage.saveUserId(response.user.id.toString());
      await secureStorage.saveUserEmail(response.user.email);

      // Configurer le token dans Dio
      final dioService = ref.read(dioServiceProvider);
      dioService.setToken(response.token);

      state = AuthState.authenticated(response.user, response.token);
    } on ApiException catch (e) {
      state = AuthState.error(e.message);
    } catch (e) {
      state = AuthState.error('Erreur inattendue: $e');
    }
  }

  Future<void> logout() async {
    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.logout();

      // Nettoyer le stockage
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.clearAll();

      // Nettoyer le token de Dio
      final dioService = ref.read(dioServiceProvider);
      dioService.clearToken();

      state = const AuthState.unauthenticated();
    } catch (e) {
      // Même en cas d'erreur, on déconnecte localement
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.clearAll();

      final dioService = ref.read(dioServiceProvider);
      dioService.clearToken();

      state = const AuthState.unauthenticated();
    }
  }
}
