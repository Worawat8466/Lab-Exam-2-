import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../expense/domain/entities/expense_category.dart';
import '../../../expense/domain/entities/expense.dart';
import '../../../expense/domain/usecases/create_expense_usecase.dart';
import '../../../expense/domain/usecases/get_expense_metadata_usecase.dart';
import '../../../expense/domain/usecases/get_all_expenses_usecase.dart';
import '../../../expense/domain/usecases/save_expense_category_usecase.dart';
import '../../../receipt_scan/data/services/e_slip_scanner_service.dart';
import '../../../receipt_scan/domain/entities/gallery_receipt_image.dart';
import '../../../receipt_scan/domain/usecases/detect_qr_code_in_image_usecase.dart';
import '../../../receipt_scan/domain/usecases/get_current_month_receipt_images_usecase.dart';
import '../../../receipt_scan/domain/usecases/request_gallery_access_usecase.dart';

final smartAutoScanControllerProvider =
    AsyncNotifierProvider<SmartAutoScanController, SmartAutoScanState>(
      SmartAutoScanController.new,
    );

enum SmartAutoScanStage {
  idle,
  permissionPrompt,
  scanning,
  reviewPrompt,
  processing,
  completed,
  permissionDenied,
  error,
}

class SmartAutoScanState {
  const SmartAutoScanState({
    this.stage = SmartAutoScanStage.idle,
    this.candidates = const [],
    this.checkedCount = 0,
    this.processedCount = 0,
    this.totalCount = 0,
    this.savedCount = 0,
    this.failedCount = 0,
    this.message,
  });

  final SmartAutoScanStage stage;
  final List<GalleryReceiptImage> candidates;
  final int checkedCount;
  final int processedCount;
  final int totalCount;
  final int savedCount;
  final int failedCount;
  final String? message;

  bool get isBusy =>
      stage == SmartAutoScanStage.scanning ||
      stage == SmartAutoScanStage.processing;

