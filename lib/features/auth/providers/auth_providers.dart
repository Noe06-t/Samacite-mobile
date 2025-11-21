import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';
import 'package:mobile_samacite/core/services/secure_storage_service.dart';
import 'package:mobile_samacite/features/auth/repositories/auth_repository.dart';

part 'auth_providers.g.dart';

/// Provider pour DioService
@riverpod
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
