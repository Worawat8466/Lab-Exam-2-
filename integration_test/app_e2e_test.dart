import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:labexam2/app/di/service_locator.dart';
import 'package:labexam2/app/router/app_router.dart';
import 'package:labexam2/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('เปิดแอป -> กรอกฟอร์ม -> บันทึก -> แสดงในหน้าประวัติ', (
    tester,
  ) async {
    await app.main();
    await _pumpFor(tester, const Duration(seconds: 3));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsAtLeastNWidgets(1));

    await sl<AppRouter>().push(ExpenseFormRoute());
    await _pumpFor(tester, const Duration(seconds: 1));

    expect(find.text('เพิ่มรายจ่าย'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);

    final categoryChips = find.byType(ChoiceChip);
    expect(
      categoryChips,
      findsWidgets,
      reason: 'ต้องมีหมวดหมู่อย่างน้อย 1 ตัวเพื่อทดสอบการบันทึก',
    );

    final selectedCategoryText =
        ((tester.widget(categoryChips.first) as ChoiceChip).label as Text)
            .data ??
        '';
    await tester.tap(categoryChips.first);
    await _pumpFor(tester, const Duration(milliseconds: 300));

    final amountField = find.byType(TextFormField).at(0);
    await tester.enterText(amountField, '89.50');
    await _pumpFor(tester, const Duration(milliseconds: 200));

    await tester.tap(find.text('บันทึกรายจ่าย'));
    await _pumpFor(tester, const Duration(seconds: 2));

    final historyTabIcon = find.byIcon(Icons.receipt_long_outlined);
    if (historyTabIcon.evaluate().isNotEmpty) {
      await tester.tap(historyTabIcon);
    } else {
      await tester.tap(find.byIcon(Icons.receipt_long));
    }
    await _pumpFor(tester, const Duration(seconds: 2));

    expect(find.text(selectedCategoryText), findsWidgets);
    expect(find.textContaining('89.50'), findsWidgets);
  });
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final steps = duration.inMilliseconds ~/ 100;
  for (var index = 0; index < steps; index++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
