// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommentModelImpl _$$CommentModelImplFromJson(Map<String, dynamic> json) =>
    _$CommentModelImpl(
      id: const IntConverter().fromJson(json['id']),
      content: json['content'] as String,
      reportId: const IntConverter().fromJson(json['report_id']),
      userId: const IntConverter().fromJson(json['user_id']),
      user: json['user'] == null
          ? null
          : CommentUser.fromJson(json['user'] as Map<String, dynamic>),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$$CommentModelImplToJson(_$CommentModelImpl instance) =>
    <String, dynamic>{
      'id': const IntConverter().toJson(instance.id),
      'content': instance.content,
      'report_id': const IntConverter().toJson(instance.reportId),
      'user_id': const IntConverter().toJson(instance.userId),
      'user': instance.user,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

_$CommentUserImpl _$$CommentUserImplFromJson(Map<String, dynamic> json) =>
    _$CommentUserImpl(
      id: const IntConverter().fromJson(json['id']),
      nom: json['nom'] as String?,
      prenom: json['prenom'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      telephone: json['telephone'] as String?,
    );

Map<String, dynamic> _$$CommentUserImplToJson(_$CommentUserImpl instance) =>
    <String, dynamic>{
      'id': const IntConverter().toJson(instance.id),
      'nom': instance.nom,
      'prenom': instance.prenom,
      'name': instance.name,
      'email': instance.email,
      'telephone': instance.telephone,
    };
