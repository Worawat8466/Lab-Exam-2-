import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/expense_category.dart';
import '../entities/expense_tag.dart';

abstract class ExpenseMetadataRepository {
  Future<Either<Failure, List<ExpenseCategory>>> getAllCategories();
  Future<Either<Failure, ExpenseCategory>> saveCategory(
    ExpenseCategory category,
  );
  Future<Either<Failure, Unit>> deleteCategory(int id);

  Future<Either<Failure, List<ExpenseTag>>> getAllTags();
  Future<Either<Failure, ExpenseTag>> saveTag(ExpenseTag tag);
  Future<Either<Failure, Unit>> deleteTag(int id);
}
