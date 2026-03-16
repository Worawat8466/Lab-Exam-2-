import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/expense_repository.dart';

class DeleteExpenseUseCase implements UseCase<Unit, DeleteExpenseParams> {
  const DeleteExpenseUseCase(this._repository);

  final ExpenseRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(DeleteExpenseParams params) {
    return _repository.deleteExpense(params.id);
  }
}

class DeleteExpenseParams {
  const DeleteExpenseParams(this.id);

  final int id;
}
