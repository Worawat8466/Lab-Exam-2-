import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../dashboard/domain/entities/category_breakdown.dart';
import '../../../dashboard/domain/entities/summary_period.dart';
import '../../../dashboard/presentation/providers/dashboard_summary_controller.dart';
import '../../../expense/domain/entities/expense.dart';
import '../../../expense/presentation/providers/expense_list_controller.dart';
import '../providers/home_summary_period_controller.dart';
import '../providers/smart_auto_scan_controller.dart';
import '../../../settings/domain/entities/app_language.dart';
import '../../../settings/presentation/providers/api_key_controller.dart';
import '../../../settings/presentation/providers/app_language_controller.dart';
import '../../../settings/presentation/providers/theme_mode_controller.dart';
import '../../../dashboard/domain/entities/dashboard_summary.dart';
import '../../../dashboard/presentation/providers/ai_insight_notifier.dart';

@RoutePage()
class HomeShellPage extends ConsumerStatefulWidget {
  const HomeShellPage({super.key});

  @override
  ConsumerState<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends ConsumerState<HomeShellPage> {
  int _index = 0;
  bool _permissionSheetVisible = false;
  bool _candidateSheetVisible = false;
  String? _lastScanFeedbackKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(smartAutoScanControllerProvider.notifier).initialize();
    });
  }

  void _onAddManually() {
    context.router.push(ExpenseFormRoute());
  }

  Future<void> _showPermissionSheet(AppStrings strings) async {
    _permissionSheetVisible = true;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.smartScanPermissionTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(strings.smartScanPermissionBody),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref
                              .read(smartAutoScanControllerProvider.notifier)
                              .dismissPrompt();
                        },
                        child: Text(strings.smartScanLater),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref
                              .read(smartAutoScanControllerProvider.notifier)
                              .requestPermissionAndDiscover();
                        },
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(strings.smartScanAllow),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    _permissionSheetVisible = false;
    if (mounted &&
        ref.read(smartAutoScanControllerProvider).value?.stage ==
            SmartAutoScanStage.permissionPrompt) {
      ref.read(smartAutoScanControllerProvider.notifier).dismissPrompt();
    }
  }

  Future<void> _showCandidateSheet(
    AppStrings strings,
    SmartAutoScanState state,
  ) async {
    _candidateSheetVisible = true;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.smartScanFoundCandidates(state.candidates.length),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(strings.smartScanCandidateSubtitle(state.checkedCount)),
                const SizedBox(height: 12),
                ...state.candidates
                    .take(3)
                    .map(
                      (image) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Image.file(
                              File(image.localPath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.receipt),
                            ),
                          ),
                        ),
                        title: Text(
                          DateFormat.yMMMd(
                            'th',
                          ).add_Hm().format(image.createdAt),
                        ),
                        subtitle: Text(image.localPath.split('\\').last),
                      ),
                    ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref
                              .read(smartAutoScanControllerProvider.notifier)
                              .dismissPrompt();
                        },
                        child: Text(strings.smartScanLater),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ref
                              .read(smartAutoScanControllerProvider.notifier)
                              .processCandidates();
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(strings.smartScanConfirm),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    _candidateSheetVisible = false;
    if (mounted &&
        ref.read(smartAutoScanControllerProvider).value?.stage ==
            SmartAutoScanStage.reviewPrompt) {
      ref.read(smartAutoScanControllerProvider.notifier).dismissPrompt();
    }
  }

  void _handleSmartScanUi(AppStrings strings, SmartAutoScanState scanState) {
    if (_index != 0) {
      return;
    }

    if (scanState.stage == SmartAutoScanStage.permissionPrompt &&
        !_permissionSheetVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermissionSheet(strings);
      });
    }

    if (scanState.stage == SmartAutoScanStage.reviewPrompt &&
        !_candidateSheetVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCandidateSheet(strings, scanState);
      });
    }

    String? feedback;
    switch (scanState.stage) {
      case SmartAutoScanStage.permissionDenied:
        feedback = strings.smartScanDenied;
        break;
      case SmartAutoScanStage.completed:
        switch (scanState.message) {
          case 'no_new_slips':
            feedback = strings.smartScanNoNew;
            break;
          case 'no_qr_candidates':
            feedback = strings.smartScanNoCandidates;
            break;
          case 'processing_complete':
            feedback = strings.smartScanCompleted(
              scanState.savedCount,
              scanState.failedCount,
            );
            break;
          default:
            feedback = null;
        }
        break;
      case SmartAutoScanStage.error:
        feedback = scanState.message;
        break;
      case SmartAutoScanStage.idle:
      case SmartAutoScanStage.scanning:
      case SmartAutoScanStage.reviewPrompt:
      case SmartAutoScanStage.processing:
      case SmartAutoScanStage.permissionPrompt:
        feedback = null;
        break;
    }

    final feedbackKey =
        '${scanState.stage.name}-${scanState.message}-${scanState.savedCount}-${scanState.failedCount}';
    if (feedback != null && feedbackKey != _lastScanFeedbackKey) {
      _lastScanFeedbackKey = feedbackKey;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        final period =
            ref.read(homeSummaryPeriodControllerProvider).value ??
            SummaryPeriod.monthly;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(feedback!)));
        await ref.read(expenseListControllerProvider.notifier).refresh();
        ref.invalidate(dashboardSummaryControllerProvider(period));
        ref.read(smartAutoScanControllerProvider.notifier).clearCompletion();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageAsync = ref.watch(appLanguageControllerProvider);
    final language = languageAsync.value ?? AppLanguage.thai;
    final strings = AppStrings.of(language);
    final periodAsync = ref.watch(homeSummaryPeriodControllerProvider);
    final period = periodAsync.value ?? SummaryPeriod.monthly;
    final smartScanAsync = ref.watch(smartAutoScanControllerProvider);
    final smartScanState = smartScanAsync.value ?? const SmartAutoScanState();

    _handleSmartScanUi(strings, smartScanState);

    final Widget currentPage = switch (_index) {
      0 => KeyedSubtree(
        key: const ValueKey('tab_home_active'),
        child: _DashboardTab(
          period: period,
          onPeriodChanged: (value) {
            ref
                .read(homeSummaryPeriodControllerProvider.notifier)
                .setPeriod(value);
          },
        ),
      ),
      1 => const KeyedSubtree(
        key: ValueKey('tab_history_active'),
        child: _HistoryTab(),
      ),
      _ => const KeyedSubtree(
        key: ValueKey('tab_settings_active'),
        child: _SettingsTab(),
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _index == 0
              ? strings.appTitle
              : _index == 1
              ? strings.historyTitle
              : strings.settingsTitle,
        ),
        actions: _index == 0
            ? [
                IconButton(
                  tooltip: strings.manageCategoryTooltip,
                  onPressed: () =>
                      context.router.push(const ExpenseMetadataRoute()),
                  icon: const Icon(Icons.category_outlined),
                ),
              ]
            : null,
      ),
      body: currentPage,
      floatingActionButton: _index == 2
          ? null
          : FloatingActionButton.extended(
              heroTag: 'fab_jot',
              tooltip: strings.addManually,
              onPressed: _onAddManually,
              icon: const Icon(Icons.edit_note),
              label: Text(strings.addManually),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          if (_index == value) {
            return;
          }
          setState(() {
            _index = value;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: strings.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: strings.navHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: strings.navSettings,
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab({required this.period, required this.onPeriodChanged});

  final SummaryPeriod period;
  final ValueChanged<SummaryPeriod> onPeriodChanged;

  String _selectedPeriodLabel(AppStrings strings, SummaryPeriod value) {
    switch (value) {
      case SummaryPeriod.weekly:
        return strings.weekly;
      case SummaryPeriod.monthly:
        return strings.monthly;
      case SummaryPeriod.quarterly:
        return strings.quarterly;
      case SummaryPeriod.yearly:
        return strings.yearly;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryControllerProvider(period));
    final expensesAsync = ref.watch(expenseListControllerProvider);
    final smartScanAsync = ref.watch(smartAutoScanControllerProvider);
    final smartScanState = smartScanAsync.value ?? const SmartAutoScanState();
    final languageAsync = ref.watch(appLanguageControllerProvider);
    final language = languageAsync.value ?? AppLanguage.thai;
    final strings = AppStrings.of(language);
    final progressLabel = smartScanState.totalCount > 0
        ? '${smartScanState.processedCount}/${smartScanState.totalCount}'
        : null;
    final progressValue = smartScanState.totalCount > 0
        ? smartScanState.processedCount / smartScanState.totalCount
        : null;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(expenseListControllerProvider.notifier).refresh();
        ref.invalidate(dashboardSummaryControllerProvider(period));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (smartScanState.isBusy) ...[
            _SmartAutoScanStatusCard(
              title: strings.smartScanStatusTitle,
              message: smartScanState.stage == SmartAutoScanStage.processing
                  ? strings.smartScanProcessingAi
                  : strings.smartScanLoadingGallery,
              progressLabel: progressLabel,
              progressValue: progressValue,
            ),
            const SizedBox(height: 12),
          ],
          _PeriodChips(
            selected: period,
            onChanged: onPeriodChanged,
            strings: strings,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('manage_categories_action'),
                onPressed: () =>
                    context.router.push(const ExpenseMetadataRoute()),
                icon: const Icon(Icons.category_outlined),
                label: Text(strings.manageCategories),
              ),
              FilledButton.icon(
                key: const ValueKey('smart_scan_action'),
                onPressed: smartScanState.isBusy
                    ? null
                    : () {
                        ref
                            .read(smartAutoScanControllerProvider.notifier)
                            .requestPermissionAndDiscover();
                      },
                icon: const Icon(Icons.qr_code_scanner_outlined),
                label: Text(
                  language == AppLanguage.thai ? 'Smart Scan' : 'Smart Scan',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${strings.spendingByCategory}: ${_selectedPeriodLabel(strings, period)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          summaryAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('โหลดสรุปไม่สำเร็จ: $error'),
            data: (summary) => Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 1,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${strings.totalSpend} (${_selectedPeriodLabel(strings, period)})',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            '฿ ${summary.totalExpense.toStringAsFixed(2)}',
                            key: ValueKey<double>(summary.totalExpense),
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w800,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatChip(
                                label: strings.totalIncome,
                                value:
                                    '+${summary.totalIncome.toStringAsFixed(2)}',
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatChip(
                                label: strings.balance,
                                value: summary.balance.toStringAsFixed(2),
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatChip(
                                label: language == AppLanguage.thai
                                    ? 'เทียบช่วงก่อน'
                                    : 'vs previous',
                                value:
                                    '${summary.comparison.percentChange >= 0 ? '+' : ''}${summary.comparison.percentChange.toStringAsFixed(1)}%',
                                color: summary.comparison.percentChange >= 0
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.spendingByCategory,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        summary.topCategories.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(strings.noCategory),
                                ),
                              )
                            : _PieChart(categories: summary.topCategories),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _AiInsightCard(summary: summary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          expensesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (items) {
              final recent = items.take(5).toList();
              if (recent.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(child: Text(strings.noItems)),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.recentItems,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...recent.map(
                    (expense) => Card(
                      child: ListTile(
                        onTap: () => context.router.push(
                          ExpenseDetailRoute(expenseId: expense.id),
                        ),
                        leading: Hero(
                          tag: 'receipt-${expense.id}',
                          child: _Thumb(path: expense.receiptImagePath),
                        ),
                        title: Text(expense.category),
                        subtitle: Text(
                          '${expense.type == TransactionType.income ? 'รายรับ' : 'รายจ่าย'} • ${DateFormat.yMMMd('th').format(expense.purchasedAt)}',
                        ),
                        trailing: SizedBox(
                          width: 110,
                          child: Text(
                            '${expense.type == TransactionType.income ? '+' : '-'} ${expense.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: expense.type == TransactionType.income
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _AiInsightCard extends ConsumerStatefulWidget {
  const _AiInsightCard({required this.summary});

  final DashboardSummary summary;

  @override
  ConsumerState<_AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends ConsumerState<_AiInsightCard> {
  static const int _cooldownUnchangedSeconds = 15;
  static const int _cooldownChangedSeconds = 6;

  DateTime? _nextAnalyzeAllowedAt;
  Timer? _cooldownTimer;
  String? _lastAnalyzedSummarySignature;
  bool _lastCooldownWasUnchanged = false;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  bool get _isCoolingDown {
    final next = _nextAnalyzeAllowedAt;
    if (next == null) {
      return false;
    }
    return DateTime.now().isBefore(next);
  }

  int get _remainingCooldownSeconds {
    final next = _nextAnalyzeAllowedAt;
    if (next == null) {
      return 0;
    }
    final diff = next.difference(DateTime.now()).inSeconds;
    return diff <= 0 ? 0 : diff;
  }

  void _startCooldown({required int seconds, required bool unchangedSummary}) {
    _lastCooldownWasUnchanged = unchangedSummary;
    _nextAnalyzeAllowedAt = DateTime.now().add(Duration(seconds: seconds));

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isCoolingDown) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _nextAnalyzeAllowedAt = null;
          });
        }
        return;
      }
      setState(() {});
    });
    setState(() {});
  }

  void _showCooldownHint(AppLanguage language) {
    final seconds = _remainingCooldownSeconds;
    if (seconds <= 0 || !mounted) {
      return;
    }
    final message = _lastCooldownWasUnchanged
        ? (language == AppLanguage.thai
              ? 'ข้อมูลยังไม่เปลี่ยน รออีก $seconds วินาทีเพื่อให้คำแนะนำต่างขึ้น'
              : 'Data is unchanged. Wait $seconds seconds for more varied advice.')
        : (language == AppLanguage.thai
              ? 'รออีก $seconds วินาที แล้วลองวิเคราะห์ใหม่'
              : 'Please wait $seconds seconds before analyzing again.');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _buildSummarySignature(DashboardSummary summary) {
    final categories = summary.topCategories
        .take(3)
        .map(
          (entry) =>
              '${entry.categoryName}:${entry.totalAmount.toStringAsFixed(0)}',
        )
        .join('|');
    return [
      summary.period.name,
      summary.totalExpense.toStringAsFixed(0),
      summary.totalIncome.toStringAsFixed(0),
      summary.balance.toStringAsFixed(0),
      summary.comparison.percentChange.toStringAsFixed(1),
      categories,
    ].join('#');
  }

  Future<void> _analyze(DashboardSummary summary, AppLanguage language) async {
    if (_isCoolingDown) {
      _showCooldownHint(language);
      return;
    }

    final signature = _buildSummarySignature(summary);
    final unchangedSummary = signature == _lastAnalyzedSummarySignature;
    final cooldownSeconds = unchangedSummary
        ? _cooldownUnchangedSeconds
        : _cooldownChangedSeconds;

    _startCooldown(
      seconds: cooldownSeconds,
      unchangedSummary: unchangedSummary,
    );
    await ref.read(aiInsightNotifierProvider.notifier).analyze(summary);
    _lastAnalyzedSummarySignature = signature;
  }

  String _cleanInsightLine(String raw) {
    return raw
        .replaceAll(RegExp(r'\*\*|\*'), '')
        .replaceAll(RegExp(r'^[-*•\s]+'), '')
        .replaceAll(RegExp(r'^\d+[\.)]\s*'), '')
        .trim();
  }

  List<_InsightAction> _buildActions({
    required String insightsJoined,
    required BuildContext context,
    required AppLanguage language,
  }) {
    final text = insightsJoined.toLowerCase();
    final actions = <_InsightAction>[];

    final needsCategory =
        text.contains('หมวด') ||
        text.contains('แท็ก') ||
        text.contains('category') ||
        text.contains('tag');
    final needsReview =
        text.contains('ทบทวน') ||
        text.contains('ย้อนหลัง') ||
        text.contains('history') ||
        text.contains('review');
    final needsControl =
        text.contains('คุม') ||
        text.contains('ลด') ||
        text.contains('budget') ||
        text.contains('overspend') ||
        text.contains('อาหาร') ||
        text.contains('food');

    if (needsControl) {
      actions.add(
        _InsightAction(
          icon: Icons.edit_note_outlined,
          label: language == AppLanguage.thai ? 'จดรายการทันที' : 'Log Now',
          onTap: () => context.router.push(ExpenseFormRoute()),
        ),
      );
    }

    if (needsReview) {
      actions.add(
        _InsightAction(
          icon: Icons.receipt_long_outlined,
          label: language == AppLanguage.thai
              ? 'เปิดประวัติรายการ'
              : 'Open History',
          onTap: () => context.router.push(const ExpenseListRoute()),
        ),
      );
    }

    if (needsCategory) {
      actions.add(
        _InsightAction(
          icon: Icons.category_outlined,
          label: language == AppLanguage.thai
              ? 'จัดการหมวดหมู่'
              : 'Manage Categories',
          onTap: () => context.router.push(const ExpenseMetadataRoute()),
        ),
      );
    }

    if (actions.isEmpty) {
      actions.add(
        _InsightAction(
          icon: Icons.edit_note_outlined,
          label: language == AppLanguage.thai
              ? 'เริ่มจดรายการ'
              : 'Start Logging',
          onTap: () => context.router.push(ExpenseFormRoute()),
        ),
      );
    }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final insightAsync = ref.watch(aiInsightNotifierProvider);
    final language =
        ref.watch(appLanguageControllerProvider).value ?? AppLanguage.thai;
    final hasData = insightAsync.value?.isNotEmpty == true;
    final isLoading = insightAsync.isLoading;
    final hasError = insightAsync.hasError && !hasData;
    final canAnalyze = !_isCoolingDown && !isLoading;

    // Direct string instead of split/first/take logic
    final rawInsightText = insightAsync.value ?? '';
    final cleanedText = _cleanInsightLine(rawInsightText);

    final actions = _buildActions(
      insightsJoined: cleanedText,
      context: context,
      language: language,
    );

    final refreshTooltip = _isCoolingDown
        ? _lastCooldownWasUnchanged
              ? (language == AppLanguage.thai
                    ? 'ข้อมูลเดิม: รอ ${_remainingCooldownSeconds}s ก่อนวิเคราะห์ซ้ำ'
                    : 'Unchanged data: wait ${_remainingCooldownSeconds}s before retry')
              : (language == AppLanguage.thai
                    ? 'รออีก ${_remainingCooldownSeconds}s ก่อนวิเคราะห์ซ้ำ'
                    : 'Wait ${_remainingCooldownSeconds}s before retry')
        : (language == AppLanguage.thai
              ? 'วิเคราะห์อีกครั้ง'
              : 'Analyze again');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(
              context,
            ).colorScheme.tertiaryContainer.withValues(alpha: 0.6),
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.tertiary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.tertiary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    language == AppLanguage.thai
                        ? 'AI วิเคราะห์รายจ่าย'
                        : 'AI Spending Insight',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (hasData)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 22),
                    tooltip: refreshTooltip,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      elevation: 2,
                      shadowColor: Theme.of(
                        context,
                      ).shadowColor.withValues(alpha: 0.2),
                    ),
                    onPressed: canAnalyze
                        ? () => _analyze(widget.summary, language)
                        : () => _showCooldownHint(language),
                  ),
              ],
            ),
            if (_isCoolingDown) ...[
              const SizedBox(height: 8),
              Text(
                _lastCooldownWasUnchanged
                    ? (language == AppLanguage.thai
                          ? 'ข้อมูลยังไม่เปลี่ยน: วิเคราะห์ซ้ำได้ในอีก $_remainingCooldownSeconds วินาที'
                          : 'Data unchanged: re-analyze available in ${_remainingCooldownSeconds}s')
                    : (language == AppLanguage.thai
                          ? 'วิเคราะห์ซ้ำได้ในอีก $_remainingCooldownSeconds วินาที'
                          : 'Re-analyze available in ${_remainingCooldownSeconds}s'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (isLoading) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  language == AppLanguage.thai
                      ? 'AI กำลังวิเคราะห์รายจ่ายของคุณอย่างตั้งใจ...'
                      : 'AI is carefully analyzing your spending...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else if (hasError) ...[
              Center(
                child: Text(
                  language == AppLanguage.thai
                      ? 'วิเคราะห์ไม่สำเร็จ กรุณาลองใหม่'
                      : 'Analysis failed. Please retry.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: FilledButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    language == AppLanguage.thai ? 'ลองใหม่' : 'Retry',
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: canAnalyze
                      ? () => _analyze(widget.summary, language)
                      : () => _showCooldownHint(language),
                ),
              ),
            ] else if (hasData) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  cleanedText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                language == AppLanguage.thai
                    ? 'เริ่มลงมือทำทันที'
                    : 'Take Action',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: actions
                    .map(
                      (action) => ActionChip(
                        avatar: Icon(
                          action.icon,
                          size: 20,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        label: Text(
                          action.label,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onPressed: action.onTap,
                      ),
                    )
                    .toList(),
              ),
            ] else ...[
              Center(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.analytics),
                  label: Text(
                    language == AppLanguage.thai
                        ? 'วิเคราะห์รายจ่ายด้วย AI'
                        : 'Analyze with AI',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: widget.summary.topCategories.isEmpty
                      ? null
                      : canAnalyze
                      ? () => _analyze(widget.summary, language)
                      : () => _showCooldownHint(language),
                ),
              ),
              if (widget.summary.topCategories.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(
                      language == AppLanguage.thai
                          ? 'เพิ่มรายการก่อนเพื่อให้ AI วิเคราะห์'
                          : 'Add transactions first for AI analysis.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              if (widget.summary.topCategories.isNotEmpty && _isCoolingDown)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(
                      _lastCooldownWasUnchanged
                          ? (language == AppLanguage.thai
                                ? 'ข้อมูลเดิมอยู่: รอคูลดาวน์ $_remainingCooldownSeconds วินาที เพื่อผลลัพธ์ที่ต่างขึ้น'
                                : 'Summary unchanged: wait ${_remainingCooldownSeconds}s cooldown for more varied results.')
                          : (language == AppLanguage.thai
                                ? 'รอคูลดาวน์อีก $_remainingCooldownSeconds วินาที เพื่อผลลัพธ์ที่ต่างขึ้น'
                                : 'Wait ${_remainingCooldownSeconds}s cooldown for more varied results.'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightAction {
  const _InsightAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListControllerProvider);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(expenseListControllerProvider.notifier).refresh(),
      child: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('เกิดข้อผิดพลาด: $error')),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: const [Center(child: Text('ยังไม่มีประวัติรายการ'))],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemBuilder: (context, index) {
              final expense = items[index];
              return ListTile(
                onTap: () => context.router.push(
                  ExpenseDetailRoute(expenseId: expense.id),
                ),
                leading: Hero(
                  tag: 'receipt-${expense.id}',
                  child: _Thumb(path: expense.receiptImagePath),
                ),
                title: Text(expense.category),
                subtitle: Text(
                  '${expense.type == TransactionType.income ? 'รายรับ' : 'รายจ่าย'} • ${DateFormat.yMMMd('th').format(expense.purchasedAt)}',
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              );
            },
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemCount: items.length,
          );
        },
      ),
    );
  }
}

class _SettingsTab extends ConsumerStatefulWidget {
  const _SettingsTab();

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  final _keyController = TextEditingController();
  bool _obscureKey = true;
  bool _keySaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existing = ref.read(apiKeyControllerProvider).value;
      if (existing != null && existing.isNotEmpty) {
        _keyController.text = existing;
      }
    });
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    await ref
        .read(apiKeyControllerProvider.notifier)
        .saveKey(_keyController.text);
    if (mounted) {
      setState(() => _keySaved = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _keySaved = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeAsync = ref.watch(themeModeControllerProvider);
    final isDark = themeAsync.value == ThemeMode.dark;
    final languageAsync = ref.watch(appLanguageControllerProvider);
    final language = languageAsync.value ?? AppLanguage.thai;
    final strings = AppStrings.of(language);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          SwitchListTile(
            value: isDark,
            title: Text(strings.darkMode),
            subtitle: Text(strings.darkModeSubtitle),
            onChanged: (_) =>
                ref.read(themeModeControllerProvider.notifier).toggle(),
          ),
          const Divider(height: 1),
          ListTile(title: Text(strings.language)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<AppLanguage>(
              segments: const [
                ButtonSegment(value: AppLanguage.thai, label: Text('ไทย')),
                ButtonSegment(
                  value: AppLanguage.english,
                  label: Text('English'),
                ),
              ],
              selected: {language},
              onSelectionChanged: (selection) => ref
                  .read(appLanguageControllerProvider.notifier)
                  .setLanguage(selection.first),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(strings.manageCategories),
            subtitle: Text(strings.manageCategoriesSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.router.push(const ExpenseMetadataRoute()),
          ),
          const Divider(height: 1),
          // ── API Key (BYOK) section ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.apiKeyTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  strings.apiKeySubtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _keyController,
                  obscureText: _obscureKey,
                  decoration: InputDecoration(
                    hintText: strings.apiKeyHint,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: _obscureKey ? 'แสดง Key' : 'ซ่อน Key',
                          icon: Icon(
                            _obscureKey
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscureKey = !_obscureKey),
                        ),
                        IconButton(
                          tooltip: strings.apiKeyTitle,
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _keySaved
                                ? const Icon(
                                    Icons.check_circle,
                                    key: ValueKey('saved'),
                                    color: Colors.lightGreen,
                                  )
                                : const Icon(
                                    Icons.save_outlined,
                                    key: ValueKey('save'),
                                  ),
                          ),
                          onPressed: _saveKey,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_keySaved)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      strings.apiKeySaved,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({
    required this.selected,
    required this.onChanged,
    required this.strings,
  });

  final SummaryPeriod selected;
  final ValueChanged<SummaryPeriod> onChanged;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    const periods = [
      SummaryPeriod.weekly,
      SummaryPeriod.monthly,
      SummaryPeriod.quarterly,
      SummaryPeriod.yearly,
    ];

    String label(SummaryPeriod period) {
      switch (period) {
        case SummaryPeriod.weekly:
          return strings.weekly;
        case SummaryPeriod.monthly:
          return strings.monthly;
        case SummaryPeriod.quarterly:
          return strings.quarterly;
        case SummaryPeriod.yearly:
          return strings.yearly;
      }
    }

    return Wrap(
      spacing: 8,
      children: periods
          .map(
            (entry) => ChoiceChip(
              label: Text(label(entry)),
              selected: selected == entry,
              onSelected: (_) => onChanged(entry),
            ),
          )
          .toList(),
    );
  }
}

class _SmartAutoScanStatusCard extends StatelessWidget {
  const _SmartAutoScanStatusCard({
    required this.title,
    required this.message,
    this.progressLabel,
    this.progressValue,
  });

  final String title;
  final String message;
  final String? progressLabel;
  final double? progressValue;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.7),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Semantics(
                label: 'cat mascot',
                child: Text('🐱', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(message),
                  if ((progressLabel ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      progressLabel!,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progressValue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  const _PieChart({required this.categories});

  final List<CategoryBreakdown> categories;

  static const _palette = <Color>[
    Color(0xFFFFB74D),
    Color(0xFF81C784),
    Color(0xFF64B5F6),
    Color(0xFFBA68C8),
    Color(0xFF4DB6AC),
    Color(0xFFE57373),
  ];

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<double>(
      0,
      (sum, item) => sum + item.totalAmount,
    );

    final summary = categories
        .map(
          (entry) =>
              '${entry.categoryName} ${entry.totalAmount.toStringAsFixed(2)}',
        )
        .join(', ');

    return Row(
      children: [
        Semantics(
          label: 'pie chart $summary',
          child: SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _PieChartPainter(categories: categories, total: total),
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '฿\n${total.toStringAsFixed(0)}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < categories.length && i < _palette.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LegendItem(
                    color: _palette[i],
                    label: categories[i].categoryName,
                    value: categories[i].totalAmount,
                    total: total,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.total,
  });

  final Color color;
  final String label;
  final double value;
  final double total;

  @override
  Widget build(BuildContext context) {
    final percent = total <= 0 ? 0 : (value / total) * 100;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Text('${percent.toStringAsFixed(0)}%'),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  const _PieChartPainter({required this.categories, required this.total});

  final List<CategoryBreakdown> categories;
  final double total;

  static const _palette = <Color>[
    Color(0xFFFFB74D),
    Color(0xFF81C784),
    Color(0xFF64B5F6),
    Color(0xFFBA68C8),
    Color(0xFF4DB6AC),
    Color(0xFFE57373),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = min(size.width, size.height) * 0.28;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (total <= 0) {
      paint.color = Colors.grey.shade300;
      canvas.drawArc(rect.deflate(12), -pi / 2, pi * 2, false, paint);
      return;
    }

    double startAngle = -pi / 2;
    for (var i = 0; i < categories.length && i < _palette.length; i++) {
      final sweepAngle = (categories[i].totalAmount / total) * pi * 2;
      paint.color = _palette[i];
      canvas.drawArc(rect.deflate(12), startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.categories != categories || oldDelegate.total != total;
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.receipt_long),
      );
    }

    final file = File(path!);
    if (!file.existsSync()) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_not_supported),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        file,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        semanticLabel: 'receipt image',
      ),
    );
  }
}
