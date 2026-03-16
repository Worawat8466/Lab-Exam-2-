import 'package:isar/isar.dart';

import '../models/expense_category_isar_model.dart';
import '../models/expense_tag_isar_model.dart';

abstract class ExpenseMetadataLocalDataSource {
  Future<List<ExpenseCategoryIsarModel>> getAllCategories();
  Future<ExpenseCategoryIsarModel> saveCategory(
    ExpenseCategoryIsarModel category,
  );
  Future<void> deleteCategory(int id);

  Future<List<ExpenseTagIsarModel>> getAllTags();
  Future<ExpenseTagIsarModel> saveTag(ExpenseTagIsarModel tag);
  Future<void> deleteTag(int id);
}

class ExpenseMetadataLocalDataSourceImpl
    implements ExpenseMetadataLocalDataSource {
  const ExpenseMetadataLocalDataSourceImpl(this._isar);

  final Isar _isar;

  @override
  Future<void> deleteCategory(int id) async {
    await _isar.writeTxn(() async {
      await _isar.expenseCategoryIsarModels.delete(id);
    });
  }

  @override
  Future<void> deleteTag(int id) async {
    await _isar.writeTxn(() async {
      await _isar.expenseTagIsarModels.delete(id);
    });
  }

  @override
  Future<List<ExpenseCategoryIsarModel>> getAllCategories() {
    return _isar.expenseCategoryIsarModels.where().sortByName().findAll();
  }

  @override
  Future<List<ExpenseTagIsarModel>> getAllTags() {
    return _isar.expenseTagIsarModels.where().sortByName().findAll();
  }

  @override
  Future<ExpenseCategoryIsarModel> saveCategory(
    ExpenseCategoryIsarModel category,
  ) async {
    final model = category;
    if (model.id <= 0) {
      model.id = Isar.autoIncrement;
    }

    await _isar.writeTxn(() async {
      model.id = await _isar.expenseCategoryIsarModels.put(model);
    });

    return model;
  }

  @override
  Future<ExpenseTagIsarModel> saveTag(ExpenseTagIsarModel tag) async {
    final model = tag;
    if (model.id <= 0) {
      model.id = Isar.autoIncrement;
    }

    await _isar.writeTxn(() async {
      model.id = await _isar.expenseTagIsarModels.put(model);
    });

    return model;
  }
}
