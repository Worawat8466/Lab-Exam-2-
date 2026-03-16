import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labexam2/features/expense/domain/entities/expense.dart';
import 'package:labexam2/features/expense/domain/entities/expense_category.dart';
import 'package:labexam2/features/expense/domain/usecases/get_expense_metadata_usecase.dart';
import 'package:labexam2/features/expense/presentation/pages/expense_form_page.dart';
import 'package:labexam2/features/expense/presentation/providers/expense_form_controller.dart';
import 'package:labexam2/features/expense/presentation/providers/expense_metadata_controller.dart';

class _FakeExpenseFormController extends ExpenseFormController {
  @override
  Future<ExpenseFormState> build() async => const ExpenseFormState();

  @override
  Future<Expense> submit({
    required int? existingId,
    required TransactionType type,
    required String merchant,
    required String category,
    required double amount,
    required String currency,
    required String note,
    required List<String> tags,
    required bool isRecurring,
    required RecurringFrequency? recurringFrequency,
    required DateTime? nextOccurrence,
    required DateTime purchasedAt,
  }) async {
    throw UnimplementedError('Not used in validation test');
  }
}

class _FakeExpenseMetadataController extends ExpenseMetadataController {
  @override
  Future<ExpenseMetadataBundle> build() async {
    final now = DateTime.now();
    return ExpenseMetadataBundle(
      categories: [
        ExpenseCategory(
          id: 1,
          name: 'อาหาร',
          isDefault: true,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      tags: const [],
    );
  }
}

void main() {
  testWidgets('ExpenseFormPage validates required fields on real page', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseFormControllerProvider.overrideWith(
            _FakeExpenseFormController.new,
          ),
          expenseMetadataControllerProvider.overrideWith(
            _FakeExpenseMetadataController.new,
          ),
        ],
        child: const MaterialApp(home: ExpenseFormPage()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('บันทึกรายจ่าย'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    final submitLabel = find.text('บันทึกรายจ่าย');
    await tester.tap(submitLabel);
    await tester.pumpAndSettle();

    expect(find.text('กรุณากรอกจำนวนเงิน'), findsOneWidget);
  });
}
