import 'category_breakdown.dart';
import 'chart_bucket.dart';
import 'period_comparison.dart';
import 'summary_period.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.period,
    required this.anchorDate,
    required this.totalIncome,
    required this.totalExpense,
    required this.recurringTransactionCount,
    required this.topCategories,
    required this.chartBuckets,
    required this.comparison,
  });

  final SummaryPeriod period;
  final DateTime anchorDate;
  final double totalIncome;
  final double totalExpense;
  final int recurringTransactionCount;
  final List<CategoryBreakdown> topCategories;
  final List<ChartBucket> chartBuckets;
  final PeriodComparison comparison;

  double get balance => totalIncome - totalExpense;
}
