enum TransactionType { expense, income }

enum RecurringFrequency { weekly, monthly, quarterly, yearly }

class Expense {
  const Expense({
    required this.id,
    required this.type,
    required this.merchant,
    required this.category,
    required this.amount,
    required this.currency,
    required this.note,
    required this.tags,
    required this.isRecurring,
    this.recurringFrequency,
    this.nextOccurrence,
    this.receiptImagePath,
    required this.receiptRawText,
    required this.purchasedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final TransactionType type;
  final String merchant;
  final String category;
  final double amount;
  final String currency;
  final String note;
  final List<String> tags;
  final bool isRecurring;
  final RecurringFrequency? recurringFrequency;
  final DateTime? nextOccurrence;
  final String? receiptImagePath;
  final String receiptRawText;
  final DateTime purchasedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
