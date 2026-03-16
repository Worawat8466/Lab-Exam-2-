import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/gemini_category_response_dto.dart';

abstract class GeminiRemoteDataSource {
  Future<GeminiCategoryResponseDto> categorize(String rawText);
}

class GeminiRemoteDataSourceImpl implements GeminiRemoteDataSource {
  const GeminiRemoteDataSourceImpl({required Dio dio, required String model})
    : _dio = dio,
      _model = model;

  final Dio _dio;
  final String _model;

  @override
  Future<GeminiCategoryResponseDto> categorize(String rawText) async {
    final prompt =
        '''
You are an assistant that categorizes receipt expenses.
Return JSON only, with keys: category, confidence, reason.
confidence must be a number between 0 and 1.
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
    return GeminiCategoryResponseDto.fromJson(parsed);
  }
}
