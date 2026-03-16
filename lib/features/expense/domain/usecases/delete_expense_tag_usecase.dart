import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/expense_metadata_repository.dart';

class DeleteExpenseTagUseCase implements UseCase<Unit, DeleteExpenseTagParams> {
  const DeleteExpenseTagUseCase(this._repository);

  final ExpenseMetadataRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(DeleteExpenseTagParams params) {
    return _repository.deleteTag(params.id);
  }
}

class DeleteExpenseTagParams {
  const DeleteExpenseTagParams({required this.id});

  final int id;
}
