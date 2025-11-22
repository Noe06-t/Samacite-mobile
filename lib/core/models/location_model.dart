import 'package:freezed_annotation/freezed_annotation.dart';

part 'location_model.freezed.dart';
part 'location_model.g.dart';

/// Modèle pour la géolocalisation d'un signalement
/// 
/// Contient les coordonnées GPS (latitude/longitude) et optionnellement l'adresse
@freezed
class LocationModel with _$LocationModel {
  const factory LocationModel({
    required double latitude,
    required double longitude,
    String? address, // Adresse textuelle (optionnelle)
  }) = _LocationModel;

  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);
}
