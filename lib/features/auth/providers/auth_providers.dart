import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/core/services/secure_storage_service.dart';
import 'package:mobile_samacite/features/auth/repositories/auth_repository.dart';

part 'auth_providers.g.dart';

/// Provider pour DioService (singleton avec keepAlive)
/// 
/// IMPORTANT: keepAlive est nécessaire pour garantir qu'une seule instance
/// de DioService existe dans l'application. Cela permet de :
/// - Partager le même token d'authentification entre tous les repositories
/// - Éviter de créer plusieurs instances Dio
/// - Maintenir la cohérence des intercepteurs
@Riverpod(keepAlive: true)
DioService dioService(DioServiceRef ref) {
  return DioService();
}

/// Provider pour SecureStorageService
@riverpod
SecureStorageService secureStorageService(SecureStorageServiceRef ref) {
  return SecureStorageService();
}

/// Provider pour AuthRepository
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  final dioService = ref.watch(dioServiceProvider);
  return AuthRepository(dioService);
}
