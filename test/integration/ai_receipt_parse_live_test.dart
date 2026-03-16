import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:labexam2/features/ai_categorization/data/datasources/receipt_ai_remote_data_source.dart';

void main() {
  test(
    'live AI parse: transfer slip text should return structured receipt data',
    () async {
      await dotenv.load(fileName: '.env');

      final apiKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
      if (apiKey.isEmpty) {
        fail('Missing GEMINI_API_KEY in .env for live AI test');
      }

      final model = dotenv.env['GEMINI_MODEL']?.trim().isNotEmpty == true
          ? dotenv.env['GEMINI_MODEL']!.trim()
          : 'gemini-2.5-flash';

      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
          queryParameters: {'key': apiKey},
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      final remote = ReceiptAiRemoteDataSourceImpl(dio: dio, model: model);

      // Text transcribed from the provided transfer slip image.
      const rawText = '''
โอนเงินสำเร็จ
รหัสอ้างอิง A0c07dc565a8e4cdb
จาก นายวรวรรษ ห***
ธนาคารกรุงไทย
XXX-X-XX482-5
ไปยัง นาย เอกชัย ยอมนิ
ไทยพาณิชย์
XXX-X-XX954-6
จำนวนเงิน 300.00 บาท
ค่าธรรมเนียม 0.00 บาท
วันที่ทำรายการ 06 มี.ค. 2569 - 12:27
''';

      final parsed = await remote.parseReceiptText(rawText);

      expect(parsed.merchant.trim().isNotEmpty, isTrue);
      expect(parsed.suggestedCategory.trim().isNotEmpty, isTrue);
      expect(parsed.amount, greaterThan(0));
      expect(parsed.currency.trim().isNotEmpty, isTrue);
      expect(parsed.confidence, greaterThanOrEqualTo(0));
      expect(parsed.confidence, lessThanOrEqualTo(1));
    },
  );
}
