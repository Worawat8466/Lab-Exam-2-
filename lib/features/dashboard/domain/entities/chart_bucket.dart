class ChartBucket {
  const ChartBucket({
    required this.label,
    required this.incomeAmount,
    required this.expenseAmount,
  });

  final String label;
  final double incomeAmount;
  final double expenseAmount;

  double get balance => incomeAmount - expenseAmount;
}
