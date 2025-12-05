// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CommentModel _$CommentModelFromJson(Map<String, dynamic> json) {
  return _CommentModel.fromJson(json);
}

/// @nodoc
mixin _$CommentModel {
  @IntConverter()
  int get id => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  @IntConverter()
  @JsonKey(name: 'report_id')
  int get reportId => throw _privateConstructorUsedError;
  @IntConverter()
  @JsonKey(name: 'user_id')
  int get userId =>
      throw _privateConstructorUsedError; // Relation user (optionnelle si pas chargée)
  CommentUser? get user => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String? get updatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CommentModelCopyWith<CommentModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommentModelCopyWith<$Res> {
  factory $CommentModelCopyWith(
          CommentModel value, $Res Function(CommentModel) then) =
      _$CommentModelCopyWithImpl<$Res, CommentModel>;
  @useResult
  $Res call(
      {@IntConverter() int id,
      String content,
      @IntConverter() @JsonKey(name: 'report_id') int reportId,
      @IntConverter() @JsonKey(name: 'user_id') int userId,
      CommentUser? user,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'updated_at') String? updatedAt});

  $CommentUserCopyWith<$Res>? get user;
}

/// @nodoc
class _$CommentModelCopyWithImpl<$Res, $Val extends CommentModel>
    implements $CommentModelCopyWith<$Res> {
  _$CommentModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? reportId = null,
    Object? userId = null,
    Object? user = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      reportId: null == reportId
          ? _value.reportId
          : reportId // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as CommentUser?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $CommentUserCopyWith<$Res>? get user {
    if (_value.user == null) {
      return null;
    }

    return $CommentUserCopyWith<$Res>(_value.user!, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CommentModelImplCopyWith<$Res>
    implements $CommentModelCopyWith<$Res> {
  factory _$$CommentModelImplCopyWith(
          _$CommentModelImpl value, $Res Function(_$CommentModelImpl) then) =
      __$$CommentModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@IntConverter() int id,
      String content,
      @IntConverter() @JsonKey(name: 'report_id') int reportId,
      @IntConverter() @JsonKey(name: 'user_id') int userId,
      CommentUser? user,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'updated_at') String? updatedAt});

  @override
  $CommentUserCopyWith<$Res>? get user;
}

