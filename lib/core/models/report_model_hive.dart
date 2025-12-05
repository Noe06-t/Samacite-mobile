import 'package:hive/hive.dart';
import 'report_model.dart';

part 'report_model_hive.g.dart';

@HiveType(typeId: 1)
class ReportModelHive extends HiveObject {
  @HiveField(0)
  int id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String description;
  @HiveField(3)
  String status;
  @HiveField(4)
  int categoryId;
  @HiveField(5)
  int userId;
  @HiveField(6)
  List<String> images;
  @HiveField(7)
  int likesCount;
  @HiveField(8)
  bool isLiked;
  @HiveField(9)
  String? createdAt;
  @HiveField(10)
  String? updatedAt;

  ReportModelHive({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.categoryId,
    required this.userId,
    required this.images,
    required this.likesCount,
    required this.isLiked,
    this.createdAt,
    this.updatedAt,
  });

  factory ReportModelHive.fromReportModel(ReportModel model) {
    return ReportModelHive(
      id: model.id,
      title: model.title,
      description: model.description,
      status: model.status,
      categoryId: model.categoryId,
      userId: model.userId,
      images: model.images,
      likesCount: model.likesCount,
      isLiked: model.isLiked,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  ReportModel toReportModel() {
    return ReportModel(
      id: id,
      title: title,
      description: description,
      status: status,
      categoryId: categoryId,
      userId: userId,
      images: images,
      likesCount: likesCount,
      isLiked: isLiked,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
