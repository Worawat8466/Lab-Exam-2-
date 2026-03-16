import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetExpenseByIdUseCase implements UseCase<Expense, GetExpenseByIdParams> {
  const GetExpenseByIdUseCase(this._repository);

  final ExpenseRepository _repository;

  @override
  Future<Either<Failure, Expense>> call(GetExpenseByIdParams params) {
    return _repository.getExpenseById(params.id);
  }
}

class GetExpenseByIdParams {
  const GetExpenseByIdParams(this.id);

  final int id;
}
