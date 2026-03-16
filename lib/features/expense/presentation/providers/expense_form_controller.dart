import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/create_expense_usecase.dart';
import '../../domain/usecases/get_expense_by_id_usecase.dart';
import '../../domain/usecases/update_expense_usecase.dart';
import '../../../ai_categorization/domain/entities/parsed_receipt_data.dart';
import '../../../ai_categorization/domain/usecases/categorize_receipt_text_usecase.dart';
import '../../../ai_categorization/domain/usecases/parse_receipt_text_usecase.dart';
import '../../../receipt_scan/data/services/e_slip_scanner_service.dart';
import '../../../receipt_scan/domain/entities/gallery_receipt_image.dart';
import '../../../receipt_scan/domain/entities/receipt_scan_result.dart';
import '../../../receipt_scan/domain/usecases/get_current_month_receipt_images_usecase.dart';
import '../../../receipt_scan/domain/usecases/request_gallery_access_usecase.dart';

final expenseFormControllerProvider =
    AutoDisposeAsyncNotifierProvider<ExpenseFormController, ExpenseFormState>(
      ExpenseFormController.new,
    );

class ExpenseFormState {
  const ExpenseFormState({
    this.expense,
    this.imagePath,
    this.galleryImages = const [],
    this.scannedText = '',
    this.aiCategory,
    this.aiReason,
    this.aiConfidence,
    this.parsedReceipt,
    this.parsedImagePath,
  });

  final Expense? expense;
  final String? imagePath;
  final List<GalleryReceiptImage> galleryImages;
  final String scannedText;
  final String? aiCategory;
  final String? aiReason;
  final double? aiConfidence;
  final ParsedReceiptData? parsedReceipt;
  final String? parsedImagePath;

  ExpenseFormState copyWith({
    Expense? expense,
    String? imagePath,
    List<GalleryReceiptImage>? galleryImages,
    String? scannedText,
    String? aiCategory,
    String? aiReason,
    double? aiConfidence,
    ParsedReceiptData? parsedReceipt,
    String? parsedImagePath,
  }) {
    return ExpenseFormState(
      expense: expense ?? this.expense,
      imagePath: imagePath ?? this.imagePath,
      galleryImages: galleryImages ?? this.galleryImages,
      scannedText: scannedText ?? this.scannedText,
      aiCategory: aiCategory ?? this.aiCategory,
      aiReason: aiReason ?? this.aiReason,
      aiConfidence: aiConfidence ?? this.aiConfidence,
      parsedReceipt: parsedReceipt ?? this.parsedReceipt,
      parsedImagePath: parsedImagePath ?? this.parsedImagePath,
    );
  }
}

class ExpenseFormController extends AutoDisposeAsyncNotifier<ExpenseFormState> {
  @override
  Future<ExpenseFormState> build() async => const ExpenseFormState();

  Future<void> load(int id) async {
    final useCase = sl<GetExpenseByIdUseCase>();
    final result = await useCase(GetExpenseByIdParams(id));
    result.fold((failure) => throw Exception(failure.message), (expense) {
      state = AsyncData(
        ExpenseFormState(
          expense: expense,
          imagePath: expense.receiptImagePath,
          scannedText: expense.receiptRawText,
          aiCategory: expense.category,
        ),
      );
    });
  }

  Future<String?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    final filePath = result?.files.single.path;
    if (filePath == null || filePath.isEmpty) {
      return null;
    }

