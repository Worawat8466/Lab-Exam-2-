import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class UpdateExpenseUseCase implements UseCase<Expense, UpdateExpenseParams> {
  const UpdateExpenseUseCase(this._repository);

  final ExpenseRepository _repository;

  @override
  Future<Either<Failure, Expense>> call(UpdateExpenseParams params) {
    return _repository.updateExpense(params.expense);
  }
}

class UpdateExpenseParams {
  const UpdateExpenseParams({required this.expense});

  final Expense expense;
}
