// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$commentRepositoryHash() => r'd88788cb21b2103805d108c9787bedc2cb17a755';

/// Provider du CommentRepository
///
/// Copied from [commentRepository].
@ProviderFor(commentRepository)
final commentRepositoryProvider = Provider<CommentRepository>.internal(
  commentRepository,
  name: r'commentRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$commentRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CommentRepositoryRef = ProviderRef<CommentRepository>;
String _$reportCommentsHash() => r'5f1bc13bc31589d5053ce86729da43a173690edd';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provider pour récupérer les commentaires d'un signalement
///
/// Copied from [reportComments].
@ProviderFor(reportComments)
const reportCommentsProvider = ReportCommentsFamily();

/// Provider pour récupérer les commentaires d'un signalement
///
/// Copied from [reportComments].
class ReportCommentsFamily extends Family<AsyncValue<Map<String, dynamic>>> {
  /// Provider pour récupérer les commentaires d'un signalement
  ///
  /// Copied from [reportComments].
  const ReportCommentsFamily();

  /// Provider pour récupérer les commentaires d'un signalement
  ///
  /// Copied from [reportComments].
  ReportCommentsProvider call(
    int reportId, {
    int page = 1,
  }) {
    return ReportCommentsProvider(
      reportId,
      page: page,
    );
  }

  @override
  ReportCommentsProvider getProviderOverride(
    covariant ReportCommentsProvider provider,
  ) {
    return call(
      provider.reportId,
      page: provider.page,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'reportCommentsProvider';
}

/// Provider pour récupérer les commentaires d'un signalement
///
/// Copied from [reportComments].
class ReportCommentsProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// Provider pour récupérer les commentaires d'un signalement
  ///
  /// Copied from [reportComments].
  ReportCommentsProvider(
    int reportId, {
    int page = 1,
  }) : this._internal(
          (ref) => reportComments(
            ref as ReportCommentsRef,
            reportId,
            page: page,
          ),
          from: reportCommentsProvider,
          name: r'reportCommentsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$reportCommentsHash,
          dependencies: ReportCommentsFamily._dependencies,
          allTransitiveDependencies:
              ReportCommentsFamily._allTransitiveDependencies,
          reportId: reportId,
          page: page,
        );

  ReportCommentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.reportId,
    required this.page,
  }) : super.internal();

  final int reportId;
  final int page;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(ReportCommentsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ReportCommentsProvider._internal(
        (ref) => create(ref as ReportCommentsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        reportId: reportId,
        page: page,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _ReportCommentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReportCommentsProvider &&
        other.reportId == reportId &&
        other.page == page;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, reportId.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ReportCommentsRef on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `reportId` of this provider.
  int get reportId;

  /// The parameter `page` of this provider.
  int get page;
}

class _ReportCommentsProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with ReportCommentsRef {
  _ReportCommentsProviderElement(super.provider);

  @override
  int get reportId => (origin as ReportCommentsProvider).reportId;
  @override
  int get page => (origin as ReportCommentsProvider).page;
}

String _$createCommentHash() => r'c01adce655348830ff4851f770484b9b36c91359';

/// Provider pour créer un commentaire
///
/// Copied from [createComment].
@ProviderFor(createComment)
const createCommentProvider = CreateCommentFamily();

/// Provider pour créer un commentaire
///
/// Copied from [createComment].
class CreateCommentFamily extends Family<AsyncValue<CommentModel>> {
  /// Provider pour créer un commentaire
  ///
  /// Copied from [createComment].
  const CreateCommentFamily();

  /// Provider pour créer un commentaire
  ///
  /// Copied from [createComment].
  CreateCommentProvider call(
    int reportId,
    String content,
  ) {
    return CreateCommentProvider(
      reportId,
      content,
    );
  }

  @override
  CreateCommentProvider getProviderOverride(
    covariant CreateCommentProvider provider,
  ) {
    return call(
      provider.reportId,
      provider.content,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'createCommentProvider';
}

/// Provider pour créer un commentaire
///
/// Copied from [createComment].
class CreateCommentProvider extends AutoDisposeFutureProvider<CommentModel> {
  /// Provider pour créer un commentaire
  ///
  /// Copied from [createComment].
  CreateCommentProvider(
    int reportId,
    String content,
  ) : this._internal(
          (ref) => createComment(
            ref as CreateCommentRef,
            reportId,
            content,
          ),
          from: createCommentProvider,
          name: r'createCommentProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$createCommentHash,
          dependencies: CreateCommentFamily._dependencies,
          allTransitiveDependencies:
              CreateCommentFamily._allTransitiveDependencies,
          reportId: reportId,
          content: content,
        );

  CreateCommentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.reportId,
    required this.content,
  }) : super.internal();

  final int reportId;
  final String content;

  @override
  Override overrideWith(
    FutureOr<CommentModel> Function(CreateCommentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CreateCommentProvider._internal(
        (ref) => create(ref as CreateCommentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        reportId: reportId,
        content: content,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<CommentModel> createElement() {
    return _CreateCommentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CreateCommentProvider &&
        other.reportId == reportId &&
        other.content == content;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, reportId.hashCode);
    hash = _SystemHash.combine(hash, content.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CreateCommentRef on AutoDisposeFutureProviderRef<CommentModel> {
  /// The parameter `reportId` of this provider.
  int get reportId;

  /// The parameter `content` of this provider.
  String get content;
}

class _CreateCommentProviderElement
    extends AutoDisposeFutureProviderElement<CommentModel>
    with CreateCommentRef {
  _CreateCommentProviderElement(super.provider);

  @override
  int get reportId => (origin as CreateCommentProvider).reportId;
  @override
  String get content => (origin as CreateCommentProvider).content;
}

String _$deleteCommentHash() => r'a9502fa0ccdeaa0837dc4b287d4d4073644a3e6d';

/// Provider pour supprimer un commentaire
///
/// Copied from [deleteComment].
@ProviderFor(deleteComment)
const deleteCommentProvider = DeleteCommentFamily();

/// Provider pour supprimer un commentaire
///
/// Copied from [deleteComment].
class DeleteCommentFamily extends Family<AsyncValue<void>> {
  /// Provider pour supprimer un commentaire
  ///
  /// Copied from [deleteComment].
  const DeleteCommentFamily();

  /// Provider pour supprimer un commentaire
  ///
  /// Copied from [deleteComment].
  DeleteCommentProvider call(
    int commentId,
  ) {
    return DeleteCommentProvider(
      commentId,
    );
  }

  @override
  DeleteCommentProvider getProviderOverride(
    covariant DeleteCommentProvider provider,
  ) {
    return call(
      provider.commentId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'deleteCommentProvider';
}

/// Provider pour supprimer un commentaire
///
/// Copied from [deleteComment].
class DeleteCommentProvider extends AutoDisposeFutureProvider<void> {
  /// Provider pour supprimer un commentaire
  ///
  /// Copied from [deleteComment].
  DeleteCommentProvider(
    int commentId,
  ) : this._internal(
          (ref) => deleteComment(
            ref as DeleteCommentRef,
            commentId,
          ),
          from: deleteCommentProvider,
          name: r'deleteCommentProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$deleteCommentHash,
          dependencies: DeleteCommentFamily._dependencies,
          allTransitiveDependencies:
              DeleteCommentFamily._allTransitiveDependencies,
          commentId: commentId,
        );

  DeleteCommentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.commentId,
  }) : super.internal();

  final int commentId;

  @override
  Override overrideWith(
    FutureOr<void> Function(DeleteCommentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DeleteCommentProvider._internal(
        (ref) => create(ref as DeleteCommentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        commentId: commentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _DeleteCommentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DeleteCommentProvider && other.commentId == commentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, commentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin DeleteCommentRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `commentId` of this provider.
  int get commentId;
}

class _DeleteCommentProviderElement
    extends AutoDisposeFutureProviderElement<void> with DeleteCommentRef {
  _DeleteCommentProviderElement(super.provider);

  @override
  int get commentId => (origin as DeleteCommentProvider).commentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