    final current = state.value ?? const ExpenseFormState();
    state = AsyncData(current.copyWith(imagePath: filePath));
    return filePath;
  }

  Future<List<GalleryReceiptImage>> loadCurrentMonthGalleryImages() async {
    final current = state.value ?? const ExpenseFormState();

    final permissionUseCase = sl<RequestGalleryAccessUseCase>();
    final permissionResult = await permissionUseCase(const NoParams());
    final granted = permissionResult.fold(
      (failure) => throw Exception(failure.message),
      (value) => value,
    );

    if (!granted) {
      throw Exception('ไม่ได้รับสิทธิ์เข้าถึงคลังรูปภาพ');
    }

    final useCase = sl<GetCurrentMonthReceiptImagesUseCase>();
    final result = await useCase(
      GetCurrentMonthReceiptImagesParams(anchorDate: DateTime.now()),
    );

    final images = result.fold(
      (failure) => throw Exception(failure.message),
      (value) => value,
    );
    state = AsyncData(current.copyWith(galleryImages: images));
    return images;
  }

  Future<void> selectGalleryImage(String imagePath) async {
    final current = state.value ?? const ExpenseFormState();
    state = AsyncData(current.copyWith(imagePath: imagePath));
  }

  Future<ReceiptScanResult?> scanReceiptText() async {
    final current = state.value ?? const ExpenseFormState();
    final imagePath = current.imagePath;
    if (imagePath == null || imagePath.isEmpty) {
      throw Exception('กรุณาเลือกรูปสลิปก่อน');
    }

    try {
      final slip = await sl<SlipScannerService>().scanFromImage(imagePath);
      if (!slip.isValidSlip) {
        throw Exception('ไม่พบ QR Code บนสลิป หรือสลิปไม่ถูกต้อง');
      }

      final structuredText = const JsonEncoder.withIndent('  ').convert({
        'amount': slip.amount,
        'receiver_name': slip.receiverName,
        'category': slip.category,
      });

      state = AsyncData(
        current.copyWith(
          scannedText: structuredText,
          aiCategory: slip.category,
          aiReason: 'QR + Gemini Vision',
          aiConfidence: 0.96,
          parsedImagePath: imagePath,
        ),
      );

      return ReceiptScanResult(
        rawText: structuredText,
        imagePath: imagePath,
        scannedAt: DateTime.now(),
      );
    } catch (error) {
      throw Exception('ดึงข้อความจากรูปไม่สำเร็จ: $error');
    }
  }

  Future<void> setScannedText(String text) async {
    final current = state.value ?? const ExpenseFormState();
    state = AsyncData(current.copyWith(scannedText: text));
  }

  Future<void> categorizeWithAi() async {
    final current = state.value ?? const ExpenseFormState();
    if (current.scannedText.trim().isEmpty) {
      throw Exception('No text available for AI categorization');
    }

    final useCase = sl<CategorizeReceiptTextUseCase>();
    final result = await useCase(
      CategorizeReceiptTextParams(rawText: current.scannedText),
    );

    result.fold((failure) => throw Exception(failure.message), (aiResult) {
      state = AsyncData(
        current.copyWith(
          aiCategory: aiResult.category,
          aiReason: aiResult.reason,
          aiConfidence: aiResult.confidence,
        ),
      );
    });
  }

  Future<ParsedReceiptData?> parseReceiptWithAi() async {
    final current = state.value ?? const ExpenseFormState();
    final imagePath = current.imagePath;

    if (current.parsedReceipt != null &&
        imagePath != null &&
        current.parsedImagePath == imagePath) {
      return current.parsedReceipt;
    }

    final fromStructured = _parseStructuredScanText(current.scannedText);
    if (fromStructured != null) {
      state = AsyncData(
        current.copyWith(
          parsedReceipt: fromStructured,
          aiCategory: fromStructured.suggestedCategory,
          aiReason: 'ใช้ผลสแกนล่าสุด (ไม่เรียก AI ซ้ำ)',
          aiConfidence: 0.96,
          parsedImagePath: imagePath,
        ),
      );
      return fromStructured;
    }

    if (imagePath != null && imagePath.isNotEmpty) {
      final slip = await sl<SlipScannerService>().scanFromImage(imagePath);
      if (!slip.isValidSlip) {
        throw Exception(
          'AI ไม่สามารถยืนยันได้ว่าเป็นสลิปโอนเงิน กรุณาตรวจสอบและกรอกเอง',
        );
      }

      final resolvedCategory = slip.category.trim().isEmpty
          ? 'โอนเงิน'
          : slip.category.trim();
      final cleanedText = slip.cleanedText.trim().isEmpty
          ? slip.rawText
          : slip.cleanedText;
      final parsed = ParsedReceiptData(
        transactionType: TransactionType.expense,
        merchant: slip.receiverName,
        suggestedCategory: resolvedCategory,
        amount: slip.amount,
        currency: 'THB',
        suggestedTags: [resolvedCategory],
        occurredAt: null,
        reasoning:
            'ตรวจสอบ QR ด้วย ML Kit Barcode แล้วใช้ Gemini Vision อ่านสลิปโดยตรง',
        confidence: 0.96,
      );

      state = AsyncData(
        current.copyWith(
          scannedText: cleanedText,
          parsedReceipt: parsed,
          aiCategory: parsed.suggestedCategory,
          aiReason: parsed.reasoning,
          aiConfidence: parsed.confidence,
          parsedImagePath: imagePath,
        ),
      );
      return parsed;
    }

    if (current.scannedText.trim().isEmpty) {
      throw Exception('ไม่มีข้อความจาก OCR ให้ AI วิเคราะห์');
    }

    final useCase = sl<ParseReceiptTextUseCase>();
    final result = await useCase(
      ParseReceiptTextParams(rawText: current.scannedText),
    );

    return result.fold((failure) => throw Exception(failure.message), (data) {
      state = AsyncData(
        current.copyWith(
          parsedReceipt: data,
          aiCategory: data.suggestedCategory,
          aiReason: data.reasoning,
          aiConfidence: data.confidence,
          parsedImagePath: imagePath,
        ),
      );
      return data;
    });
  }

  ParsedReceiptData? _parseStructuredScanText(String raw) {
    final text = raw.trim();
    if (!text.startsWith('{') || !text.endsWith('}')) {
      return null;
    }

    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      final amount = (json['amount'] as num?)?.toDouble() ?? 0;
      if (amount <= 0) {
        return null;
      }

      final category = (json['category'] as String?)?.trim();
      final receiver = (json['receiver_name'] as String?)?.trim() ?? '';
      final resolvedCategory = (category == null || category.isEmpty)
          ? 'โอนเงิน'
          : category;

      return ParsedReceiptData(
        transactionType: TransactionType.expense,
        merchant: receiver,
        suggestedCategory: resolvedCategory,
        amount: amount,
        currency: 'THB',
        suggestedTags: [resolvedCategory],
        occurredAt: null,
        reasoning: 'ใช้ข้อมูลที่สแกนไว้แล้ว',
        confidence: 0.96,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Expense> submit({
    required int? existingId,
    required TransactionType type,
    required String merchant,
    required String category,
    required double amount,
    required String currency,
    required String note,
    required List<String> tags,
    required bool isRecurring,
    required RecurringFrequency? recurringFrequency,
    required DateTime? nextOccurrence,
    required DateTime purchasedAt,
  }) async {
    final current = state.value ?? const ExpenseFormState();
    final now = DateTime.now();

    final expense = Expense(
      id: existingId ?? 0,
      type: type,
      merchant: merchant,
      category: category,
      amount: amount,
      currency: currency,
      note: note,
      tags: tags,
      isRecurring: isRecurring,
      recurringFrequency: recurringFrequency,
      nextOccurrence: nextOccurrence,
      receiptImagePath: current.imagePath,
      receiptRawText: current.scannedText,
      purchasedAt: purchasedAt,
      createdAt: existingId == null ? now : (current.expense?.createdAt ?? now),
      updatedAt: now,
    );

    if (existingId == null) {
      final createUseCase = sl<CreateExpenseUseCase>();
      final result = await createUseCase(CreateExpenseParams(expense: expense));
      return result.fold(
        (failure) => throw Exception(failure.message),
        (created) => created,
      );
    }

    final updateUseCase = sl<UpdateExpenseUseCase>();
    final result = await updateUseCase(UpdateExpenseParams(expense: expense));
    return result.fold(
      (failure) => throw Exception(failure.message),
      (updated) => updated,
    );
  }
}
