// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parsed_receipt_data_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ParsedReceiptDataDtoImpl _$$ParsedReceiptDataDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$ParsedReceiptDataDtoImpl(
      transactionType: json['transactionType'] as String,
      merchant: json['merchant'] as String,
      suggestedCategory: json['suggestedCategory'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      suggestedTags: (json['suggestedTags'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      occurredAt: json['occurredAt'] as String?,
      reasoning: json['reasoning'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );

Map<String, dynamic> _$$ParsedReceiptDataDtoImplToJson(
        _$ParsedReceiptDataDtoImpl instance) =>
    <String, dynamic>{
      'transactionType': instance.transactionType,
      'merchant': instance.merchant,
      'suggestedCategory': instance.suggestedCategory,
      'amount': instance.amount,
      'currency': instance.currency,
      'suggestedTags': instance.suggestedTags,
      'occurredAt': instance.occurredAt,
      'reasoning': instance.reasoning,
      'confidence': instance.confidence,
    };
