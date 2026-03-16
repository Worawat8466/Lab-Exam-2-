import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../expense/domain/entities/expense.dart';
import '../../../expense/presentation/providers/expense_metadata_controller.dart';
import '../../../expense/presentation/providers/expense_form_controller.dart';
import '../../../settings/domain/entities/app_language.dart';
import '../../../settings/presentation/providers/app_language_controller.dart';

@RoutePage()
class AutoScanAiReviewPage extends ConsumerStatefulWidget {
  const AutoScanAiReviewPage({super.key});

  @override
  ConsumerState<AutoScanAiReviewPage> createState() =>
      _AutoScanAiReviewPageState();
}

class _AutoScanAiReviewPageState extends ConsumerState<AutoScanAiReviewPage> {
  bool _processing = false;
  String? _selectedCategory;
  String? _lastParsedSignature;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(expenseFormControllerProvider).value;
    final images = formState?.galleryImages ?? const [];
    final parsed = formState?.parsedReceipt;
    final metadataState = ref.watch(expenseMetadataControllerProvider).value;
    final languageAsync = ref.watch(appLanguageControllerProvider);
    final language = languageAsync.value ?? AppLanguage.thai;
    final strings = AppStrings.of(language);
    final categoryOptions = [
      ...?metadataState?.categories.map((entry) => entry.name),
      if ((_selectedCategory ?? '').isNotEmpty &&
          !(metadataState?.categories.any(
                (entry) => entry.name == _selectedCategory,
              ) ??
              false))
        _selectedCategory!,
    ];

