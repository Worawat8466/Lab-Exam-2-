import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/expense.dart';

abstract class ExpenseRepository {
  Future<Either<Failure, Expense>> createExpense(Expense expense);
  Future<Either<Failure, Expense>> updateExpense(Expense expense);
  Future<Either<Failure, Unit>> deleteExpense(int id);
  Future<Either<Failure, Expense>> getExpenseById(int id);
  Future<Either<Failure, List<Expense>>> getAllExpenses();
}
