import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/expense_metadata_controller.dart';

@RoutePage()
class ExpenseMetadataPage extends ConsumerStatefulWidget {
  const ExpenseMetadataPage({super.key});

  @override
  ConsumerState<ExpenseMetadataPage> createState() =>
      _ExpenseMetadataPageState();
}

class _ExpenseMetadataPageState extends ConsumerState<ExpenseMetadataPage> {
  final _categoryController = TextEditingController();
  final _tagController = TextEditingController();

  Future<void> _openCategoryDialog({
    String initialValue = '',
    required String title,
    required Future<void> Function(String value) onSave,
  }) async {
    _categoryController.text = initialValue;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: _categoryController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'ชื่อหมวดหมู่',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () async {
              final value = _categoryController.text.trim();
              if (value.isEmpty) {
                return;
              }
              await onSave(value);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
    _categoryController.clear();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metadataAsync = ref.watch(expenseMetadataControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('จัดการหมวดหมู่และแท็ก')),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(expenseMetadataControllerProvider.notifier).refresh(),
        child: metadataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(child: Text('เกิดข้อผิดพลาด: $error')),
            ],
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('หมวดหมู่', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ใช้หมวดหมู่ชุดเดียวกันทั้งแอพ และเลือกจากรายการตอนเพิ่มรายการ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      await _openCategoryDialog(
                        title: 'เพิ่มหมวดหมู่',
                        onSave: (value) => ref
                            .read(expenseMetadataControllerProvider.notifier)
                            .saveCategory(name: value),
                      );
                    },
                    child: const Text('เพิ่ม'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data.categories
                    .map(
                      (item) => InputChip(
                        label: Text(item.name),
                        onPressed: () async {
                          await _openCategoryDialog(
                            title: 'แก้ไขหมวดหมู่',
                            initialValue: item.name,
                            onSave: (value) => ref
                                .read(
                                  expenseMetadataControllerProvider.notifier,
                                )
                                .saveCategory(
                                  name: value,
                                  existingId: item.id,
                                  createdAt: item.createdAt,
                                  isDefault: item.isDefault,
                                  emoji: item.emoji,
                                  colorHex: item.colorHex,
                                ),
                          );
                        },
                        onDeleted: () async {
                          await ref
                              .read(expenseMetadataControllerProvider.notifier)
                              .deleteCategory(item.id);
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text('แท็ก', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        hintText: 'เพิ่มแท็กใหม่',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final value = _tagController.text.trim();
                      if (value.isEmpty) {
                        return;
                      }
                      await ref
                          .read(expenseMetadataControllerProvider.notifier)
                          .saveTag(name: value);
                      _tagController.clear();
                    },
                    child: const Text('เพิ่ม'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data.tags
                    .map(
                      (item) => InputChip(
                        label: Text('#${item.name}'),
                        onDeleted: () async {
                          await ref
                              .read(expenseMetadataControllerProvider.notifier)
                              .deleteTag(item.id);
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
