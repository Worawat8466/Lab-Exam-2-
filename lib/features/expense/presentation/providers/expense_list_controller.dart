import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/get_all_expenses_usecase.dart';

final expenseListControllerProvider =
    AutoDisposeAsyncNotifierProvider<ExpenseListController, List<Expense>>(
      ExpenseListController.new,
    );

class ExpenseListController extends AutoDisposeAsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    return _load();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> deleteExpense(int id) async {
    final useCase = sl<DeleteExpenseUseCase>();
    final result = await useCase(DeleteExpenseParams(id));

    result.fold((failure) {
      state = AsyncError(Exception(failure.message), StackTrace.current);
    }, (_) => refresh());
  }

  Future<List<Expense>> _load() async {
    final useCase = sl<GetAllExpensesUseCase>();
    final result = await useCase(const NoParams());

    return result.fold(
      (failure) => throw Exception(failure.message),
      (expenses) => expenses,
    );
  }
}
