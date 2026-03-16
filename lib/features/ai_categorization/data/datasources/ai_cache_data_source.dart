import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/gemini_category_response_dto.dart';

abstract class AiCacheDataSource {
  Future<GeminiCategoryResponseDto?> getCached(String rawText);
  Future<void> save(String rawText, GeminiCategoryResponseDto result);
}

class AiCacheDataSourceImpl implements AiCacheDataSource {
  const AiCacheDataSourceImpl(this._box);

  final Box<String> _box;

  @override
  Future<GeminiCategoryResponseDto?> getCached(String rawText) async {
    final cached = _box.get(_key(rawText));
    if (cached == null) {
      return null;
    }

    final json = jsonDecode(cached) as Map<String, dynamic>;
    return GeminiCategoryResponseDto.fromJson(json);
  }

  @override
  Future<void> save(String rawText, GeminiCategoryResponseDto result) async {
    await _box.put(_key(rawText), jsonEncode(result.toJson()));
  }

  String _key(String rawText) => rawText.trim().hashCode.toString();
}
