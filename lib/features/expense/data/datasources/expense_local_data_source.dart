import 'package:isar/isar.dart';

import '../models/expense_isar_model.dart';

abstract class ExpenseLocalDataSource {
  Future<ExpenseIsarModel> create(ExpenseIsarModel expense);
  Future<ExpenseIsarModel> update(ExpenseIsarModel expense);
  Future<void> delete(int id);
  Future<ExpenseIsarModel?> getById(int id);
  Future<List<ExpenseIsarModel>> getAll();
}

class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  const ExpenseLocalDataSourceImpl(this._isar);

  final Isar _isar;

  @override
  Future<ExpenseIsarModel> create(ExpenseIsarModel expense) async {
    final model = expense;
    if (model.id <= 0) {
      model.id = Isar.autoIncrement;
    }

    await _isar.writeTxn(() async {
      model.id = await _isar.expenseIsarModels.put(model);
    });

    return model;
  }

  @override
  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.expenseIsarModels.delete(id);
    });
  }

  @override
  Future<List<ExpenseIsarModel>> getAll() async {
    return _isar.expenseIsarModels.where().sortByCreatedAtDesc().findAll();
  }

  @override
  Future<ExpenseIsarModel?> getById(int id) {
    return _isar.expenseIsarModels.get(id);
  }

  @override
  Future<ExpenseIsarModel> update(ExpenseIsarModel expense) async {
    final model = expense;
    await _isar.writeTxn(() async {
      model.id = await _isar.expenseIsarModels.put(model);
    });

    return model;
  }
}
