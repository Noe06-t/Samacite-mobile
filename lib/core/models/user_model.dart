import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required int id,
    required String nom,
    required String prenom,
    String? email, // Email optionnel
    required String telephone, // Téléphone obligatoire
    @JsonKey(name: 'photo_url') String? photoUrl, // Photo de profil
    @JsonKey(name: 'created_at') @Default(null) String? createdAt,
    @JsonKey(name: 'updated_at') @Default(null) String? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
