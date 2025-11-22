// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dioServiceHash() => r'889a9c3e81c87e81cf74a8045f600cdc31931ff2';

/// Provider pour DioService (singleton avec keepAlive)
///
/// IMPORTANT: keepAlive est nécessaire pour garantir qu'une seule instance
/// de DioService existe dans l'application. Cela permet de :
/// - Partager le même token d'authentification entre tous les repositories
/// - Éviter de créer plusieurs instances Dio
/// - Maintenir la cohérence des intercepteurs
///
/// Copied from [dioService].
@ProviderFor(dioService)
final dioServiceProvider = Provider<DioService>.internal(
  dioService,
  name: r'dioServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dioServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DioServiceRef = ProviderRef<DioService>;
String _$secureStorageServiceHash() =>
    r'28ef5a96de61720fa06a7ba59ceb572a1791b078';

/// Provider pour SecureStorageService
///
/// Copied from [secureStorageService].
@ProviderFor(secureStorageService)
final secureStorageServiceProvider =
    AutoDisposeProvider<SecureStorageService>.internal(
      secureStorageService,
      name: r'secureStorageServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$secureStorageServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SecureStorageServiceRef = AutoDisposeProviderRef<SecureStorageService>;
String _$authRepositoryHash() => r'9dae2dbcb58cf3ecaee8a5589ecbebd080d43be2';

/// Provider pour AuthRepository
///
/// Copied from [authRepository].
@ProviderFor(authRepository)
final authRepositoryProvider = AutoDisposeProvider<AuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthRepositoryRef = AutoDisposeProviderRef<AuthRepository>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
