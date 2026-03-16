import 'package:isar/isar.dart';

import '../../domain/entities/expense_category.dart';

part 'expense_category_isar_model.g.dart';

@collection
class ExpenseCategoryIsarModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, caseSensitive: false)
  late String name;

  String? emoji;
  String? colorHex;
  late bool isDefault;
  late DateTime createdAt;
  late DateTime updatedAt;

  ExpenseCategory toEntity() {
    return ExpenseCategory(
      id: id,
      name: name,
      emoji: emoji,
      colorHex: colorHex,
      isDefault: isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static ExpenseCategoryIsarModel fromEntity(ExpenseCategory entity) {
    final model = ExpenseCategoryIsarModel()
      ..id = entity.id
      ..name = entity.name
      ..emoji = entity.emoji
      ..colorHex = entity.colorHex
      ..isDefault = entity.isDefault
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt;

    return model;
  }
}