    if (parsed != null) {
      final signature =
          '${parsed.merchant}|${parsed.suggestedCategory}|${parsed.amount}|${parsed.currency}|${parsed.occurredAt?.millisecondsSinceEpoch}';
      if (signature != _lastParsedSignature) {
        _lastParsedSignature = signature;
        _selectedCategory = categoryOptions.contains(parsed.suggestedCategory)
            ? parsed.suggestedCategory
            : null;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(strings.scanTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: () async {
              try {
                await ref
                    .read(expenseFormControllerProvider.notifier)
                    .loadCurrentMonthGalleryImages();
              } catch (error) {
                _showError(error.toString());
              }
            },
            icon: const Icon(Icons.photo_library),
            label: Text(strings.loadGallery),
          ),
          const SizedBox(height: 12),
          if (images.isEmpty)
            Text(strings.noImages)
          else ...[
            // ── Image grid ──────────────────────────────────────────────
            SizedBox(
              height: 220,
              child: ListView.separated(
                itemCount: images.length,
                scrollDirection: Axis.horizontal,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  final item = images[index];
                  final isSelected =
                      (formState?.imagePath ?? '') == item.localPath;
                  return GestureDetector(
                    onTap: () async {
                      await ref
                          .read(expenseFormControllerProvider.notifier)
                          .selectGalleryImage(item.localPath);
                    },
                    child: SizedBox(
                      width: 170,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  Expanded(
                                    child: Hero(
                                      tag: 'scan-${item.assetId}',
                                      child: _ImagePreview(
                                        path: item.localPath,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      DateFormat.yMMMd(
                                        'th',
                                      ).add_Hm().format(item.createdAt),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                  ),
                                ],
                              ),
                              // ─ Selected checkmark badge ─────────────
                              if (isSelected)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // ── Selected image preview ───────────────────────────────────
            if ((formState?.imagePath ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.15),
                ),
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: _ImagePreview(path: formState!.imagePath ?? ''),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            language == AppLanguage.thai
                                ? 'รูปที่เลือกแล้ว ✓'
                                : 'Image selected ✓',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            language == AppLanguage.thai
                                ? 'กดปุ่ม AI ด้านล่างเพื่อดึงข้อมูลอัตโนมัติ'
                                : 'Tap the AI button below to extract data',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_downward_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: _processing
                ? _MascotLoadingCard(
                    key: const ValueKey('processing'),
                    title: strings.aiProcessing,
                    subtitle: language == AppLanguage.thai
                        ? 'กำลัง OCR และส่งข้อมูลให้ AI ช่วยจัดหมวดหมู่'
                        : 'Running OCR and asking AI to classify the receipt',
                  )
                : Card(
                    key: const ValueKey('idle'),
                    child: ListTile(
                      leading: const Icon(Icons.smart_toy_outlined),
                      title: Text(
                        language == AppLanguage.thai
                            ? 'พร้อมประมวลผล'
                            : 'Ready to Process',
                      ),
                      subtitle: Text(
                        language == AppLanguage.thai
                            ? 'เลือกรูปแล้วกดปุ่มด้านล่างเพื่อเริ่ม AI review'
                            : 'Pick an image and tap below to start AI review',
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _processing
                ? null
                : () async {
                    if ((formState?.imagePath ?? '').isEmpty) {
                      _showError(
                        language == AppLanguage.thai
                            ? 'กรุณาเลือกรูปใบเสร็จก่อนเริ่มประมวลผล'
                            : 'Please select a receipt image before processing',
                      );
                      return;
                    }

                    try {
                      setState(() => _processing = true);
                      final scan = await ref
                          .read(expenseFormControllerProvider.notifier)
                          .scanReceiptText();
                      if (scan != null) {
                        await ref
                            .read(expenseFormControllerProvider.notifier)
                            .setScannedText(scan.rawText);
                        await ref
                            .read(expenseFormControllerProvider.notifier)
                            .parseReceiptWithAi();
                      }
                    } catch (error) {
                      _showError(error.toString());
                    } finally {
                      if (mounted) {
                        setState(() => _processing = false);
                      }
                    }
                  },
            icon: const Icon(Icons.auto_awesome),
            label: Text(strings.runAiParse),
          ),
          const SizedBox(height: 12),
          if (parsed != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language == AppLanguage.thai
                          ? 'ตรวจสอบก่อนบันทึก'
                          : 'Review Before Saving',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${language == AppLanguage.thai ? 'ชื่อผู้รับเงินที่ AI จำไว้' : 'Remembered payee'}: ${parsed.merchant}',
                    ),
                    Text(
                      '${language == AppLanguage.thai ? 'ยอดเงิน' : 'Amount'}: ${parsed.amount.toStringAsFixed(2)} ${parsed.currency}',
                    ),
                    Text(
                      '${language == AppLanguage.thai ? 'หมวดที่ AI เดาไว้' : 'Suggested category'}: ${parsed.suggestedCategory}',
                    ),
                    Text(
                      '${language == AppLanguage.thai ? 'ประเภท' : 'Type'}: ${parsed.transactionType == TransactionType.income ? (language == AppLanguage.thai ? 'รายรับ' : 'Income') : (language == AppLanguage.thai ? 'รายจ่าย' : 'Expense')}',
                    ),
                    Text(
                      '${language == AppLanguage.thai ? 'แท็ก' : 'Tags'}: ${parsed.suggestedTags.join(', ')}',
                    ),
                    Text(
                      '${language == AppLanguage.thai ? 'ความมั่นใจ' : 'Confidence'}: ${(parsed.confidence * 100).toStringAsFixed(0)}%',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${language == AppLanguage.thai ? 'เหตุผล AI' : 'AI Reasoning'}: ${parsed.reasoning}',
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: categoryOptions.contains(_selectedCategory)
                          ? _selectedCategory
                          : null,
                      decoration: InputDecoration(
                        labelText: language == AppLanguage.thai
                            ? 'หมวดหมู่'
                            : 'Category',
                        helperText: language == AppLanguage.thai
                            ? 'AI เดาไว้ว่า ${parsed.suggestedCategory}'
                            : 'AI suggested ${parsed.suggestedCategory}',
                        border: const OutlineInputBorder(),
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
                          _selectedCategory = value;
                        });
                      },
                    ),
                    if (categoryOptions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          language == AppLanguage.thai
                              ? 'ยังไม่มีหมวดหมู่ในระบบ ให้ไปเพิ่มในตั้งค่าก่อน'
                              : 'No categories yet. Add them in settings first.',
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              try {
                                final category = (_selectedCategory ?? '')
                                    .trim();
                                if (category.isEmpty) {
                                  _showError(
                                    language == AppLanguage.thai
                                        ? 'กรุณาเลือกหมวดหมู่ก่อนบันทึก'
                                        : 'Please select category before saving',
                                  );
                                  return;
                                }

                                await ref
                                    .read(
                                      expenseFormControllerProvider.notifier,
                                    )
                                    .submit(
                                      existingId: null,
                                      type: parsed.transactionType,
                                      merchant: '',
                                      category: category,
                                      amount: parsed.amount,
                                      currency: parsed.currency,
                                      note:
                                          'ชื่อผู้รับเงินที่ AI จำไว้: ${parsed.merchant}\nบันทึกจาก Auto-Scan AI Review',
                                      tags: parsed.suggestedTags,
                                      isRecurring: false,
                                      recurringFrequency: null,
                                      nextOccurrence: null,
                                      purchasedAt:
                                          parsed.occurredAt ?? DateTime.now(),
                                    );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        language == AppLanguage.thai
                                            ? 'บันทึกรายการสำเร็จ'
                                            : 'Transaction saved successfully',
                                      ),
                                    ),
                                  );
                                  context.router.maybePop();
                                }
                              } catch (error) {
                                _showError(error.toString());
                              }
                            },
                            child: Text(strings.confirmAndSave),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
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

class _MascotLoadingCard extends StatelessWidget {
  const _MascotLoadingCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.92, end: 1.08),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOut,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              onEnd: () {},
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Semantics(
                  label: 'processing mascot',
                  child: Text('🐾', style: TextStyle(fontSize: 28)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle),
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.image_not_supported)),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      width: double.infinity,
      semanticLabel: 'selected receipt image',
    );
  }
}
