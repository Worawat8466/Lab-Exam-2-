import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetAllExpensesUseCase implements UseCase<List<Expense>, NoParams> {
  const GetAllExpensesUseCase(this._repository);

  final ExpenseRepository _repository;

  @override
  Future<Either<Failure, List<Expense>>> call(NoParams params) {
    return _repository.getAllExpenses();
  }
}
