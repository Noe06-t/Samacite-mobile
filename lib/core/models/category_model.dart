import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_model.freezed.dart';
part 'category_model.g.dart';

/// Modèle pour les catégories de signalements
/// 
/// Représente une catégorie côté backend Laravel (table: categories)
@freezed
class CategoryModel with _$CategoryModel {
  const factory CategoryModel({
    required int id,
    required String name,
    String? description,
    String? icon, // Nom de l'icône (à mapper avec Icons Flutter)
    @JsonKey(name: 'created_at') @Default(null) String? createdAt,
    @JsonKey(name: 'updated_at') @Default(null) String? updatedAt,
  }) = _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);
}
