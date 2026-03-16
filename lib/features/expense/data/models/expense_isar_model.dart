import 'package:isar/isar.dart';

import '../../domain/entities/expense.dart';

part 'expense_isar_model.g.dart';

@collection
class ExpenseIsarModel {
  Id id = Isar.autoIncrement;

  @enumerated
  late TransactionType type;

  @Index(caseSensitive: false)
  late String merchant;

  @Index(caseSensitive: false)
  late String category;

  late double amount;
  late String currency;
  late String note;
  List<String> tags = <String>[];
  late bool isRecurring;
  String? recurringFrequencyKey;
  DateTime? nextOccurrence;
  String? receiptImagePath;
  late String receiptRawText;
  late DateTime purchasedAt;
  late DateTime createdAt;
  late DateTime updatedAt;

  Expense toEntity() {
    return Expense(
      id: id,
      type: type,
      merchant: merchant,
      category: category,
      amount: amount,
      currency: currency,
      note: note,
      tags: tags,
      isRecurring: isRecurring,
      recurringFrequency: _parseRecurringFrequency(recurringFrequencyKey),
      nextOccurrence: nextOccurrence,
      receiptImagePath: receiptImagePath,
      receiptRawText: receiptRawText,
      purchasedAt: purchasedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static ExpenseIsarModel fromEntity(Expense entity) {
    final model = ExpenseIsarModel()
      ..id = entity.id
      ..type = entity.type
      ..merchant = entity.merchant
      ..category = entity.category
      ..amount = entity.amount
      ..currency = entity.currency
      ..note = entity.note
      ..tags = List<String>.from(entity.tags)
      ..isRecurring = entity.isRecurring
      ..recurringFrequencyKey = entity.recurringFrequency?.name
      ..nextOccurrence = entity.nextOccurrence
      ..receiptImagePath = entity.receiptImagePath
      ..receiptRawText = entity.receiptRawText
      ..purchasedAt = entity.purchasedAt
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt;

    return model;
  }

  static RecurringFrequency? _parseRecurringFrequency(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    for (final frequency in RecurringFrequency.values) {
      if (frequency.name == value) {
        return frequency;
      }
    }

    return null;
  }
}
