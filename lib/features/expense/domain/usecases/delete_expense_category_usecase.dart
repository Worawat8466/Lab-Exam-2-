import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/expense_metadata_repository.dart';

class DeleteExpenseCategoryUseCase
    implements UseCase<Unit, DeleteExpenseCategoryParams> {
  const DeleteExpenseCategoryUseCase(this._repository);

  final ExpenseMetadataRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(DeleteExpenseCategoryParams params) {
    return _repository.deleteCategory(params.id);
  }
}

class DeleteExpenseCategoryParams {
  const DeleteExpenseCategoryParams({required this.id});

  final int id;
}
