import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class SlipScanResult {
  const SlipScanResult({
    required this.amount,
    required this.receiverName,
    required this.category,
    required this.rawText,
    required this.cleanedText,
    required this.isValidSlip,
  });

  final double amount;
  final String receiverName;
  final String category;
  final String rawText;
  final String cleanedText;
  final bool isValidSlip;

  factory SlipScanResult.fromJson(Map<String, dynamic> json) {
    return SlipScanResult(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      receiverName: (json['receiver_name'] as String?)?.trim() ?? '',
      category: (json['category'] as String?)?.trim() ?? '',
      rawText: (json['raw_text'] as String?) ?? '',
      cleanedText: (json['cleaned_text'] as String?) ?? '',
      isValidSlip: json['is_valid_slip'] == true,
    );
  }
}

class SlipScannerService {
  const SlipScannerService({required Dio dio, String? model})
    : _dio = dio,
      _model = model;

  final Dio _dio;
  final String? _model;

  Future<SlipScanResult> scanFromImage(String imagePath) async {
    try {
      final qrPayload = await _scanQrPayload(imagePath);
      if (qrPayload == null || qrPayload.trim().isEmpty) {
        throw const FormatException('ไม่พบ QR Code บนสลิป');
      }

      final parsed = await _scanFromImageWithVision(
        imagePath,
        qrPayload: qrPayload,
      );
      if (parsed.amount <= 0) {
        throw const FormatException('Gemini ไม่สามารถสกัดยอดเงินได้');
      }

      return SlipScanResult(
        amount: parsed.amount,
        receiverName: parsed.receiverName,
        category: parsed.category,
        rawText: qrPayload,
        cleanedText: parsed.cleanedText,
        isValidSlip: true,
      );
    } catch (error) {
      throw Exception('AI ดึงข้อมูลจากสลิปไม่สำเร็จ: $error');
    }
  }

  Future<String?> _scanQrPayload(String imagePath) async {
    if (!kIsWeb && !(Platform.isAndroid || Platform.isIOS)) {
      throw UnsupportedError('การสแกน QR รองรับเฉพาะ Android/iOS runtime');
    }

    final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final barcodes = await scanner.processImage(inputImage);
      if (barcodes.isEmpty) {
        return null;
      }

      for (final barcode in barcodes) {
        final value = (barcode.rawValue ?? barcode.displayValue ?? '').trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
      return null;
    } finally {
      await scanner.close();
    }
  }

  Future<SlipScanResult> _scanFromImageWithVision(
    String imagePath, {
    required String qrPayload,
  }) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(imageBytes);
    final modelCandidates = _buildModelCandidates();

    DioException? lastModelException;
    Map<String, dynamic>? root;

    for (final model in modelCandidates) {
      try {
        final response = await _dio.post<Map<String, dynamic>>(
          'models/$model:generateContent',
          data: {
            'contents': [
              {
                'parts': [
                  {'text': _buildSystemPrompt(qrPayload: qrPayload)},
                  {
                    'inline_data': {
                      'mime_type': _guessMimeType(imagePath),
                      'data': base64Image,
                    },
                  },
                ],
              },
            ],
          },
        );
        root = response.data ?? <String, dynamic>{};
        break;
      } on DioException catch (error) {
        if (_isModelUnavailableError(error)) {
          lastModelException = error;
          continue;
        }
        rethrow;
      }
    }

    if (root == null) {
      if (lastModelException != null) {
        throw FormatException(
          'ไม่พบ model ที่ใช้งานได้สำหรับบัญชีนี้ (${modelCandidates.join(', ')})',
        );
      }
      throw const FormatException('เรียก AI ไม่สำเร็จ');
    }

    final candidates = (root['candidates'] as List?) ?? const [];
    if (candidates.isEmpty) {
      throw const FormatException('No AI candidates returned (vision)');
    }

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = (content?['parts'] as List?) ?? const [];
    if (parts.isEmpty) {
      throw const FormatException('No AI text content returned (vision)');
    }

    final rawJsonText = (parts.first['text'] as String?)?.trim() ?? '';
    if (rawJsonText.isEmpty) {
      throw const FormatException('AI text payload is empty (vision)');
    }

    try {
      final cleanedJson = rawJsonText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final parsed = jsonDecode(cleanedJson) as Map<String, dynamic>;
      final amount = (parsed['amount'] as num?)?.toDouble() ?? 0;
      final rawReceiverName =
          (parsed['receiver_name'] as String?)?.trim() ?? '';
      final receiverName = _cleanReceiverName(rawReceiverName);
      final category = _resolveSlipCategory(
        receiverName: receiverName,
        rawReceiverName: rawReceiverName,
      );
      final cleanedText = cleanedJson;

      return SlipScanResult(
        amount: amount,
        receiverName: receiverName,
        category: category,
        rawText: qrPayload,
        cleanedText: cleanedText,
        isValidSlip: amount > 0,
      );
    } catch (error) {
      throw FormatException('AI vision คืนค่า JSON ไม่ถูกต้อง: $error');
    }
  }

  List<String> _buildModelCandidates() {
    final ordered = <String>[
      if ((_model ?? '').trim().isNotEmpty) _model!.trim(),
      if ((dotenv.env['GEMINI_SCAN_MODEL'] ?? '').trim().isNotEmpty)
        dotenv.env['GEMINI_SCAN_MODEL']!.trim(),
      if ((dotenv.env['GEMINI_MODEL'] ?? '').trim().isNotEmpty)
        dotenv.env['GEMINI_MODEL']!.trim(),
      'gemini-3-flash',
      'gemini-2.5-flash',
      'gemini-1.5-flash',
    ];

    final unique = <String>{};
    return ordered.where((m) => unique.add(m)).toList(growable: false);
  }

  bool _isModelUnavailableError(DioException error) {
    final status = error.response?.statusCode ?? 0;
    if (status != 400 && status != 404) {
      return false;
    }

    final body = error.response?.data;
    final text = body is String
        ? body.toLowerCase()
        : body.toString().toLowerCase();
    return text.contains('model') &&
        (text.contains('not found') ||
            text.contains('is not supported') ||
            text.contains('not available') ||
            text.contains('permission') ||
            text.contains('not enabled'));
  }
}

