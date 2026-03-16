import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/category_breakdown.dart';
import '../../domain/entities/chart_bucket.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/period_comparison.dart';
import '../../domain/entities/summary_period.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../expense/domain/entities/expense.dart';
import '../datasources/dashboard_local_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._localDataSource);

  final DashboardLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, DashboardSummary>> getDashboardSummary({
    required SummaryPeriod period,
    required DateTime anchorDate,
  }) async {
    try {
      final all = await _localDataSource.getAllTransactions();
      final current = _filterByPeriod(all, period, anchorDate);
      final previous = _filterByPreviousPeriod(all, period, anchorDate);

      final totalIncome = _sumByType(current, TransactionType.income);
      final totalExpense = _sumByType(current, TransactionType.expense);
      final previousExpense = _sumByType(previous, TransactionType.expense);
      final difference = totalExpense - previousExpense;
      final percentChange =
          (previousExpense <= 0
                  ? (totalExpense <= 0 ? 0 : 100)
                  : (difference / previousExpense) * 100)
              .toDouble();

      final summary = DashboardSummary(
        period: period,
        anchorDate: anchorDate,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        recurringTransactionCount: current
            .where((entry) => entry.isRecurring)
            .length,
        topCategories: _buildCategoryBreakdown(current),
        chartBuckets: _buildChartBuckets(current, period, anchorDate),
        comparison: PeriodComparison(
          currentExpense: totalExpense,
          previousExpense: previousExpense,
          difference: difference,
          percentChange: percentChange,
        ),
      );

      return right(summary);
    } catch (error) {
      return left(DatabaseFailure('Load dashboard summary failed: $error'));
    }
  }

  List<Expense> _filterByPeriod(
    List<Expense> expenses,
    SummaryPeriod period,
    DateTime anchorDate,
  ) {
    return expenses.where((entry) {
      final date = entry.purchasedAt;
      switch (period) {
        case SummaryPeriod.weekly:
          final start = _startOfWeek(anchorDate);
          final end = start.add(const Duration(days: 7));
          return !date.isBefore(start) && date.isBefore(end);
        case SummaryPeriod.monthly:
          return date.year == anchorDate.year && date.month == anchorDate.month;
        case SummaryPeriod.quarterly:
          final quarter = ((anchorDate.month - 1) ~/ 3) + 1;
          final dateQuarter = ((date.month - 1) ~/ 3) + 1;
          return date.year == anchorDate.year && dateQuarter == quarter;
        case SummaryPeriod.yearly:
          return date.year == anchorDate.year;
      }
    }).toList();
  }

  List<Expense> _filterByPreviousPeriod(
    List<Expense> expenses,
    SummaryPeriod period,
    DateTime anchorDate,
  ) {
    switch (period) {
      case SummaryPeriod.weekly:
        final currentStart = _startOfWeek(anchorDate);
        final previousStart = currentStart.subtract(const Duration(days: 7));
        final previousEnd = currentStart;
        return expenses
            .where(
              (entry) =>
                  !entry.purchasedAt.isBefore(previousStart) &&
                  entry.purchasedAt.isBefore(previousEnd),
            )
            .toList();
      case SummaryPeriod.monthly:
        final previousMonthDate = DateTime(
          anchorDate.year,
          anchorDate.month - 1,
          1,
        );
        return expenses
            .where(
              (entry) =>
                  entry.purchasedAt.year == previousMonthDate.year &&
                  entry.purchasedAt.month == previousMonthDate.month,
            )
            .toList();
      case SummaryPeriod.quarterly:
        final currentQuarter = ((anchorDate.month - 1) ~/ 3) + 1;
        final previousQuarter = currentQuarter == 1 ? 4 : currentQuarter - 1;
        final year = currentQuarter == 1
            ? anchorDate.year - 1
            : anchorDate.year;
        return expenses.where((entry) {
          final dateQuarter = ((entry.purchasedAt.month - 1) ~/ 3) + 1;
          return entry.purchasedAt.year == year &&
              dateQuarter == previousQuarter;
        }).toList();
      case SummaryPeriod.yearly:
        return expenses
            .where((entry) => entry.purchasedAt.year == anchorDate.year - 1)
            .toList();
    }
  }

  DateTime _startOfWeek(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.subtract(Duration(days: local.weekday - 1));
  }

  double _sumByType(List<Expense> expenses, TransactionType type) {
    return expenses
        .where((entry) => entry.type == type)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
  }

  List<CategoryBreakdown> _buildCategoryBreakdown(List<Expense> expenses) {
    final totals = <String, double>{};
    final expenseItems = expenses
        .where((entry) => entry.type == TransactionType.expense)
        .toList();
    final totalExpense = expenseItems.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );

    for (final entry in expenseItems) {
      totals.update(
        entry.category,
        (value) => value + entry.amount,
        ifAbsent: () => entry.amount,
      );
    }

    final result = totals.entries.map((entry) {
      final percentage =
          (totalExpense <= 0 ? 0 : (entry.value / totalExpense) * 100)
              .toDouble();
      return CategoryBreakdown(
        categoryName: entry.key,
        totalAmount: entry.value,
        percentage: percentage,
      );
    }).toList()..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return result;
  }

  List<ChartBucket> _buildChartBuckets(
    List<Expense> expenses,
    SummaryPeriod period,
    DateTime anchorDate,
  ) {
    switch (period) {
      case SummaryPeriod.weekly:
        final start = _startOfWeek(anchorDate);
        return List.generate(7, (index) {
          final day = start.add(Duration(days: index));
          final dayItems = expenses.where(
            (entry) =>
                entry.purchasedAt.year == day.year &&
                entry.purchasedAt.month == day.month &&
                entry.purchasedAt.day == day.day,
          );
          return ChartBucket(
            label: '${day.day}/${day.month}',
            incomeAmount: dayItems
                .where((entry) => entry.type == TransactionType.income)
                .fold<double>(0, (sum, entry) => sum + entry.amount),
            expenseAmount: dayItems
                .where((entry) => entry.type == TransactionType.expense)
                .fold<double>(0, (sum, entry) => sum + entry.amount),
          );
        });
      case SummaryPeriod.monthly:
        return List.generate(4, (index) {
          final startDay = index * 7 + 1;
          final endDay = index == 3 ? 31 : startDay + 6;
          final bucketItems = expenses.where(
            (entry) =>
                entry.purchasedAt.day >= startDay &&
                entry.purchasedAt.day <= endDay,
          );
          return ChartBucket(
            label: 'W${index + 1}',
            incomeAmount: bucketItems
                .where((entry) => entry.type == TransactionType.income)
                .fold<double>(0, (sum, entry) => sum + entry.amount),
            expenseAmount: bucketItems
                .where((entry) => entry.type == TransactionType.expense)
                .fold<double>(0, (sum, entry) => sum + entry.amount),
          );
        });
      case SummaryPeriod.quarterly:
        final quarterStartMonth = ((anchorDate.month - 1) ~/ 3) * 3 + 1;
        return List.generate(3, (index) {
          final month = quarterStartMonth + index;
          final monthItems = expenses.where(
            (entry) => entry.purchasedAt.month == month,
          );
          return ChartBucket(
            label: 'M$month',
            incomeAmount: monthItems
                .where((entry) => entry.type == TransactionType.income)
                .fold<double>(0, (sum, entry) => sum + entry.amount),
            expenseAmount: monthItems
                .where((entry) => entry.type == TransactionType.expense)
                .fold<double>(0, (sum, entry) => sum + entry.amount),
          );
        });
      case SummaryPeriod.yearly:
        return List.generate(12, (index) {
          final month = index + 1;
          final monthItems = expenses.where(
            (entry) => entry.purchasedAt.month == month,
          );
          return ChartBucket(
            label: '$month',
            incomeAmount: monthItems
                .where((entry) => entry.type == TransactionType.income)
                .fold<double>(0, (sum, entry) => sum + entry.amount),
            expenseAmount: monthItems
                .where((entry) => entry.type == TransactionType.expense)
                .fold<double>(0, (sum, entry) => sum + entry.amount),
          );
        });
    }
  }
}
