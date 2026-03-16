import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/expense_category.dart';
import '../entities/expense_tag.dart';
import '../repositories/expense_metadata_repository.dart';

class GetExpenseMetadataUseCase
    implements UseCase<ExpenseMetadataBundle, NoParams> {
  const GetExpenseMetadataUseCase(this._repository);

  final ExpenseMetadataRepository _repository;

  @override
  Future<Either<Failure, ExpenseMetadataBundle>> call(NoParams params) async {
    final categoriesResult = await _repository.getAllCategories();
    final tagsResult = await _repository.getAllTags();

    return categoriesResult.fold(
      left,
      (categories) => tagsResult.fold(
        left,
        (tags) =>
            right(ExpenseMetadataBundle(categories: categories, tags: tags)),
      ),
    );
  }
}

class ExpenseMetadataBundle {
  const ExpenseMetadataBundle({required this.categories, required this.tags});

  final List<ExpenseCategory> categories;
  final List<ExpenseTag> tags;
}
