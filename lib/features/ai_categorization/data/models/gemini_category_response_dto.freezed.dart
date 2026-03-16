// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gemini_category_response_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GeminiCategoryResponseDto _$GeminiCategoryResponseDtoFromJson(
    Map<String, dynamic> json) {
  return _GeminiCategoryResponseDto.fromJson(json);
}

/// @nodoc
mixin _$GeminiCategoryResponseDto {
  String get category => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GeminiCategoryResponseDtoCopyWith<GeminiCategoryResponseDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GeminiCategoryResponseDtoCopyWith<$Res> {
  factory $GeminiCategoryResponseDtoCopyWith(GeminiCategoryResponseDto value,
          $Res Function(GeminiCategoryResponseDto) then) =
      _$GeminiCategoryResponseDtoCopyWithImpl<$Res, GeminiCategoryResponseDto>;
  @useResult
  $Res call({String category, double confidence, String reason});
}

/// @nodoc
class _$GeminiCategoryResponseDtoCopyWithImpl<$Res,
        $Val extends GeminiCategoryResponseDto>
    implements $GeminiCategoryResponseDtoCopyWith<$Res> {
  _$GeminiCategoryResponseDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? confidence = null,
    Object? reason = null,
  }) {
    return _then(_value.copyWith(
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GeminiCategoryResponseDtoImplCopyWith<$Res>
    implements $GeminiCategoryResponseDtoCopyWith<$Res> {
  factory _$$GeminiCategoryResponseDtoImplCopyWith(
          _$GeminiCategoryResponseDtoImpl value,
          $Res Function(_$GeminiCategoryResponseDtoImpl) then) =
      __$$GeminiCategoryResponseDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String category, double confidence, String reason});
}

/// @nodoc
class __$$GeminiCategoryResponseDtoImplCopyWithImpl<$Res>
    extends _$GeminiCategoryResponseDtoCopyWithImpl<$Res,
        _$GeminiCategoryResponseDtoImpl>
    implements _$$GeminiCategoryResponseDtoImplCopyWith<$Res> {
  __$$GeminiCategoryResponseDtoImplCopyWithImpl(
      _$GeminiCategoryResponseDtoImpl _value,
      $Res Function(_$GeminiCategoryResponseDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? confidence = null,
    Object? reason = null,
  }) {
    return _then(_$GeminiCategoryResponseDtoImpl(
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GeminiCategoryResponseDtoImpl implements _GeminiCategoryResponseDto {
  const _$GeminiCategoryResponseDtoImpl(
      {required this.category, required this.confidence, required this.reason});

  factory _$GeminiCategoryResponseDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$GeminiCategoryResponseDtoImplFromJson(json);

  @override
  final String category;
  @override
  final double confidence;
  @override
  final String reason;

  @override
  String toString() {
    return 'GeminiCategoryResponseDto(category: $category, confidence: $confidence, reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GeminiCategoryResponseDtoImpl &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, category, confidence, reason);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GeminiCategoryResponseDtoImplCopyWith<_$GeminiCategoryResponseDtoImpl>
      get copyWith => __$$GeminiCategoryResponseDtoImplCopyWithImpl<
          _$GeminiCategoryResponseDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GeminiCategoryResponseDtoImplToJson(
      this,
    );
  }
}

abstract class _GeminiCategoryResponseDto implements GeminiCategoryResponseDto {
  const factory _GeminiCategoryResponseDto(
      {required final String category,
      required final double confidence,
      required final String reason}) = _$GeminiCategoryResponseDtoImpl;

  factory _GeminiCategoryResponseDto.fromJson(Map<String, dynamic> json) =
      _$GeminiCategoryResponseDtoImpl.fromJson;

  @override
  String get category;
  @override
  double get confidence;
  @override
  String get reason;
  @override
  @JsonKey(ignore: true)
  _$$GeminiCategoryResponseDtoImplCopyWith<_$GeminiCategoryResponseDtoImpl>
      get copyWith => throw _privateConstructorUsedError;
}
