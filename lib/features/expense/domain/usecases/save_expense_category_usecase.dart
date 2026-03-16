import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/expense_category.dart';
import '../repositories/expense_metadata_repository.dart';

class SaveExpenseCategoryUseCase
    implements UseCase<ExpenseCategory, SaveExpenseCategoryParams> {
  const SaveExpenseCategoryUseCase(this._repository);

  final ExpenseMetadataRepository _repository;

  @override
  Future<Either<Failure, ExpenseCategory>> call(
    SaveExpenseCategoryParams params,
  ) {
    return _repository.saveCategory(params.category);
  }
}

class SaveExpenseCategoryParams {
  const SaveExpenseCategoryParams({required this.category});

  final ExpenseCategory category;
}
