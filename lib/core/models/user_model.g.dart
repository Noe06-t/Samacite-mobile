// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      email: json['email'] as String?,
      telephone: json['telephone'] as String,
      createdAt: json['created_at'] as String? ?? null,
      updatedAt: json['updated_at'] as String? ?? null,
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'prenom': instance.prenom,
      'email': instance.email,
      'telephone': instance.telephone,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
