import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/service_locator.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/summary_period.dart';

final aiInsightNotifierProvider =
    AsyncNotifierProvider<AiInsightNotifier, String>(AiInsightNotifier.new);

class AiInsightNotifier extends AsyncNotifier<String> {
  int _requestCount = 0;

  @override
  FutureOr<String> build() => ''; // empty = not yet analyzed

  Future<void> analyze(DashboardSummary summary) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      _requestCount += 1;
      final insight = await _callGemini(summary).timeout(
        const Duration(seconds: 12),
        onTimeout: () => _fallbackInsight(summary),
      );
      return insight;
    });
  }

  Future<String> _callGemini(DashboardSummary summary) async {
    final dio = sl<Dio>();
    final modelCandidates = _buildModelCandidates();

    final categoryLines = summary.topCategories
        .take(5)
        .map(
          (c) =>
              '- ${c.categoryName}: ฿${c.totalAmount.toStringAsFixed(2)} (${c.percentage.toStringAsFixed(1)}%)',
        )
        .join('\n');

    final periodLabel = switch (summary.period) {
      SummaryPeriod.weekly => 'สัปดาห์นี้',
      SummaryPeriod.monthly => 'เดือนนี้',
      SummaryPeriod.quarterly => 'ไตรมาสนี้',
      SummaryPeriod.yearly => 'ปีนี้',
    };

    final changeSign = summary.comparison.percentChange >= 0 ? '+' : '';
    final focus = switch (_requestCount % 3) {
      0 => 'แนะนำวิธีประหยัดเงินในหมวดที่จ่ายเยอะที่สุด',
      1 => 'ให้กำลังใจและชื่นชมหากมีเงินเหลือ พร้อมแนะนำการออมเพิ่ม',
      _ => 'เตือนสติเกี่ยวกับการใช้จ่ายที่สูงขึ้นในรอบนี้',
    };

    final prompt =
        '''คุณคือผู้ช่วยอัจฉริยะด้านการเงินส่วนบุคคล (Smart Financial Assistant) ที่มีความเชี่ยวชาญ แต่พูดคุยด้วยน้ำเสียงที่เป็นมิตร อบอุ่น เป็นธรรมชาติ และให้กำลังใจเหมือนเพื่อนที่หวังดี
ตอบเป็นภาษาไทยที่อ่านง่าย สละสลวย ไม่เป็นทางการจนเกินไป แต่ดูล้ำสมัยและน่าเชื่อถือ
ห้ามใช้ Bullet, ห้ามใช้หมายเลขข้อ, ห้ามใช้ Markdown (เช่น ** หรือ *) เด็ดขาด เขียนเป็นความเรียงที่อ่านแล้วลื่นไหล

ธีมที่อยากให้เน้นวันนี้: "$focus"

ข้อมูลสรุปการเงิน ($periodLabel):
รายรับ: ฿${summary.totalIncome.toStringAsFixed(2)} | รายจ่าย: ฿${summary.totalExpense.toStringAsFixed(2)} | เงินคงเหลือ: ฿${summary.balance.toStringAsFixed(2)}
เทียบครั้งก่อน: $changeSign${summary.comparison.percentChange.toStringAsFixed(1)}%
หมวดที่จ่ายสูงสุด:
$categoryLines

รูปแบบการตอบ (ขอเป็น 1-2 ย่อหน้าสั้นๆ ความยาวรวมไม่เกิน 4 ประโยค):
- เริ่มด้วยการสรุปสถานการณ์สั้นๆ แบบเข้าใจง่ายและเป็นมิตร เช่น "ยอดเยี่ยมมากครับ เดือนนี้คุณบริหารเงินได้ดีเลย..." หรือ "ช่วงนี้อาจจะใช้จ่ายตึงมือไปนิด..."
- ดึงจุดที่น่าสนใจที่สุดจากข้อมูล (เช่น หมวดหมู่ที่จ่ายเยอะสุด) มาวิเคราะห์สั้นๆ พร้อมให้คำแนะนำ 1 ข้อที่ทำได้จริงและทำได้ทันทีเพื่อปรับปรุงสถานการณ์ให้ดีขึ้น
- ห้ามใช้คำว่า "สรุป" "ข้อแนะนำ" ให้รวมเป็นเนื้อเดียวกันอย่างกลมกลืน''';

    DioException? lastModelException;
    Map<String, dynamic>? root;

    for (final model in modelCandidates) {
      try {
        final response = await dio.post<Map<String, dynamic>>(
          'models/$model:generateContent',
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
          'ไม่พบ model ที่ใช้งานได้สำหรับคำแนะนำหน้าแรก (${modelCandidates.join(', ')})',
        );
      }
      throw const FormatException('เรียก AI ไม่สำเร็จ');
    }

    final candidates = (root['candidates'] as List?) ?? const [];
    if (candidates.isEmpty) {
      throw const FormatException('ไม่ได้รับการตอบกลับจาก AI');
    }
    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = (content?['parts'] as List?) ?? const [];
    if (parts.isEmpty) throw const FormatException('AI ไม่ส่งข้อมูลกลับมา');

    final raw = (parts.first['text'] as String?)?.trim() ?? '';
    return _sanitizeInsight(raw, summary);
  }

  List<String> _buildModelCandidates() {
    final ordered = <String>[
      if ((dotenv.env['GEMINI_INSIGHT_MODEL'] ?? '').trim().isNotEmpty)
        dotenv.env['GEMINI_INSIGHT_MODEL']!.trim(),
      if ((dotenv.env['GEMINI_CATEGORY_MODEL'] ?? '').trim().isNotEmpty)
        dotenv.env['GEMINI_CATEGORY_MODEL']!.trim(),
      if ((dotenv.env['GEMINI_MODEL'] ?? '').trim().isNotEmpty)
        dotenv.env['GEMINI_MODEL']!.trim(),
      'gemini-3.1-pro',
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

  String _sanitizeInsight(String raw, DashboardSummary summary) {
    // Remove Markdown boldness and extra newlines, keep it natural
    final cleaned = raw
        .replaceAll(RegExp(r'\*\*|\*'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    if (cleaned.isEmpty) {
      return _fallbackInsight(summary);
    }

    return cleaned;
  }

  String _fallbackInsight(DashboardSummary summary) {
    final top = summary.topCategories.isNotEmpty
        ? summary.topCategories.first
        : null;
    final topLine = top == null
        ? 'ตอนนี้ข้อมูลยังน้อยอยู่ ลองจดเพิ่มอีก 3-5 รายการจะเห็นแพทเทิร์นชัดขึ้น'
        : 'หมวด ${top.categoryName} นำโด่งอยู่ที่ ฿${top.totalAmount.toStringAsFixed(2)} เลย';
    final direction = summary.comparison.percentChange >= 0
        ? 'เพิ่มขึ้น'
        : 'ลดลง';

    final weeklyTarget = top == null
        ? (summary.totalExpense * 0.10)
        : (top.totalAmount * 0.12);

    return [
      'ภาพรวมตอนนี้รายจ่าย$direction ${summary.comparison.percentChange.abs().toStringAsFixed(1)}% เทียบรอบก่อนนะ',
      topLine,
      'ลองคุม 7 วันนี้ให้ลดลงอีกประมาณ ฿${weeklyTarget.toStringAsFixed(0)} แล้วค่อยเช็กกันใหม่ปลายสัปดาห์',
    ].join('\n');
  }
}
