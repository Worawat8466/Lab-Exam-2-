import 'package:isar/isar.dart';

import '../../domain/entities/expense_tag.dart';

part 'expense_tag_isar_model.g.dart';

@collection
class ExpenseTagIsarModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, caseSensitive: false)
  late String name;

  String? colorHex;
  late DateTime createdAt;
  late DateTime updatedAt;

  ExpenseTag toEntity() {
    return ExpenseTag(
      id: id,
      name: name,
      colorHex: colorHex,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static ExpenseTagIsarModel fromEntity(ExpenseTag entity) {
    final model = ExpenseTagIsarModel()
      ..id = entity.id
      ..name = entity.name
      ..colorHex = entity.colorHex
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt;

    return model;
  }
}
