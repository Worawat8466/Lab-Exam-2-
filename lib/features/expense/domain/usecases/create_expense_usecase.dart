import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class CreateExpenseUseCase implements UseCase<Expense, CreateExpenseParams> {
  const CreateExpenseUseCase(this._repository);

  final ExpenseRepository _repository;

  @override
  Future<Either<Failure, Expense>> call(CreateExpenseParams params) {
    return _repository.createExpense(params.expense);
  }
}

class CreateExpenseParams {
  const CreateExpenseParams({required this.expense});

  final Expense expense;
}
