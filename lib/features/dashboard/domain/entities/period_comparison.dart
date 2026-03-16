class PeriodComparison {
  const PeriodComparison({
    required this.currentExpense,
    required this.previousExpense,
    required this.difference,
    required this.percentChange,
  });

  final double currentExpense;
  final double previousExpense;
  final double difference;
  final double percentChange;
}
