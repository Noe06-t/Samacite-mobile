import 'package:hive/hive.dart';
import 'package:mobile_samacite/core/models/category_model.dart';

part 'category_model_hive.g.dart';

/// Modèle Hive pour les catégories (cache local)
/// 
/// Adapter pour stocker CategoryModel dans Hive
/// TTL: 60s (spec.md - Phase 6)
@HiveType(typeId: 2) // typeId 1 utilisé par ReportModelHive
class CategoryModelHive extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String? icon;

  @HiveField(4)
  final String? createdAt;

  @HiveField(5)
  final String? updatedAt;

  CategoryModelHive({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.createdAt,
    this.updatedAt,
  });

  /// Convertit CategoryModel en CategoryModelHive pour stockage
  factory CategoryModelHive.fromCategoryModel(CategoryModel category) {
    return CategoryModelHive(
      id: category.id,
      name: category.name,
      description: category.description,
      icon: category.icon,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
  }

  /// Convertit CategoryModelHive en CategoryModel pour utilisation
  CategoryModel toCategoryModel() {
    return CategoryModel(
      id: id,
      name: name,
      description: description,
      icon: icon,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
