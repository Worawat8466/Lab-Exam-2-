import 'package:freezed_annotation/freezed_annotation.dart';

part 'gemini_category_response_dto.freezed.dart';
part 'gemini_category_response_dto.g.dart';

@freezed
class GeminiCategoryResponseDto with _$GeminiCategoryResponseDto {
  const factory GeminiCategoryResponseDto({
    required String category,
    required double confidence,
    required String reason,
  }) = _GeminiCategoryResponseDto;

  factory GeminiCategoryResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GeminiCategoryResponseDtoFromJson(json);
}
