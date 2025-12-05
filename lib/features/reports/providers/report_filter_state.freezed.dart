// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report_filter_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ReportFilterState {
  /// Filtre par statut (null = tous)
  /// Valeurs possibles: 'pending', 'in_progress', 'resolved'
  String? get status => throw _privateConstructorUsedError;

  /// Filtre par catégorie ID (null = toutes)
  int? get categoryId => throw _privateConstructorUsedError;

  /// Date de début (pour filtrer par plage)
  DateTime? get startDate => throw _privateConstructorUsedError;

  /// Date de fin (pour filtrer par plage)
  DateTime? get endDate => throw _privateConstructorUsedError;

  /// Recherche textuelle (titre ou description)
  String get searchQuery => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ReportFilterStateCopyWith<ReportFilterState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReportFilterStateCopyWith<$Res> {
  factory $ReportFilterStateCopyWith(
          ReportFilterState value, $Res Function(ReportFilterState) then) =
      _$ReportFilterStateCopyWithImpl<$Res, ReportFilterState>;
  @useResult
  $Res call(
      {String? status,
      int? categoryId,
      DateTime? startDate,
      DateTime? endDate,
      String searchQuery});
}

/// @nodoc
class _$ReportFilterStateCopyWithImpl<$Res, $Val extends ReportFilterState>
    implements $ReportFilterStateCopyWith<$Res> {
  _$ReportFilterStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = freezed,
    Object? categoryId = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? searchQuery = null,
  }) {
    return _then(_value.copyWith(
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as int?,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      searchQuery: null == searchQuery
          ? _value.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReportFilterStateImplCopyWith<$Res>
    implements $ReportFilterStateCopyWith<$Res> {
  factory _$$ReportFilterStateImplCopyWith(_$ReportFilterStateImpl value,
          $Res Function(_$ReportFilterStateImpl) then) =
      __$$ReportFilterStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? status,
      int? categoryId,
      DateTime? startDate,
      DateTime? endDate,
      String searchQuery});
}

/// @nodoc
class __$$ReportFilterStateImplCopyWithImpl<$Res>
    extends _$ReportFilterStateCopyWithImpl<$Res, _$ReportFilterStateImpl>
    implements _$$ReportFilterStateImplCopyWith<$Res> {
  __$$ReportFilterStateImplCopyWithImpl(_$ReportFilterStateImpl _value,
      $Res Function(_$ReportFilterStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = freezed,
    Object? categoryId = freezed,
    Object? startDate = freezed,
    Object? endDate = freezed,
    Object? searchQuery = null,
  }) {
    return _then(_$ReportFilterStateImpl(
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as int?,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      endDate: freezed == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      searchQuery: null == searchQuery
          ? _value.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ReportFilterStateImpl extends _ReportFilterState {
  const _$ReportFilterStateImpl(
      {this.status,
      this.categoryId,
      this.startDate,
      this.endDate,
      this.searchQuery = ''})
      : super._();

  /// Filtre par statut (null = tous)
  /// Valeurs possibles: 'pending', 'in_progress', 'resolved'
  @override
  final String? status;

  /// Filtre par catégorie ID (null = toutes)
  @override
  final int? categoryId;

  /// Date de début (pour filtrer par plage)
  @override
  final DateTime? startDate;

  /// Date de fin (pour filtrer par plage)
  @override
  final DateTime? endDate;

  /// Recherche textuelle (titre ou description)
  @override
  @JsonKey()
  final String searchQuery;

  @override
  String toString() {
    return 'ReportFilterState(status: $status, categoryId: $categoryId, startDate: $startDate, endDate: $endDate, searchQuery: $searchQuery)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReportFilterStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, status, categoryId, startDate, endDate, searchQuery);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReportFilterStateImplCopyWith<_$ReportFilterStateImpl> get copyWith =>
      __$$ReportFilterStateImplCopyWithImpl<_$ReportFilterStateImpl>(
          this, _$identity);
}

abstract class _ReportFilterState extends ReportFilterState {
  const factory _ReportFilterState(
      {final String? status,
      final int? categoryId,
      final DateTime? startDate,
      final DateTime? endDate,
      final String searchQuery}) = _$ReportFilterStateImpl;
  const _ReportFilterState._() : super._();

  @override

  /// Filtre par statut (null = tous)
  /// Valeurs possibles: 'pending', 'in_progress', 'resolved'
  String? get status;
  @override

  /// Filtre par catégorie ID (null = toutes)
  int? get categoryId;
  @override

  /// Date de début (pour filtrer par plage)
  DateTime? get startDate;
  @override

  /// Date de fin (pour filtrer par plage)
  DateTime? get endDate;
  @override

  /// Recherche textuelle (titre ou description)
  String get searchQuery;
  @override
  @JsonKey(ignore: true)
  _$$ReportFilterStateImplCopyWith<_$ReportFilterStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
