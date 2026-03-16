import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:labexam2/features/expense/presentation/pages/expense_form_page.dart';

void main() {
  testWidgets('Expense form renders key fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ExpenseFormPage())),
    );

    expect(find.text('หมวดหมู่'), findsOneWidget);
    expect(find.text('จำนวนเงิน'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
  });
}
