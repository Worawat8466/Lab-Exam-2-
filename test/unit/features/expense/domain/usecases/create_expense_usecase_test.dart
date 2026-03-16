import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labexam2/features/expense/domain/entities/expense.dart';
import 'package:labexam2/features/expense/domain/repositories/expense_repository.dart';
import 'package:labexam2/features/expense/domain/usecases/create_expense_usecase.dart';
import 'package:mocktail/mocktail.dart';

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

class _FakeExpense extends Fake implements Expense {}

void main() {
  late _MockExpenseRepository repository;
  late CreateExpenseUseCase useCase;

  setUpAll(() {
    registerFallbackValue(_FakeExpense());
  });

  setUp(() {
    repository = _MockExpenseRepository();
    useCase = CreateExpenseUseCase(repository);
  });

  test('returns created expense when repository succeeds', () async {
    final expense = Expense(
      id: 0,
      type: TransactionType.expense,
      merchant: 'Cafe',
      category: 'Food',
      amount: 120,
      currency: 'THB',
      note: 'Lunch',
      tags: const ['อาหาร', 'กลางวัน'],
      isRecurring: false,
      receiptImagePath: '/tmp/receipt.jpg',
      receiptRawText: 'Cafe 120 THB',
      purchasedAt: DateTime(2026, 3, 2),
      createdAt: DateTime(2026, 3, 2),
      updatedAt: DateTime(2026, 3, 2),
    );

    when(
      () => repository.createExpense(any()),
    ).thenAnswer((_) async => right(expense));

    final result = await useCase(CreateExpenseParams(expense: expense));

    expect(result, right(expense));
    verify(() => repository.createExpense(expense)).called(1);
  });
}
