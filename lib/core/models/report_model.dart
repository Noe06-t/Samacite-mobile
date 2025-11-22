import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile_samacite/core/models/user_model.dart';
import 'package:mobile_samacite/core/models/category_model.dart';
import 'package:mobile_samacite/core/models/location_model.dart';

part 'report_model.freezed.dart';
part 'report_model.g.dart';

/// Modèle pour les signalements
/// 
/// Représente un signalement côté backend Laravel (table: reports)
/// Inclut les relations: user, category, images, location
@freezed
class ReportModel with _$ReportModel {
  const factory ReportModel({
    required int id,
    required String title,
    required String description,
    required String status, // 'pending', 'in_progress', 'resolved'
    @JsonKey(name: 'category_id') required int categoryId,
    @JsonKey(name: 'user_id') required int userId,
    
    // Relations (peuvent être nulles si non incluses dans la requête)
    @Default(null) UserModel? user,
    @Default(null) CategoryModel? category,
    @Default(null) LocationModel? location,
    
    // Images URLs (peut être une liste vide)
    @Default([]) List<String> images,
    
    @JsonKey(name: 'created_at') @Default(null) String? createdAt,
    @JsonKey(name: 'updated_at') @Default(null) String? updatedAt,
  }) = _ReportModel;

  factory ReportModel.fromJson(Map<String, dynamic> json) =>
      _$ReportModelFromJson(json);
}
