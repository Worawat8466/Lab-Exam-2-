// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gemini_category_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GeminiCategoryResponseDtoImpl _$$GeminiCategoryResponseDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$GeminiCategoryResponseDtoImpl(
      category: json['category'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$$GeminiCategoryResponseDtoImplToJson(
        _$GeminiCategoryResponseDtoImpl instance) =>
    <String, dynamic>{
      'category': instance.category,
      'confidence': instance.confidence,
      'reason': instance.reason,
    };