String _guessMimeType(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  return 'image/jpeg';
}

String _cleanReceiverName(String name) {
  return name
      .replaceAll(RegExp(r'^\s*(นาย|นางสาว|นาง|บริษัท|หจก\.|บจก\.)\s*'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

const List<String> _foodKeywords = [
  'โบนัสสุกี้',
  'สุกี้',
  'ชาบู',
  'หมูกระทะ',
  'ร้านข้าว',
  'ก๋วยเตี๋ยว',
  'อาหาร',
  'คาเฟ่',
  'กาแฟ',
  'ชา',
  'cafe',
  'coffee',
  'café',
  'food',
  'restaurant',
  'grabfood',
  'line man',
  'lineman',
  'kfc',
  'pizza',
];

const List<String> _shoppingKeywords = [
  'mr.diy',
  'mr diy',
  'diy',
  '7-11',
  '7 eleven',
  'เซเว่น',
  'โลตัส',
  'บิ๊กซี',
  'ห้าง',
  'ร้านค้า',
  'ร้านขายของ',
  'กิ๊ฟช็อป',
  'ช็อป',
  'shop',
  'store',
  'mart',
  'mall',
  'plaza',
  'supermarket',
  'department',
  'lazada',
  'shopee',
  'central',
  'robinson',
  'big c',
  'lotus',
  '7eleven',
];

const List<String> _nonPersonKeywords = [
  'บริษัท',
  'บจก',
  'หจก',
  'co.',
  'co ',
  'ltd',
  'inc',
  'corp',
  'shop',
  'store',
  'mall',
  'mart',
  'plaza',
  'restaurant',
  'cafe',
  'coffee',
  'ห้าง',
  'ร้าน',
  'diy',
  'โลตัส',
  'บิ๊กซี',
  '7-11',
];

const List<String> _personTitleKeywords = [
  'นาย',
  'นาง',
  'น.ส.',
  'น.ส',
  'mr',
  'mrs',
  'ms',
];

String _resolveSlipCategory({
  required String receiverName,
  required String rawReceiverName,
}) {
  final name = receiverName.trim().toLowerCase();
  final rawName = rawReceiverName.trim().toLowerCase();

  if (_containsAny(rawName, _personTitleKeywords)) {
    return 'โอนเงิน';
  }

  if (name.isEmpty) {
    return 'โอนเงิน';
  }

  if (_containsAny(name, _foodKeywords)) {
    return 'อาหาร';
  }

  if (_containsAny(name, _shoppingKeywords)) {
    return 'ช็อปปิ้ง';
  }

  if (_looksLikePersonName(name)) {
    return 'โอนเงิน';
  }

  return 'โอนเงิน';
}

bool _containsAny(String text, List<String> keywords) {
  for (final keyword in keywords) {
    if (text.contains(keyword)) {
      return true;
    }
  }
  return false;
}

bool _looksLikePersonName(String lowerName) {
  if (_containsAny(lowerName, _nonPersonKeywords)) {
    return false;
  }

  // Rough heuristic: short Thai/English names without business terms.
  final words = lowerName
      .split(RegExp(r'\s+'))
      .where((entry) => entry.isNotEmpty)
      .toList();
  if (words.isEmpty || words.length > 4) {
    return false;
  }

  final hasThaiOrLatin = RegExp(r'[a-zก-ฮ]').hasMatch(lowerName);
  return hasThaiOrLatin;
}

String _buildSystemPrompt({required String qrPayload}) {
  return '''รูปภาพที่แนบมานี้คือสลิปโอนเงินธนาคารของไทย โปรดทำหน้าที่เป็น OCR สกัดข้อมูลสำคัญออกมา ได้แก่ 1. ยอดเงิน (เป็นตัวเลขทศนิยม) 2. ชื่อผู้รับเงิน (ตัดคำว่านาย/นาง/บริษัทออกให้กระชับ)

ตอบกลับมาเป็น JSON Format ตามโครงสร้างนี้เท่านั้น ห้ามมีข้อความอื่น: {"amount": 0.00, "receiver_name": "...", "category": "โอนเงิน"}

ข้อมูล QR ที่สแกนได้จากสลิป:
$qrPayload''';
}
