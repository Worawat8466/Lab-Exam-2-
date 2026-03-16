import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/parsed_receipt_data_dto.dart';

abstract class ReceiptAiCacheDataSource {
  Future<ParsedReceiptDataDto?> getCached(String rawText);
  Future<void> save(String rawText, ParsedReceiptDataDto result);
}

class ReceiptAiCacheDataSourceImpl implements ReceiptAiCacheDataSource {
  const ReceiptAiCacheDataSourceImpl(this._box);

  final Box<String> _box;

  @override
  Future<ParsedReceiptDataDto?> getCached(String rawText) async {
    final cached = _box.get(_key(rawText));
    if (cached == null) {
      return null;
    }

    final json = jsonDecode(cached) as Map<String, dynamic>;
    return ParsedReceiptDataDto.fromJson(json);
  }

  @override
  Future<void> save(String rawText, ParsedReceiptDataDto result) async {
    await _box.put(_key(rawText), jsonEncode(result.toJson()));
  }

  String _key(String rawText) => 'receipt_parse_${rawText.trim().hashCode}';
}
