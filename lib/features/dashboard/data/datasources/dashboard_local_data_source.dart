import '../../../expense/data/datasources/expense_local_data_source.dart';
import '../../../expense/domain/entities/expense.dart';

abstract class DashboardLocalDataSource {
  Future<List<Expense>> getAllTransactions();
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  const DashboardLocalDataSourceImpl(this._expenseLocalDataSource);

  final ExpenseLocalDataSource _expenseLocalDataSource;

  @override
  Future<List<Expense>> getAllTransactions() async {
    final models = await _expenseLocalDataSource.getAll();
    return models.map((entry) => entry.toEntity()).toList();
  }
}
