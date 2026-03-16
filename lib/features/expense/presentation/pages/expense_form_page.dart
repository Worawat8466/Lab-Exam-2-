import 'dart:io';

import 'package:auto_route/auto_route.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_router.dart';
import '../../domain/entities/expense.dart';
import '../providers/expense_metadata_controller.dart';
import '../providers/expense_form_controller.dart';

// Helper extension for consistent form field styling
extension InputDecorationBuilder on String {
  InputDecoration asFormLabel({
    required BuildContext context,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: this,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 2,
        ),
      ),
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
    );
  }
}

@RoutePage()
class ExpenseFormPage extends ConsumerStatefulWidget {
  const ExpenseFormPage({super.key, this.expenseId});

  final int? expenseId;

  @override
  ConsumerState<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

enum JotInputMode { manual, scan }

class _ExpenseFormPageState extends ConsumerState<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  final _currencyController = TextEditingController(text: 'THB');
  final _noteController = TextEditingController();
  final _tagsController = TextEditingController();
  final _ocrTextController = TextEditingController();

  DateTime _purchasedAt = DateTime.now();
  DateTime? _nextOccurrence;
  bool _scanCompleted = false;
  bool _isRecurring = false;
  TransactionType _transactionType = TransactionType.expense;
  RecurringFrequency _recurringFrequency = RecurringFrequency.monthly;

