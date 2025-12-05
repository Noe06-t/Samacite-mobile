// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ReportListState {
  /// Liste des signalements chargés
  List<ReportModel> get reports => throw _privateConstructorUsedError;

  /// Indique si un chargement est en cours
  bool get isLoading => throw _privateConstructorUsedError;

  /// Indique s'il reste des données à charger
  bool get hasMore => throw _privateConstructorUsedError;

  /// Page actuelle de la pagination
  int get currentPage => throw _privateConstructorUsedError;

  /// Message d'erreur en cas de problème
  String? get errorMessage => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ReportListStateCopyWith<ReportListState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReportListStateCopyWith<$Res> {
  factory $ReportListStateCopyWith(
          ReportListState value, $Res Function(ReportListState) then) =
      _$ReportListStateCopyWithImpl<$Res, ReportListState>;
  @useResult
  $Res call(
      {List<ReportModel> reports,
      bool isLoading,
      bool hasMore,
      int currentPage,
      String? errorMessage});
}

/// @nodoc
class _$ReportListStateCopyWithImpl<$Res, $Val extends ReportListState>
    implements $ReportListStateCopyWith<$Res> {
  _$ReportListStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reports = null,
    Object? isLoading = null,
    Object? hasMore = null,
    Object? currentPage = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      reports: null == reports
          ? _value.reports
          : reports // ignore: cast_nullable_to_non_nullable
              as List<ReportModel>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReportListStateImplCopyWith<$Res>
    implements $ReportListStateCopyWith<$Res> {
  factory _$$ReportListStateImplCopyWith(_$ReportListStateImpl value,
          $Res Function(_$ReportListStateImpl) then) =
      __$$ReportListStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<ReportModel> reports,
      bool isLoading,
      bool hasMore,
      int currentPage,
      String? errorMessage});
}

/// @nodoc
class __$$ReportListStateImplCopyWithImpl<$Res>
    extends _$ReportListStateCopyWithImpl<$Res, _$ReportListStateImpl>
    implements _$$ReportListStateImplCopyWith<$Res> {
  __$$ReportListStateImplCopyWithImpl(
      _$ReportListStateImpl _value, $Res Function(_$ReportListStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reports = null,
    Object? isLoading = null,
    Object? hasMore = null,
    Object? currentPage = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_$ReportListStateImpl(
      reports: null == reports
          ? _value._reports
          : reports // ignore: cast_nullable_to_non_nullable
              as List<ReportModel>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      currentPage: null == currentPage
          ? _value.currentPage
          : currentPage // ignore: cast_nullable_to_non_nullable
              as int,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ReportListStateImpl implements _ReportListState {
  const _$ReportListStateImpl(
      {required final List<ReportModel> reports,
      required this.isLoading,
      required this.hasMore,
      required this.currentPage,
      this.errorMessage})
      : _reports = reports;

  /// Liste des signalements chargés
  final List<ReportModel> _reports;

  /// Liste des signalements chargés
  @override
  List<ReportModel> get reports {
    if (_reports is EqualUnmodifiableListView) return _reports;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reports);
  }

  /// Indique si un chargement est en cours
  @override
  final bool isLoading;

  /// Indique s'il reste des données à charger
  @override
  final bool hasMore;

  /// Page actuelle de la pagination
  @override
  final int currentPage;

  /// Message d'erreur en cas de problème
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'ReportListState(reports: $reports, isLoading: $isLoading, hasMore: $hasMore, currentPage: $currentPage, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReportListStateImpl &&
            const DeepCollectionEquality().equals(other._reports, _reports) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_reports),
      isLoading,
      hasMore,
      currentPage,
      errorMessage);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReportListStateImplCopyWith<_$ReportListStateImpl> get copyWith =>
      __$$ReportListStateImplCopyWithImpl<_$ReportListStateImpl>(
          this, _$identity);
}

abstract class _ReportListState implements ReportListState {
  const factory _ReportListState(
      {required final List<ReportModel> reports,
      required final bool isLoading,
      required final bool hasMore,
      required final int currentPage,
      final String? errorMessage}) = _$ReportListStateImpl;

  @override

  /// Liste des signalements chargés
  List<ReportModel> get reports;
  @override

  /// Indique si un chargement est en cours
  bool get isLoading;
  @override

  /// Indique s'il reste des données à charger
  bool get hasMore;
  @override

  /// Page actuelle de la pagination
  int get currentPage;
  @override

  /// Message d'erreur en cas de problème
  String? get errorMessage;
  @override
  @JsonKey(ignore: true)
  _$$ReportListStateImplCopyWith<_$ReportListStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
