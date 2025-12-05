import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile_samacite/core/models/comment_model.dart';
import 'package:mobile_samacite/features/comments/repositories/comment_repository.dart';
import 'package:mobile_samacite/core/services/dio_service.dart';

part 'comments_provider.g.dart';

/// Provider du CommentRepository
@Riverpod(keepAlive: true)
CommentRepository commentRepository(CommentRepositoryRef ref) {
  final dioService = ref.watch(dioServiceProvider);
  return CommentRepository(dioService);
}

/// Provider pour récupérer les commentaires d'un signalement
@riverpod
Future<Map<String, dynamic>> reportComments(
  ReportCommentsRef ref,
  int reportId, {
  int page = 1,
}) async {
  final repository = ref.watch(commentRepositoryProvider);
  return repository.getComments(reportId, page: page);
}

/// Provider pour créer un commentaire
@riverpod
Future<CommentModel> createComment(
  CreateCommentRef ref,
  int reportId,
  String content,
) async {
  final repository = ref.watch(commentRepositoryProvider);
  return repository.createComment(reportId, content);
}

/// Provider pour supprimer un commentaire
@riverpod
Future<void> deleteComment(
  DeleteCommentRef ref,
  int commentId,
) async {
  final repository = ref.watch(commentRepositoryProvider);
  return repository.deleteComment(commentId);
}
