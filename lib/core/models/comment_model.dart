import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment_model.freezed.dart';
part 'comment_model.g.dart';

/// Convertisseur pour gérer les int qui arrivent en string depuis le backend
class IntConverter implements JsonConverter<int, dynamic> {
  const IntConverter();

  @override
  int fromJson(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    throw Exception('Cannot convert $value to int');
  }

  @override
  int toJson(int value) => value;
}

/// Modèle pour un commentaire sur un signalement
/// 
/// Structure backend Laravel:
/// - id: int
/// - content: String (texte du commentaire)
/// - report_id: int (ID du signalement)
/// - user_id: int (ID de l'auteur)
/// - user: {id, nom, prenom, email, telephone} (relation)
/// - created_at: String (ISO 8601)
/// - updated_at: String (ISO 8601)
@freezed
class CommentModel with _$CommentModel {
  const factory CommentModel({
    @IntConverter() required int id,
    required String content,
    @IntConverter() @JsonKey(name: 'report_id') required int reportId,
    @IntConverter() @JsonKey(name: 'user_id') required int userId,
    
    // Relation user (optionnelle si pas chargée)
    CommentUser? user,
    
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _CommentModel;

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);
}

/// Sous-modèle pour l'utilisateur dans un commentaire
/// 
/// Supporte 2 formats backend:
/// 1. Format complet: {id, nom, prenom, email, telephone}
/// 2. Format minimal: {id, name, email}
@freezed
class CommentUser with _$CommentUser {
  const factory CommentUser({
    @IntConverter() required int id,
    
    // Format complet (depuis UserModel)
    String? nom,
    String? prenom,
    
    // Format minimal (depuis backend comments)
    String? name,
    
    String? email,
    String? telephone,
  }) = _CommentUser;

  factory CommentUser.fromJson(Map<String, dynamic> json) =>
      _$CommentUserFromJson(json);
}
