import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_tag.dart';
import '../../domain/repositories/expense_metadata_repository.dart';
import '../datasources/expense_metadata_local_data_source.dart';
import '../models/expense_category_isar_model.dart';
import '../models/expense_tag_isar_model.dart';

class ExpenseMetadataRepositoryImpl implements ExpenseMetadataRepository {
  const ExpenseMetadataRepositoryImpl(this._localDataSource);

  final ExpenseMetadataLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, Unit>> deleteCategory(int id) async {
    try {
      await _localDataSource.deleteCategory(id);
      return right(unit);
    } catch (error) {
      return left(DatabaseFailure('Delete category failed: $error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTag(int id) async {
    try {
      await _localDataSource.deleteTag(id);
      return right(unit);
    } catch (error) {
      return left(DatabaseFailure('Delete tag failed: $error'));
    }
  }

  @override
  Future<Either<Failure, List<ExpenseCategory>>> getAllCategories() async {
    try {
      final all = await _localDataSource.getAllCategories();
      return right(all.map((entry) => entry.toEntity()).toList());
    } catch (error) {
      return left(DatabaseFailure('Load categories failed: $error'));
    }
  }

  @override
  Future<Either<Failure, List<ExpenseTag>>> getAllTags() async {
    try {
      final all = await _localDataSource.getAllTags();
      return right(all.map((entry) => entry.toEntity()).toList());
    } catch (error) {
      return left(DatabaseFailure('Load tags failed: $error'));
    }
  }

  @override
  Future<Either<Failure, ExpenseCategory>> saveCategory(
    ExpenseCategory category,
  ) async {
    try {
      final saved = await _localDataSource.saveCategory(
        ExpenseCategoryIsarModel.fromEntity(category),
      );
      return right(saved.toEntity());
    } catch (error) {
      return left(DatabaseFailure('Save category failed: $error'));
    }
  }

  @override
  Future<Either<Failure, ExpenseTag>> saveTag(ExpenseTag tag) async {
    try {
      final saved = await _localDataSource.saveTag(
        ExpenseTagIsarModel.fromEntity(tag),
      );
      return right(saved.toEntity());
    } catch (error) {
      return left(DatabaseFailure('Save tag failed: $error'));
    }
  }
}