/// @nodoc
class __$$CommentModelImplCopyWithImpl<$Res>
    extends _$CommentModelCopyWithImpl<$Res, _$CommentModelImpl>
    implements _$$CommentModelImplCopyWith<$Res> {
  __$$CommentModelImplCopyWithImpl(
      _$CommentModelImpl _value, $Res Function(_$CommentModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? reportId = null,
    Object? userId = null,
    Object? user = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$CommentModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      reportId: null == reportId
          ? _value.reportId
          : reportId // ignore: cast_nullable_to_non_nullable
              as int,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as CommentUser?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CommentModelImpl implements _CommentModel {
  const _$CommentModelImpl(
      {@IntConverter() required this.id,
      required this.content,
      @IntConverter() @JsonKey(name: 'report_id') required this.reportId,
      @IntConverter() @JsonKey(name: 'user_id') required this.userId,
      this.user,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt});

  factory _$CommentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommentModelImplFromJson(json);

  @override
  @IntConverter()
  final int id;
  @override
  final String content;
  @override
  @IntConverter()
  @JsonKey(name: 'report_id')
  final int reportId;
  @override
  @IntConverter()
  @JsonKey(name: 'user_id')
  final int userId;
// Relation user (optionnelle si pas chargée)
  @override
  final CommentUser? user;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  @override
  String toString() {
    return 'CommentModel(id: $id, content: $content, reportId: $reportId, userId: $userId, user: $user, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommentModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.reportId, reportId) ||
                other.reportId == reportId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, content, reportId, userId, user, createdAt, updatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CommentModelImplCopyWith<_$CommentModelImpl> get copyWith =>
      __$$CommentModelImplCopyWithImpl<_$CommentModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CommentModelImplToJson(
      this,
    );
  }
}

abstract class _CommentModel implements CommentModel {
  const factory _CommentModel(
      {@IntConverter() required final int id,
      required final String content,
      @IntConverter() @JsonKey(name: 'report_id') required final int reportId,
      @IntConverter() @JsonKey(name: 'user_id') required final int userId,
      final CommentUser? user,
      @JsonKey(name: 'created_at') final String? createdAt,
      @JsonKey(name: 'updated_at')
      final String? updatedAt}) = _$CommentModelImpl;

  factory _CommentModel.fromJson(Map<String, dynamic> json) =
      _$CommentModelImpl.fromJson;

  @override
  @IntConverter()
  int get id;
  @override
  String get content;
  @override
  @IntConverter()
  @JsonKey(name: 'report_id')
  int get reportId;
  @override
  @IntConverter()
  @JsonKey(name: 'user_id')
  int get userId;
  @override // Relation user (optionnelle si pas chargée)
  CommentUser? get user;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  String? get updatedAt;
  @override
  @JsonKey(ignore: true)
  _$$CommentModelImplCopyWith<_$CommentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CommentUser _$CommentUserFromJson(Map<String, dynamic> json) {
  return _CommentUser.fromJson(json);
}

/// @nodoc
mixin _$CommentUser {
  @IntConverter()
  int get id =>
      throw _privateConstructorUsedError; // Format complet (depuis UserModel)
  String? get nom => throw _privateConstructorUsedError;
  String? get prenom =>
      throw _privateConstructorUsedError; // Format minimal (depuis backend comments)
  String? get name => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get telephone => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CommentUserCopyWith<CommentUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommentUserCopyWith<$Res> {
  factory $CommentUserCopyWith(
          CommentUser value, $Res Function(CommentUser) then) =
      _$CommentUserCopyWithImpl<$Res, CommentUser>;
  @useResult
  $Res call(
      {@IntConverter() int id,
      String? nom,
      String? prenom,
      String? name,
      String? email,
      String? telephone});
}

/// @nodoc
class _$CommentUserCopyWithImpl<$Res, $Val extends CommentUser>
    implements $CommentUserCopyWith<$Res> {
  _$CommentUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nom = freezed,
    Object? prenom = freezed,
    Object? name = freezed,
    Object? email = freezed,
    Object? telephone = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      nom: freezed == nom
          ? _value.nom
          : nom // ignore: cast_nullable_to_non_nullable
              as String?,
      prenom: freezed == prenom
          ? _value.prenom
          : prenom // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      telephone: freezed == telephone
          ? _value.telephone
          : telephone // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CommentUserImplCopyWith<$Res>
    implements $CommentUserCopyWith<$Res> {
  factory _$$CommentUserImplCopyWith(
          _$CommentUserImpl value, $Res Function(_$CommentUserImpl) then) =
      __$$CommentUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@IntConverter() int id,
      String? nom,
      String? prenom,
      String? name,
      String? email,
      String? telephone});
}

/// @nodoc
class __$$CommentUserImplCopyWithImpl<$Res>
    extends _$CommentUserCopyWithImpl<$Res, _$CommentUserImpl>
    implements _$$CommentUserImplCopyWith<$Res> {
  __$$CommentUserImplCopyWithImpl(
      _$CommentUserImpl _value, $Res Function(_$CommentUserImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nom = freezed,
    Object? prenom = freezed,
    Object? name = freezed,
    Object? email = freezed,
    Object? telephone = freezed,
  }) {
    return _then(_$CommentUserImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      nom: freezed == nom
          ? _value.nom
          : nom // ignore: cast_nullable_to_non_nullable
              as String?,
      prenom: freezed == prenom
          ? _value.prenom
          : prenom // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      telephone: freezed == telephone
          ? _value.telephone
          : telephone // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CommentUserImpl implements _CommentUser {
  const _$CommentUserImpl(
      {@IntConverter() required this.id,
      this.nom,
      this.prenom,
      this.name,
      this.email,
      this.telephone});

  factory _$CommentUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommentUserImplFromJson(json);

  @override
  @IntConverter()
  final int id;
// Format complet (depuis UserModel)
  @override
  final String? nom;
  @override
  final String? prenom;
// Format minimal (depuis backend comments)
  @override
  final String? name;
  @override
  final String? email;
  @override
  final String? telephone;

  @override
  String toString() {
    return 'CommentUser(id: $id, nom: $nom, prenom: $prenom, name: $name, email: $email, telephone: $telephone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommentUserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nom, nom) || other.nom == nom) &&
            (identical(other.prenom, prenom) || other.prenom == prenom) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.telephone, telephone) ||
                other.telephone == telephone));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, nom, prenom, name, email, telephone);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CommentUserImplCopyWith<_$CommentUserImpl> get copyWith =>
      __$$CommentUserImplCopyWithImpl<_$CommentUserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CommentUserImplToJson(
      this,
    );
  }
}

abstract class _CommentUser implements CommentUser {
  const factory _CommentUser(
      {@IntConverter() required final int id,
      final String? nom,
      final String? prenom,
      final String? name,
      final String? email,
      final String? telephone}) = _$CommentUserImpl;

  factory _CommentUser.fromJson(Map<String, dynamic> json) =
      _$CommentUserImpl.fromJson;

  @override
  @IntConverter()
  int get id;
  @override // Format complet (depuis UserModel)
  String? get nom;
  @override
  String? get prenom;
  @override // Format minimal (depuis backend comments)
  String? get name;
  @override
  String? get email;
  @override
  String? get telephone;
  @override
  @JsonKey(ignore: true)
  _$$CommentUserImplCopyWith<_$CommentUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
