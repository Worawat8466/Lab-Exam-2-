import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/utils/iterable_extensions.dart';
import '../../../dashboard/domain/entities/summary_period.dart';
import '../../../dashboard/presentation/providers/dashboard_summary_controller.dart';
import '../../domain/entities/expense.dart';
import '../providers/expense_list_controller.dart';

@RoutePage()
class ExpenseDetailPage extends ConsumerWidget {
  const ExpenseDetailPage({super.key, required this.expenseId});

  final int expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListControllerProvider);

    return expensesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text(error.toString()))),
      data: (expenses) {
        final expense = expenses
            .where((entry) => entry.id == expenseId)
            .firstOrNull;
        if (expense == null) {
          return const Scaffold(body: Center(child: Text('ไม่พบรายการ')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              expense.type == TransactionType.income
                  ? 'รายละเอียดรายรับ'
                  : 'รายละเอียดรายจ่าย',
            ),
            actions: [
              IconButton(
                tooltip: 'แก้ไขรายการ',
                onPressed: () async {
                  await context.router.push(
                    ExpenseFormRoute(expenseId: expense.id),
                  );
                  if (context.mounted) {
                    await ref
                        .read(expenseListControllerProvider.notifier)
                        .refresh();
                    for (final p in SummaryPeriod.values) {
                      ref.invalidate(dashboardSummaryControllerProvider(p));
                    }
                  }
                },
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                tooltip: 'ลบรายการ',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('ยืนยันการลบ'),
                      content: const Text('ต้องการลบรายการนี้ใช่หรือไม่?'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('ยกเลิก'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text('ลบ'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) {
                    return;
                  }

                  await ref
                      .read(expenseListControllerProvider.notifier)
                      .deleteExpense(expense.id);
                  if (context.mounted) {
                    for (final p in SummaryPeriod.values) {
                      ref.invalidate(dashboardSummaryControllerProvider(p));
                    }
                    context.router.maybePop();
                  }
                },
                icon: const Icon(Icons.delete),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Hero(
                  tag: 'receipt-${expense.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _ReceiptPreview(path: expense.receiptImagePath),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _InfoTile(
                label: 'ประเภทรายการ',
                value: expense.type == TransactionType.income
                    ? 'รายรับ'
                    : 'รายจ่าย',
              ),
              _InfoTile(label: 'หมวดหมู่', value: expense.category),
              _InfoTile(
                label: 'จำนวนเงิน',
                value:
                    '${expense.type == TransactionType.income ? '+' : '-'} ${expense.currency} ${expense.amount.toStringAsFixed(2)}',
              ),
              _InfoTile(
                label: 'วันที่รายการ',
                value: DateFormat.yMMMMd('th').format(expense.purchasedAt),
              ),
              _InfoTile(
                label: 'จดซ้ำล่วงหน้า',
                value: expense.isRecurring ? 'ใช่' : 'ไม่ใช่',
              ),
              if (expense.isRecurring)
                _InfoTile(
                  label: 'ความถี่',
                  value: _recurringLabel(expense.recurringFrequency),
                ),
              if (expense.nextOccurrence != null)
                _InfoTile(
                  label: 'ครั้งถัดไป',
                  value: DateFormat.yMMMMd(
                    'th',
                  ).format(expense.nextOccurrence!),
                ),
              _InfoTile(
                label: 'แท็ก',
                value: expense.tags.isEmpty
                    ? '-'
                    : expense.tags.map((tag) => '#$tag').join(', '),
              ),
              _InfoTile(
                label: 'บันทึก',
                value: expense.note.isEmpty ? '-' : expense.note,
              ),
              _InfoTile(
                label: 'ข้อความจาก OCR',
                value: expense.receiptRawText.isEmpty
                    ? '-'
                    : expense.receiptRawText,
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: const Text('ใช้งานกับสลิปโอนเงินได้'),
                  subtitle: Text(
                    expense.receiptRawText.isEmpty
                        ? 'รายการนี้ถูกบันทึกแบบกรอกเอง'
                        : 'ระบบดึงข้อความจากรูปสลิปหรือใบเสร็จมาเก็บไว้แล้ว',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(title: Text(label), subtitle: Text(value)),
    );
  }
}

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return Container(
        width: 280,
        height: 280,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.receipt_long, size: 64),
      );
    }

    final file = File(path!);
    if (!file.existsSync()) {
      return Container(
        width: 280,
        height: 280,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.image_not_supported, size: 64),
      );
    }

    return Image.file(
      file,
      width: 280,
      height: 280,
      fit: BoxFit.cover,
      semanticLabel: 'receipt image',
    );
  }
}