  String? _suggestedCategory;
  JotInputMode _inputMode = JotInputMode.manual;
  bool _isPickingImage = false;
  bool _isScanning = false;
  bool _isParsingAi = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final id = widget.expenseId;
      if (id != null) {
        await ref.read(expenseFormControllerProvider.notifier).load(id);
        final state = ref.read(expenseFormControllerProvider).value;
        final expense = state?.expense;
        if (expense != null && mounted) {
          setState(() {
            _transactionType = expense.type;
            _categoryController.text = expense.category;
            _amountController.text = expense.amount.toString();
            _currencyController.text = expense.currency;
            _noteController.text = expense.note;
            _tagsController.text = expense.tags.join(', ');
            _ocrTextController.text = expense.receiptRawText;
            _isRecurring = expense.isRecurring;
            _nextOccurrence = expense.nextOccurrence;
            _recurringFrequency =
                expense.recurringFrequency ?? RecurringFrequency.monthly;
            _purchasedAt = expense.purchasedAt;
          });
        }
      }
    });
  }

  String get _entryLabel =>
      _transactionType == TransactionType.income ? 'รายรับ' : 'รายจ่าย';

  void _rememberPayeeInNote(String payeeName) {
    final trimmed = payeeName.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final line = 'ชื่อผู้รับเงินที่สแกนได้: $trimmed';
    if (_noteController.text.contains(line)) {
      return;
    }
    final existing = _noteController.text.trim();
    _noteController.text = existing.isEmpty ? line : '$line\n$existing';
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    _ocrTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(expenseFormControllerProvider).value;
    final metadataState = ref.watch(expenseMetadataControllerProvider).value;
    final categoryOptions = [
      ...?metadataState?.categories.map((entry) => entry.name),
      if (_categoryController.text.trim().isNotEmpty &&
          !(metadataState?.categories.any(
                (entry) => entry.name == _categoryController.text.trim(),
              ) ??
              false))
        _categoryController.text.trim(),
    ];
    final selectedCategory = _categoryController.text.trim().isEmpty
        ? null
        : _categoryController.text.trim();
    final canParseWithAi =
        !_isParsingAi &&
        !_isScanning &&
        ((formState?.imagePath ?? '').trim().isNotEmpty ||
            _ocrTextController.text.trim().isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.expenseId == null ? 'เพิ่ม$_entryLabel' : 'แก้ไข$_entryLabel',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _scanCompleted
                    ? Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.6)
                    : Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _scanCompleted
                    ? 'อ่านข้อมูลจากสลิปเรียบร้อยแล้ว พร้อมตรวจสอบก่อนบันทึก'
                    : _inputMode == JotInputMode.manual
                    ? 'โหมดกรอกเอง: ใส่ยอด หมวดหมู่ และวันที่ให้ครบ'
                    : 'โหมดสแกน: เลือกรูปและให้ AI เติมข้อมูลให้อัตโนมัติ',
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<JotInputMode>(
              segments: const [
                ButtonSegment(
                  value: JotInputMode.manual,
                  icon: Icon(Icons.keyboard_alt_outlined),
                  label: Text('กรอกเอง'),
                ),
                ButtonSegment(
                  value: JotInputMode.scan,
                  icon: Icon(Icons.document_scanner_outlined),
                  label: Text('สแกนสลิป'),
                ),
              ],
              selected: {_inputMode},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) {
                  return;
                }
                setState(() {
                  _inputMode = selection.first;
                });
              },
            ),
            if (_inputMode == JotInputMode.scan) ...[
              const SizedBox(height: 12),
              if ((formState?.imagePath ?? '').isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.file(
                      File(formState!.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _isPickingImage || _isScanning || _isSaving
                        ? null
                        : () async {
                            setState(() {
                              _isPickingImage = true;
                            });
                            try {
                              await ref
                                  .read(expenseFormControllerProvider.notifier)
                                  .pickImage();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('เลือกรูปเรียบร้อย'),
                                  ),
                                );
                              }
                            } catch (error) {
                              _showError(error.toString());
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isPickingImage = false;
                                });
                              }
                            }
                          },
                    icon: Icon(
                      _isPickingImage
                          ? Icons.hourglass_top
                          : Icons.photo_library,
                    ),
                    label: Text(
                      _isPickingImage ? 'กำลังเลือกรูป...' : 'เลือกรูปสลิป',
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _isScanning || _isParsingAi || _isSaving
                        ? null
                        : () async {
                            setState(() {
                              _isScanning = true;
                            });
                            try {
                              final result = await ref
                                  .read(expenseFormControllerProvider.notifier)
                                  .scanReceiptText();
                              if (result != null && mounted) {
                                _ocrTextController.text = result.rawText;
                                await ref
                                    .read(
                                      expenseFormControllerProvider.notifier,
                                    )
                                    .setScannedText(result.rawText);
                                setState(() {
                                  _scanCompleted = true;
                                });
                              }
                            } catch (error) {
                              _showError(error.toString());
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isScanning = false;
                                });
                              }
                            }
                          },
                    icon: Icon(
                      _isScanning
                          ? Icons.hourglass_top
                          : Icons.document_scanner,
                    ),
                    label: Text(
                      _isScanning ? 'กำลังอ่านสลิป...' : 'อ่านข้อความจากสลิป',
                    ),
                  ),
                ],
              ),
              if (_isScanning || _isParsingAi) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 12),
            ] else
              const SizedBox(height: 8),
            if ((formState?.parsedReceipt?.merchant ?? '')
                .trim()
                .isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI จำชื่อผู้รับเงินไว้: ${formState!.parsedReceipt!.merchant}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Icon(
                              Icons.note_add_outlined,
                              size: 16,
                            ),
                            label: const Text('บันทึกไว้ในโน้ต'),
                            onPressed: () {
                              setState(() {
                                _rememberPayeeInNote(
                                  formState.parsedReceipt!.merchant,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  icon: Icon(Icons.arrow_circle_up),
                  label: Text('รายจ่าย'),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  icon: Icon(Icons.arrow_circle_down),
                  label: Text('รายรับ'),
                ),
              ],
              selected: <TransactionType>{_transactionType},
              onSelectionChanged: (selection) {
                setState(() {
                  _transactionType = selection.first;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: categoryOptions.contains(selectedCategory)
                  ? selectedCategory
                  : null,
              decoration: 'หมวดหมู่'.asFormLabel(
                context: context,
                prefixIcon: const Icon(Icons.category),
                suffixIcon: IconButton(
                  tooltip: 'จัดการหมวดหมู่',
                  onPressed: () async {
                    await context.router.push(const ExpenseMetadataRoute());
                    if (mounted) {
                      await ref
                          .read(expenseMetadataControllerProvider.notifier)
                          .refresh();
                    }
                  },
                  icon: const Icon(Icons.settings_suggest_outlined),
                ),
              ),
              items: categoryOptions
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _categoryController.text = value ?? '';
                });
              },
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'กรุณาเลือกหมวดหมู่';
                }
                return null;
              },
            ),
            if (categoryOptions.isEmpty) ...[
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('ยังไม่มีหมวดหมู่ให้เลือก'),
                  subtitle: const Text(
                    'เพิ่ม ลบ หรือแก้ไขหมวดหมู่ได้จากการตั้งค่า',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await context.router.push(const ExpenseMetadataRoute());
                    if (mounted) {
                      await ref
                          .read(expenseMetadataControllerProvider.notifier)
                          .refresh();
                    }
                  },
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categoryOptions
                    .map(
                      (item) => ChoiceChip(
                        label: Text(item),
                        selected: selectedCategory == item,
                        onSelected: (_) {
                          setState(() {
                            _categoryController.text = item;
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            if ((_suggestedCategory ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: Text('AI เดาหมวดไว้: ${_suggestedCategory!}'),
                  subtitle: Text(
                    categoryOptions.contains(_suggestedCategory)
                        ? 'กดเลือกหมวดนี้ได้ทันที'
                        : 'ถ้ายังไม่มีในรายการ ให้ไปเพิ่มในตั้งค่า',
                  ),
                  trailing: categoryOptions.contains(_suggestedCategory)
                      ? FilledButton(
                          onPressed: () {
                            setState(() {
                              _categoryController.text = _suggestedCategory!;
                            });
                          },
                          child: const Text('เลือก'),
                        )
                      : IconButton(
                          tooltip: 'จัดการหมวดหมู่',
                          onPressed: () async {
                            await context.router.push(
                              const ExpenseMetadataRoute(),
                            );
                            if (mounted) {
                              await ref
                                  .read(
                                    expenseMetadataControllerProvider.notifier,
                                  )
                                  .refresh();
                            }
                          },
                          icon: const Icon(Icons.open_in_new),
                        ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: 'จำนวนเงิน'.asFormLabel(
                context: context,
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกจำนวนเงิน';
                }
                final parsed = double.tryParse(value);
                if (parsed == null) {
                  return 'จำนวนเงินต้องเป็นตัวเลข';
                }
                if (parsed < 0) {
                  return 'จำนวนเงินต้องไม่ติดลบ';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _currencyController,
              decoration: 'สกุลเงิน'.asFormLabel(
                context: context,
                prefixIcon: const Icon(Icons.currency_exchange),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกสกุลเงิน';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagsController,
              decoration: 'แท็ก (คั่นด้วย , เช่น อาหาร, ธุรกิจ)'.asFormLabel(
                context: context,
                prefixIcon: const Icon(Icons.label),
              ),
            ),
            if ((metadataState?.tags.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: metadataState!.tags
                    .map(
                      (item) => ActionChip(
                        label: Text('#${item.name}'),
                        onPressed: () {
                          final current = _tagsController.text
                              .split(',')
                              .map((entry) => entry.trim())
                              .where((entry) => entry.isNotEmpty)
                              .toSet();
                          current.add(item.name);
                          _tagsController.text = current.join(', ');
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('ตั้งจดซ้ำล่วงหน้า'),
              subtitle: const Text(
                'ใช้กับเงินเดือน ค่าบริการรายเดือน หรือค่าเช่า',
              ),
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                  _nextOccurrence ??= _purchasedAt;
                });
              },
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<RecurringFrequency>(
                initialValue: _recurringFrequency,
                decoration: 'ความถี่การจดซ้ำ'.asFormLabel(
                  context: context,
                  prefixIcon: const Icon(Icons.repeat),
                ),
                items: const [
                  DropdownMenuItem(
                    value: RecurringFrequency.weekly,
                    child: Text('ทุกสัปดาห์'),
                  ),
                  DropdownMenuItem(
                    value: RecurringFrequency.monthly,
                    child: Text('ทุกเดือน'),
                  ),
                  DropdownMenuItem(
                    value: RecurringFrequency.quarterly,
                    child: Text('ทุกไตรมาส'),
                  ),
                  DropdownMenuItem(
                    value: RecurringFrequency.yearly,
                    child: Text('ทุกปี'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _recurringFrequency = value;
                  });
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('รอบถัดไป'),
                subtitle: Text(
                  _nextOccurrence == null
                      ? 'ยังไม่ได้เลือก'
                      : DateFormat.yMMMMd('th').format(_nextOccurrence!),
                ),
                trailing: const Icon(Icons.event_repeat),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _nextOccurrence ?? _purchasedAt,
                    firstDate: _purchasedAt,
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );

                  if (picked != null && mounted) {
                    setState(() {
                      _nextOccurrence = picked;
                    });
                  }
                },
              ),
            ],
            const SizedBox(height: 12),
            ListTile(
              title: const Text('วันที่ใช้จ่าย'),
              subtitle: Text(DateFormat.yMMMMd().format(_purchasedAt)),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _purchasedAt,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );

                if (picked != null && mounted) {
                  setState(() {
                    _purchasedAt = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: 'บันทึกเพิ่มเติม'.asFormLabel(
                context: context,
                prefixIcon: const Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            if (_inputMode == JotInputMode.scan) ...[
              TextFormField(
                controller: _ocrTextController,
                decoration: 'ข้อความจาก OCR'.asFormLabel(
                  context: context,
                  prefixIcon: const Icon(Icons.text_snippet),
                ),
                minLines: 3,
                maxLines: 6,
                onChanged: (value) {
                  ref
                      .read(expenseFormControllerProvider.notifier)
                      .setScannedText(value);
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: canParseWithAi
                    ? () async {
                        setState(() {
                          _isParsingAi = true;
                        });
                        try {
                          final parsed = await ref
                              .read(expenseFormControllerProvider.notifier)
                              .parseReceiptWithAi();
                          if (parsed == null) {
                            return;
                          }

                          _categoryController.clear();
                          _amountController.text = parsed.amount
                              .toStringAsFixed(2);
                          _currencyController.text = parsed.currency;
                          _transactionType = parsed.transactionType;
                          _tagsController.text = parsed.suggestedTags.join(
                            ', ',
                          );
                          _suggestedCategory = parsed.suggestedCategory;
                          _rememberPayeeInNote(parsed.merchant);
                          if (parsed.occurredAt != null) {
                            _purchasedAt = parsed.occurredAt!;
                          }

                          if (mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'AI เติมยอดเงินให้แล้ว และจำชื่อผู้รับเงินไว้ในโน้ต (${(parsed.confidence * 100).toStringAsFixed(0)}%)',
                                ),
                              ),
                            );
                          }
                        } catch (error) {
                          _showError(error.toString());
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isParsingAi = false;
                            });
                          }
                        }
                      }
                    : null,
                icon: Icon(
                  _isParsingAi ? Icons.hourglass_top : Icons.auto_fix_high,
                ),
                label: Text(
                  _isParsingAi ? 'AI กำลังดึงข้อมูล...' : 'AI ดึงข้อมูลจากสลิป',
                ),
              ),
            ],
            if ((formState?.aiReason ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('เหตุผลจาก AI: ${formState?.aiReason}'),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSaving || _isScanning || _isParsingAi
                  ? null
                  : () async {
                      if (!(_formKey.currentState?.validate() ?? false)) {
                        return;
                      }

                      setState(() {
                        _isSaving = true;
                      });
                      try {
                        await ref
                            .read(expenseFormControllerProvider.notifier)
                            .submit(
                              existingId: widget.expenseId,
                              type: _transactionType,
                              merchant: '',
                              category: _categoryController.text.trim(),
                              amount: double.parse(
                                _amountController.text.trim(),
                              ),
                              currency: _currencyController.text.trim(),
                              note: _noteController.text.trim(),
                              tags: _tagsController.text
                                  .split(',')
                                  .map((entry) => entry.trim())
                                  .where((entry) => entry.isNotEmpty)
                                  .toSet()
                                  .toList(),
                              isRecurring: _isRecurring,
                              recurringFrequency: _isRecurring
                                  ? _recurringFrequency
                                  : null,
                              nextOccurrence: _isRecurring
                                  ? _nextOccurrence
                                  : null,
                              purchasedAt: _purchasedAt,
                            );
                        if (mounted) {
                          context.router.maybePop();
                        }
                      } catch (error) {
                        _showError(error.toString());
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isSaving = false;
                          });
                        }
                      }
                    },
              child: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึก$_entryLabel'),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
