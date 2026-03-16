import 'dart:convert';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/router/app_router.dart';
import '../../../dashboard/domain/entities/summary_period.dart';
import '../../../dashboard/presentation/providers/dashboard_summary_controller.dart';
import '../../domain/entities/expense.dart';
import '../providers/expense_list_controller.dart';

@RoutePage()
class ExpenseListPage extends ConsumerStatefulWidget {
  const ExpenseListPage({super.key});

  @override
  ConsumerState<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends ConsumerState<ExpenseListPage> {
  String? _selectedTag;
  SummaryPeriod _selectedPeriod = SummaryPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('แม๊วจดรายรับรายจ่าย'),
        actions: [
          IconButton(
            tooltip: 'ส่งออก CSV',
            onPressed: () async {
              final expenses = ref.read(expenseListControllerProvider).value;
              if (expenses == null || expenses.isEmpty) {
                _showSnackBar('ยังไม่มีข้อมูลให้ส่งออก');
                return;
              }
              final path = await _exportCsv(expenses);
              _showSnackBar('ส่งออก CSV แล้ว: $path');
            },
            icon: const Icon(Icons.download),
          ),
          IconButton(
            tooltip: 'ตั้งค่า',
            onPressed: () async {
              await context.router.push(const SettingsRoute());
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.router.push(ExpenseFormRoute());
          if (context.mounted) {
            await ref.read(expenseListControllerProvider.notifier).refresh();
            for (final p in SummaryPeriod.values) {
              ref.invalidate(dashboardSummaryControllerProvider(p));
            }
          }
        },
        label: const Text('เพิ่มรายการ'),
        icon: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(expenseListControllerProvider.notifier).refresh(),
        child: expensesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('เกิดข้อผิดพลาด: $error')),
          data: (expenses) {
            final periodFiltered = _filterByPeriod(expenses, _selectedPeriod);
            final filtered = _selectedTag == null
                ? periodFiltered
                : periodFiltered
                      .where((entry) => entry.tags.contains(_selectedTag))
                      .toList();

            return ListView(
              children: [
                _PeriodFilterBar(
                  selectedPeriod: _selectedPeriod,
                  onChanged: (period) {
                    setState(() {
                      _selectedPeriod = period;
                    });
                  },
                ),
                _DashboardHeader(selectedPeriod: _selectedPeriod),
                _TagFilterBar(
                  expenses: periodFiltered,
                  selectedTag: _selectedTag,
                  onChanged: (tag) => setState(() => _selectedTag = tag),
                ),
                const SizedBox(height: 8),
                if (filtered.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'ยังไม่มีรายการในช่วงเวลานี้ ลองเพิ่มรายการเองหรือสแกนสลิปได้เลย',
                      ),
                    ),
                  )
                else
                  ...filtered.map(
                    (expense) => Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: ListTile(
                        onTap: () => context.router.push(
                          ExpenseDetailRoute(expenseId: expense.id),
                        ),
                        isThreeLine: true,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _ReceiptThumb(path: expense.receiptImagePath),
                        ),
                        title: Text(expense.category),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat.yMMMd(
                                'th',
                              ).format(expense.purchasedAt),
                            ),
                            Text(
                              expense.type == TransactionType.income
                                  ? 'รายการรายรับ'
                                  : 'รายการรายจ่าย',
                              style: TextStyle(
                                color: expense.type == TransactionType.income
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (expense.isRecurring)
                              Text(
                                'จดซ้ำ: ${_recurringLabel(expense.recurringFrequency)}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  fontSize: 12,
                                ),
                              ),
                            if (expense.tags.isNotEmpty)
                              Text(
                                expense.tags.map((tag) => '#$tag').join('  '),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                        trailing: SizedBox(
                          width: 118,
                          child: Text(
                            '${expense.type == TransactionType.income ? '+' : '-'} ${expense.currency} ${expense.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: expense.type == TransactionType.income
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Expense> _filterByPeriod(List<Expense> expenses, SummaryPeriod period) {
    final now = DateTime.now();

    return expenses.where((entry) {
      final date = entry.purchasedAt;
      switch (period) {
        case SummaryPeriod.weekly:
          final startOfWeek = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: now.weekday - 1));
          return !date.isBefore(startOfWeek);
        case SummaryPeriod.monthly:
          return date.year == now.year && date.month == now.month;
        case SummaryPeriod.quarterly:
          final quarter = ((now.month - 1) ~/ 3) + 1;
          final dateQuarter = ((date.month - 1) ~/ 3) + 1;
          return date.year == now.year && dateQuarter == quarter;
        case SummaryPeriod.yearly:
          return date.year == now.year;
      }
    }).toList();
  }

  Future<String> _exportCsv(List<Expense> expenses) async {
    final rows = <List<String>>[
      [
        'id',
        'ประเภทรายการ',
        'ร้านค้า',
        'หมวดหมู่',
        'จำนวนเงิน',
        'สกุลเงิน',
        'วันที่รายการ',
        'จดซ้ำ',
        'ความถี่',
        'แท็ก',
        'บันทึก',
      ],
      ...expenses.map(
        (entry) => [
          '${entry.id}',
          entry.type == TransactionType.income ? 'รายรับ' : 'รายจ่าย',
          entry.merchant,
          entry.category,
          entry.amount.toStringAsFixed(2),
          entry.currency,
          entry.purchasedAt.toIso8601String(),
          entry.isRecurring ? 'ใช่' : 'ไม่ใช่',
          _recurringLabel(entry.recurringFrequency),
          entry.tags.join('|'),
          entry.note,
        ],
      ),
    ];

    final csvText = rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');

    final directory = await getApplicationDocumentsDirectory();
    final filename = 'expenses_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}${Platform.pathSeparator}$filename');
    await file.writeAsString(csvText, encoding: utf8);
    return file.path;
  }

  String _escapeCsv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _recurringLabel(RecurringFrequency? frequency) {
    switch (frequency) {
      case RecurringFrequency.weekly:
        return 'ทุกสัปดาห์';
      case RecurringFrequency.monthly:
        return 'ทุกเดือน';
      case RecurringFrequency.quarterly:
        return 'ทุกไตรมาส';
      case RecurringFrequency.yearly:
        return 'ทุกปี';
      case null:
        return '-';
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader({required this.selectedPeriod});

  final SummaryPeriod selectedPeriod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(
      dashboardSummaryControllerProvider(selectedPeriod),
    );

    if (summaryAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      );
    }

    if (summaryAsync.hasError) {
      return const SizedBox.shrink();
    }

    final summary = summaryAsync.value;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    final topCategory = summary.topCategories.isEmpty
        ? '-'
        : summary.topCategories.first.categoryName;
    final topCategoryAmount = summary.topCategories.isEmpty
        ? 0.0
        : summary.topCategories.first.totalAmount;
    final buckets = summary.chartBuckets
        .map((entry) => entry.expenseAmount)
        .toList();
    final maxBucket = buckets.isEmpty
        ? 0.0
        : buckets.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'ดูสรุปรายรับรายจ่าย',
                  value: summary.balance.toStringAsFixed(2),
                  subtitle:
                      'รายรับ ${summary.totalIncome.toStringAsFixed(2)} • รายจ่าย ${summary.totalExpense.toStringAsFixed(2)}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'เงินหายไปไหน',
                  value: topCategory,
                  subtitle: summary.topCategories.isEmpty
                      ? 'ยังไม่มีข้อมูล'
                      : 'หมวดสูงสุด ${topCategoryAmount.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'รายการจดซ้ำล่วงหน้า',
                  value: '${summary.recurringTransactionCount} รายการ',
                  subtitle: 'ใช้กับเงินเดือน ค่าบริการ และค่าเช่า',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'เทียบงวดก่อน',
                  value: summary.comparison.difference >= 0
                      ? '+${summary.comparison.difference.toStringAsFixed(2)}'
                      : summary.comparison.difference.toStringAsFixed(2),
                  subtitle: summary.comparison.difference >= 0
                      ? 'ใช้จ่ายมากขึ้นจากงวดก่อน'
                      : 'ใช้จ่ายน้อยลงจากงวดก่อน',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'กราฟสรุปรายรับรายจ่าย (${_periodLabel(selectedPeriod)})',
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 92,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: buckets.map((value) {
                        final ratio = maxBucket <= 0
                            ? 0.12
                            : (value / maxBucket).clamp(0.12, 1.0).toDouble();
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Container(
                              height: 72 * ratio,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'เห็นอินไซต์การเงินแบบรายสัปดาห์ รายเดือน รายไตรมาส และรายปี พร้อมเปรียบเทียบงวดก่อน',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _periodLabel(SummaryPeriod period) {
    switch (period) {
      case SummaryPeriod.weekly:
        return 'รายสัปดาห์';
      case SummaryPeriod.monthly:
        return 'รายเดือน';
      case SummaryPeriod.quarterly:
        return 'รายไตรมาส';
      case SummaryPeriod.yearly:
        return 'รายปี';
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _PeriodFilterBar extends StatelessWidget {
  const _PeriodFilterBar({
    required this.selectedPeriod,
    required this.onChanged,
  });

  final SummaryPeriod selectedPeriod;
  final ValueChanged<SummaryPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    const periods = <SummaryPeriod>[
      SummaryPeriod.weekly,
      SummaryPeriod.monthly,
      SummaryPeriod.quarterly,
      SummaryPeriod.yearly,
    ];

    String label(SummaryPeriod period) {
      switch (period) {
        case SummaryPeriod.weekly:
          return 'สัปดาห์';
        case SummaryPeriod.monthly:
          return 'เดือน';
        case SummaryPeriod.quarterly:
          return 'ไตรมาส';
        case SummaryPeriod.yearly:
          return 'ปี';
      }
    }

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: periods
            .map(
              (period) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(label(period)),
                  selected: selectedPeriod == period,
                  onSelected: (_) => onChanged(period),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TagFilterBar extends StatelessWidget {
  const _TagFilterBar({
    required this.expenses,
    required this.selectedTag,
    required this.onChanged,
  });

  final List<Expense> expenses;
  final String? selectedTag;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tags = expenses.expand((entry) => entry.tags).toSet().toList()
      ..sort();

    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: const Text('ทั้งหมด'),
              selected: selectedTag == null,
              onSelected: (_) => onChanged(null),
            ),
          ),
          ...tags.map(
            (tag) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text('#$tag'),
                selected: selectedTag == tag,
                onSelected: (_) => onChanged(tag),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptThumb extends StatelessWidget {
  const _ReceiptThumb({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        width: 48,
        height: 48,
        child: const Icon(Icons.receipt_long),
      );
    }

    final file = File(path!);
    if (!file.existsSync()) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        width: 48,
        height: 48,
        child: const Icon(Icons.image_not_supported),
      );
    }

    return Image.file(
      file,
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      semanticLabel: 'receipt image',
    );
  }
}
