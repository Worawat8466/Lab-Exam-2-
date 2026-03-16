import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/parsed_receipt_data_dto.dart';

abstract class ReceiptAiRemoteDataSource {
  Future<ParsedReceiptDataDto> parseReceiptText(String rawText);
}

class ReceiptAiRemoteDataSourceImpl implements ReceiptAiRemoteDataSource {
  const ReceiptAiRemoteDataSourceImpl({required Dio dio, required String model})
    : _dio = dio,
      _model = model;

  final Dio _dio;
  final String _model;

  @override
  Future<ParsedReceiptDataDto> parseReceiptText(String rawText) async {
    final prompt =
        '''
You are a financial assistant that extracts data from receipt text.
Return JSON only with keys:
transactionType (expense|income),
merchant,
suggestedCategory,
amount,
currency,
suggestedTags (string array),
occurredAt (ISO-8601 or null),
reasoning,
confidence (0..1).
Receipt text:
$rawText
''';

    final response = await _dio.post<Map<String, dynamic>>(
      'models/$_model:generateContent',
      data: {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      },
    );

    final root = response.data ?? <String, dynamic>{};
    final candidates = (root['candidates'] as List?) ?? const [];
    if (candidates.isEmpty) {
      throw const FormatException('No AI candidates returned');
    }

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = (content?['parts'] as List?) ?? const [];
    if (parts.isEmpty) {
      throw const FormatException('No AI text content returned');
    }

    final rawJsonText = (parts.first['text'] as String?)?.trim() ?? '';
    if (rawJsonText.isEmpty) {
      throw const FormatException('AI text payload is empty');
    }

    final cleaned = rawJsonText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    return ParsedReceiptDataDto.fromJson(parsed);
  }
}
