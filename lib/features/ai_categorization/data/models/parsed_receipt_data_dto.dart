import 'package:freezed_annotation/freezed_annotation.dart';

part 'parsed_receipt_data_dto.freezed.dart';
part 'parsed_receipt_data_dto.g.dart';

@freezed
class ParsedReceiptDataDto with _$ParsedReceiptDataDto {
  const factory ParsedReceiptDataDto({
    required String transactionType,
    required String merchant,
    required String suggestedCategory,
    required double amount,
    required String currency,
    required List<String> suggestedTags,
    String? occurredAt,
    required String reasoning,
    required double confidence,
  }) = _ParsedReceiptDataDto;

  factory ParsedReceiptDataDto.fromJson(Map<String, dynamic> json) =>
      _$ParsedReceiptDataDtoFromJson(json);
}
