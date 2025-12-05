import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_samacite/features/auth/providers/auth_providers.dart';
import 'package:mobile_samacite/features/home/repositories/user_repository.dart';

/// Provider pour UserRepository
/// 
/// Dépend de DioService pour les requêtes HTTP
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dioService = ref.watch(dioServiceProvider);
  return UserRepository(dioService);
});
