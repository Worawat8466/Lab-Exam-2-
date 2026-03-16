import '../../../expense/domain/entities/expense.dart';

class ParsedReceiptData {
  const ParsedReceiptData({
    required this.transactionType,
    required this.merchant,
    required this.suggestedCategory,
    required this.amount,
    required this.currency,
    required this.suggestedTags,
    required this.occurredAt,
    required this.reasoning,
    required this.confidence,
  });

  final TransactionType transactionType;
  final String merchant;
  final String suggestedCategory;
  final double amount;
  final String currency;
  final List<String> suggestedTags;
  final DateTime? occurredAt;
  final String reasoning;
  final double confidence;
}
