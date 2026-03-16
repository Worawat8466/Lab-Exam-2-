import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/expense_tag.dart';
import '../repositories/expense_metadata_repository.dart';

class SaveExpenseTagUseCase
    implements UseCase<ExpenseTag, SaveExpenseTagParams> {
  const SaveExpenseTagUseCase(this._repository);

  final ExpenseMetadataRepository _repository;

  @override
  Future<Either<Failure, ExpenseTag>> call(SaveExpenseTagParams params) {
    return _repository.saveTag(params.tag);
  }
}

class SaveExpenseTagParams {
  const SaveExpenseTagParams({required this.tag});

  final ExpenseTag tag;
}
