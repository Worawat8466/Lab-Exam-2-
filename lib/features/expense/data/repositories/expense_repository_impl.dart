import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_data_source.dart';
import '../models/expense_isar_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  const ExpenseRepositoryImpl(this._localDataSource);

  final ExpenseLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, Expense>> createExpense(Expense expense) async {
    try {
      final created = await _localDataSource.create(
        ExpenseIsarModel.fromEntity(expense),
      );

      return right(created.toEntity());
    } catch (error) {
      return left(DatabaseFailure('Create expense failed: $error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteExpense(int id) async {
    try {
      await _localDataSource.delete(id);
      return right(unit);
    } catch (error) {
      return left(DatabaseFailure('Delete expense failed: $error'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getAllExpenses() async {
    try {
      final all = await _localDataSource.getAll();
      return right(all.map((entry) => entry.toEntity()).toList());
    } catch (error) {
      return left(DatabaseFailure('Load expenses failed: $error'));
    }
  }

  @override
  Future<Either<Failure, Expense>> getExpenseById(int id) async {
    try {
      final found = await _localDataSource.getById(id);
      if (found == null) {
        return left(DatabaseFailure('Expense not found'));
      }

      return right(found.toEntity());
    } catch (error) {
      return left(DatabaseFailure('Get expense failed: $error'));
    }
  }

  @override
  Future<Either<Failure, Expense>> updateExpense(Expense expense) async {
    try {
      final updated = await _localDataSource.update(
        ExpenseIsarModel.fromEntity(expense),
      );

      return right(updated.toEntity());
    } catch (error) {
      return left(DatabaseFailure('Update expense failed: $error'));
    }
  }
}