  SmartAutoScanState copyWith({
    SmartAutoScanStage? stage,
    List<GalleryReceiptImage>? candidates,
    int? checkedCount,
    int? processedCount,
    int? totalCount,
    int? savedCount,
    int? failedCount,
    String? message,
    bool clearMessage = false,
  }) {
    return SmartAutoScanState(
      stage: stage ?? this.stage,
      candidates: candidates ?? this.candidates,
      checkedCount: checkedCount ?? this.checkedCount,
      processedCount: processedCount ?? this.processedCount,
      totalCount: totalCount ?? this.totalCount,
      savedCount: savedCount ?? this.savedCount,
      failedCount: failedCount ?? this.failedCount,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class SmartAutoScanController extends AsyncNotifier<SmartAutoScanState> {
  bool _initialized = false;

  @override
  Future<SmartAutoScanState> build() async => const SmartAutoScanState();

  void initialize() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    state = const AsyncData(
      SmartAutoScanState(stage: SmartAutoScanStage.permissionPrompt),
    );
  }

  void dismissPrompt() {
    state = const AsyncData(SmartAutoScanState(stage: SmartAutoScanStage.idle));
  }

  Future<void> requestPermissionAndDiscover() async {
    final current = state.value ?? const SmartAutoScanState();
    state = AsyncData(
      current.copyWith(
        stage: SmartAutoScanStage.scanning,
        clearMessage: true,
        candidates: const [],
        checkedCount: 0,
        processedCount: 0,
        totalCount: 0,
        savedCount: 0,
        failedCount: 0,
      ),
    );

    try {
      final permissionUseCase = sl<RequestGalleryAccessUseCase>();
      final permissionResult = await permissionUseCase(const NoParams());
      final granted = permissionResult.fold((_) => false, (value) => value);

      if (!granted) {
        state = const AsyncData(
          SmartAutoScanState(
            stage: SmartAutoScanStage.permissionDenied,
            message: 'gallery_permission_denied',
          ),
        );
        return;
      }

      final galleryUseCase = sl<GetCurrentMonthReceiptImagesUseCase>();
      final galleryResult = await galleryUseCase(
        GetCurrentMonthReceiptImagesParams(anchorDate: DateTime.now()),
      );
      final allImages = galleryResult.fold(
        (failure) => throw Exception(failure.message),
        (value) => value,
      );

      final allExpensesResult = await sl<GetAllExpensesUseCase>()(
        const NoParams(),
      );
      final existingPaths = allExpensesResult.fold<Set<String>>(
        (_) => <String>{},
        (items) => items
            .map((entry) => entry.receiptImagePath)
            .whereType<String>()
            .where((path) => path.isNotEmpty)
            .toSet(),
      );

      final unsavedImages = allImages
          .where((image) => !existingPaths.contains(image.localPath))
          .toList();

      if (unsavedImages.isEmpty) {
        state = const AsyncData(
          SmartAutoScanState(
            stage: SmartAutoScanStage.completed,
            message: 'no_new_slips',
          ),
        );
        return;
      }

      final qrUseCase = sl<DetectQrCodeInImageUseCase>();
      final candidates = <GalleryReceiptImage>[];
      final total = unsavedImages.length;

      for (var index = 0; index < unsavedImages.length; index++) {
        final image = unsavedImages[index];
        final result = await qrUseCase(
          DetectQrCodeInImageParams(imagePath: image.localPath),
        );
        final hasQr = result.fold((_) => false, (value) => value);
        if (hasQr) {
          candidates.add(image);
        }

        final scanningState = state.value ?? const SmartAutoScanState();
        state = AsyncData(
          scanningState.copyWith(
            stage: SmartAutoScanStage.scanning,
            candidates: List<GalleryReceiptImage>.unmodifiable(candidates),
            checkedCount: index + 1,
            processedCount: index + 1,
            totalCount: total,
          ),
        );
      }

      if (candidates.isEmpty) {
        state = AsyncData(
          SmartAutoScanState(
            stage: SmartAutoScanStage.completed,
            checkedCount: unsavedImages.length,
            processedCount: unsavedImages.length,
            totalCount: unsavedImages.length,
            message: 'no_qr_candidates',
          ),
        );
        return;
      }

      state = AsyncData(
        SmartAutoScanState(
          stage: SmartAutoScanStage.reviewPrompt,
          candidates: candidates,
          checkedCount: unsavedImages.length,
          processedCount: 0,
          totalCount: candidates.length,
        ),
      );
    } catch (error) {
      state = AsyncData(
        SmartAutoScanState(
          stage: SmartAutoScanStage.error,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> processCandidates() async {
    final current = state.value ?? const SmartAutoScanState();
    if (current.candidates.isEmpty) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        stage: SmartAutoScanStage.processing,
        clearMessage: true,
        processedCount: 0,
        totalCount: current.candidates.length,
      ),
    );

    try {
      final createUseCase = sl<CreateExpenseUseCase>();
      final slipScanner = sl<SlipScannerService>();
      final allExpensesResult = await sl<GetAllExpensesUseCase>()(
        const NoParams(),
      );
      final existingPaths = allExpensesResult.fold<Set<String>>(
        (_) => <String>{},
        (items) => items
            .map((entry) => entry.receiptImagePath)
            .whereType<String>()
            .where((path) => path.isNotEmpty)
            .toSet(),
      );

      var saved = 0;
      var failed = 0;

      for (var index = 0; index < current.candidates.length; index++) {
        final image = current.candidates[index];
        if (existingPaths.contains(image.localPath)) {
          final processingState = state.value ?? const SmartAutoScanState();
          state = AsyncData(
            processingState.copyWith(
              stage: SmartAutoScanStage.processing,
              processedCount: index + 1,
              totalCount: current.candidates.length,
            ),
          );
          continue;
        }

        try {
          final slip = await slipScanner.scanFromImage(image.localPath);
          if (!slip.isValidSlip || slip.amount <= 0) {
            failed += 1;
            continue;
          }

          final resolvedCategory = slip.category.trim().isEmpty
              ? 'โอนเงิน'
              : slip.category.trim();

          if (resolvedCategory.isNotEmpty) {
            final metadataUseCase = sl<GetExpenseMetadataUseCase>();
            final metadataResult = await metadataUseCase(const NoParams());
            final metadata = metadataResult.fold(
              (failure) => throw Exception(failure.message),
              (value) => value,
            );
            final exists = metadata.categories.any(
              (entry) => entry.name == resolvedCategory,
            );
            if (!exists) {
              final now = DateTime.now();
              final saveCategoryUseCase = sl<SaveExpenseCategoryUseCase>();
              final saveResult = await saveCategoryUseCase(
                SaveExpenseCategoryParams(
                  category: ExpenseCategory(
                    id: 0,
                    name: resolvedCategory,
                    createdAt: now,
                    updatedAt: now,
                  ),
                ),
              );
              saveResult.fold(
                (failure) => throw Exception(failure.message),
                (_) {},
              );
            }
          }

          final now = DateTime.now();
          final expense = Expense(
            id: 0,
            type: TransactionType.expense,
            merchant: '',
            category: resolvedCategory,
            amount: slip.amount,
            currency: 'THB',
            note:
                'ชื่อผู้รับเงินที่สแกนได้: ${slip.receiverName}\nSmart Auto-Scan e-Slip',
            tags: [resolvedCategory],
            isRecurring: false,
            recurringFrequency: null,
            nextOccurrence: null,
            receiptImagePath: image.localPath,
            receiptRawText: slip.cleanedText.isEmpty
                ? slip.rawText
                : slip.cleanedText,
            purchasedAt: image.createdAt,
            createdAt: now,
            updatedAt: now,
          );

          final createdResult = await createUseCase(
            CreateExpenseParams(expense: expense),
          );
          createdResult.fold(
            (failure) => throw Exception(failure.message),
            (_) => saved += 1,
          );
          existingPaths.add(image.localPath);
        } catch (_) {
          failed += 1;
        }

        final processingState = state.value ?? const SmartAutoScanState();
        state = AsyncData(
          processingState.copyWith(
            stage: SmartAutoScanStage.processing,
            processedCount: index + 1,
            totalCount: current.candidates.length,
            savedCount: saved,
            failedCount: failed,
          ),
        );
      }

      state = AsyncData(
        SmartAutoScanState(
          stage: SmartAutoScanStage.completed,
          savedCount: saved,
          failedCount: failed,
          checkedCount: current.candidates.length,
          processedCount: current.candidates.length,
          totalCount: current.candidates.length,
          message: 'processing_complete',
        ),
      );
    } catch (error) {
      state = AsyncData(
        SmartAutoScanState(
          stage: SmartAutoScanStage.error,
          message: error.toString(),
        ),
      );
    }
  }

  void clearCompletion() {
    state = const AsyncData(SmartAutoScanState(stage: SmartAutoScanStage.idle));
  }
}
