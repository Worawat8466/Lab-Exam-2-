import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_key_interceptor.dart';
import '../../core/network/api_key_service.dart';
import '../../features/ai_categorization/data/datasources/ai_cache_data_source.dart';
import '../../features/ai_categorization/data/datasources/gemini_remote_data_source.dart';
import '../../features/ai_categorization/data/datasources/receipt_ai_cache_data_source.dart';
import '../../features/ai_categorization/data/datasources/receipt_ai_remote_data_source.dart';
import '../../features/ai_categorization/data/repositories/ai_categorization_repository_impl.dart';
import '../../features/ai_categorization/data/repositories/receipt_ai_repository_impl.dart';
import '../../features/ai_categorization/domain/repositories/ai_categorization_repository.dart';
import '../../features/ai_categorization/domain/repositories/receipt_ai_repository.dart';
import '../../features/ai_categorization/domain/usecases/categorize_receipt_text_usecase.dart';
import '../../features/ai_categorization/domain/usecases/parse_receipt_text_usecase.dart';
import '../../features/dashboard/data/datasources/dashboard_local_data_source.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import '../../features/expense/data/datasources/expense_local_data_source.dart';
import '../../features/expense/data/datasources/expense_metadata_local_data_source.dart';
import '../../features/expense/data/models/expense_category_isar_model.dart';
import '../../features/expense/data/models/expense_isar_model.dart';
import '../../features/expense/data/models/expense_tag_isar_model.dart';
import '../../features/expense/data/repositories/expense_metadata_repository_impl.dart';
import '../../features/expense/data/repositories/expense_repository_impl.dart';
import '../../features/expense/domain/repositories/expense_metadata_repository.dart';
import '../../features/expense/domain/repositories/expense_repository.dart';
import '../../features/expense/domain/usecases/create_expense_usecase.dart';
import '../../features/expense/domain/usecases/delete_expense_usecase.dart';
import '../../features/expense/domain/usecases/delete_expense_category_usecase.dart';
import '../../features/expense/domain/usecases/delete_expense_tag_usecase.dart';
import '../../features/expense/domain/usecases/get_all_expenses_usecase.dart';
import '../../features/expense/domain/usecases/get_expense_metadata_usecase.dart';
import '../../features/expense/domain/usecases/get_expense_by_id_usecase.dart';
import '../../features/expense/domain/usecases/save_expense_category_usecase.dart';
import '../../features/expense/domain/usecases/save_expense_tag_usecase.dart';
import '../../features/expense/domain/usecases/update_expense_usecase.dart';
import '../../features/receipt_scan/data/datasources/receipt_gallery_data_source.dart';
import '../../features/receipt_scan/data/datasources/receipt_barcode_data_source.dart';
import '../../features/receipt_scan/data/datasources/receipt_text_recognition_data_source.dart';
import '../../features/receipt_scan/data/repositories/receipt_barcode_repository_impl.dart';
import '../../features/receipt_scan/data/repositories/receipt_gallery_repository_impl.dart';
import '../../features/receipt_scan/data/repositories/receipt_scan_repository_impl.dart';
import '../../features/receipt_scan/data/services/e_slip_scanner_service.dart';
import '../../features/receipt_scan/domain/repositories/receipt_barcode_repository.dart';
import '../../features/receipt_scan/domain/repositories/receipt_gallery_repository.dart';
import '../../features/receipt_scan/domain/repositories/receipt_scan_repository.dart';
import '../../features/receipt_scan/domain/usecases/detect_qr_code_in_image_usecase.dart';
import '../../features/receipt_scan/domain/usecases/get_current_month_receipt_images_usecase.dart';
import '../../features/receipt_scan/domain/usecases/extract_receipt_text_usecase.dart';
import '../../features/receipt_scan/domain/usecases/request_gallery_access_usecase.dart';
import '../../features/settings/data/datasources/language_local_data_source.dart';
import '../../features/settings/data/datasources/theme_local_data_source.dart';
import '../../features/settings/data/repositories/language_repository_impl.dart';
import '../../features/settings/data/repositories/theme_repository_impl.dart';
import '../../features/settings/domain/repositories/language_repository.dart';
import '../../features/settings/domain/repositories/theme_repository.dart';
import '../../features/settings/domain/usecases/get_app_language_usecase.dart';
import '../../features/settings/domain/usecases/get_theme_mode_usecase.dart';
import '../../features/settings/domain/usecases/set_app_language_usecase.dart';
import '../../features/settings/domain/usecases/toggle_theme_mode_usecase.dart';
import '../router/app_router.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  if (sl.isRegistered<AppRouter>()) {
    return;
  }

  final preferences = await SharedPreferences.getInstance();
  await Hive.initFlutter();
  final aiCacheBox = await Hive.openBox<String>('ai_categorization_cache');

  final appDirectory = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([
    ExpenseIsarModelSchema,
    ExpenseCategoryIsarModelSchema,
    ExpenseTagIsarModelSchema,
  ], directory: appDirectory.path);

  final scanModel =
      dotenv.env['GEMINI_SCAN_MODEL'] ??
      dotenv.env['GEMMA_SCAN_MODEL'] ??
      dotenv.env['GEMINI_MODEL'] ??
      'gemini-3-flash';
  final insightModel =
      dotenv.env['GEMINI_INSIGHT_MODEL'] ??
      dotenv.env['GEMINI_CATEGORY_MODEL'] ??
      dotenv.env['GEMINI_MODEL'] ??
      'gemini-3.1-pro';

  // Register secure storage and API key service FIRST so the interceptor
  // can resolve them lazily at request time.
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );
  // Hybrid key: user-stored key in secure storage takes precedence over .env
  dio.interceptors.add(
    ApiKeyInterceptor(() => sl<ApiKeyService>().getEffectiveKey()),
  );
  dio.interceptors.add(
    LogInterceptor(requestBody: true, responseBody: true, requestHeader: true),
  );

  sl
    ..registerSingleton<AppRouter>(AppRouter())
    ..registerSingleton<SharedPreferences>(preferences)
    ..registerSingleton<FlutterSecureStorage>(secureStorage)
    ..registerLazySingleton<ApiKeyService>(() => ApiKeyService(sl()))
    ..registerSingleton<Box<String>>(aiCacheBox)
    ..registerSingleton<Isar>(isar)
    ..registerSingleton<Dio>(dio)
    ..registerLazySingleton<SlipScannerService>(
      () => SlipScannerService(dio: sl(), model: scanModel),
    )
    ..registerLazySingleton<ExpenseLocalDataSource>(
      () => ExpenseLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<ExpenseMetadataLocalDataSource>(
      () => ExpenseMetadataLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<ExpenseRepository>(
      () => ExpenseRepositoryImpl(sl()),
    )
    ..registerLazySingleton<ExpenseMetadataRepository>(
      () => ExpenseMetadataRepositoryImpl(sl()),
    )
    ..registerLazySingleton<CreateExpenseUseCase>(
      () => CreateExpenseUseCase(sl()),
    )
    ..registerLazySingleton<UpdateExpenseUseCase>(
      () => UpdateExpenseUseCase(sl()),
    )
    ..registerLazySingleton<GetExpenseByIdUseCase>(
      () => GetExpenseByIdUseCase(sl()),
    )
    ..registerLazySingleton<GetAllExpensesUseCase>(
      () => GetAllExpensesUseCase(sl()),
    )
    ..registerLazySingleton<DeleteExpenseUseCase>(
      () => DeleteExpenseUseCase(sl()),
    )
    ..registerLazySingleton<GetExpenseMetadataUseCase>(
      () => GetExpenseMetadataUseCase(sl()),
    )
    ..registerLazySingleton<SaveExpenseCategoryUseCase>(
      () => SaveExpenseCategoryUseCase(sl()),
    )
    ..registerLazySingleton<DeleteExpenseCategoryUseCase>(
      () => DeleteExpenseCategoryUseCase(sl()),
    )
    ..registerLazySingleton<SaveExpenseTagUseCase>(
      () => SaveExpenseTagUseCase(sl()),
    )
    ..registerLazySingleton<DeleteExpenseTagUseCase>(
      () => DeleteExpenseTagUseCase(sl()),
    )
    ..registerLazySingleton<DashboardLocalDataSource>(
      () => DashboardLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<DashboardRepository>(
      () => DashboardRepositoryImpl(sl()),
    )
    ..registerLazySingleton<GetDashboardSummaryUseCase>(
      () => GetDashboardSummaryUseCase(sl()),
    )
    ..registerLazySingleton<ReceiptTextRecognitionDataSource>(
      ReceiptTextRecognitionDataSourceImpl.new,
    )
    ..registerLazySingleton<ReceiptBarcodeDataSource>(
      ReceiptBarcodeDataSourceImpl.new,
    )
    ..registerLazySingleton<ReceiptGalleryDataSource>(
      ReceiptGalleryDataSourceImpl.new,
    )
    ..registerLazySingleton<ReceiptBarcodeRepository>(
      () => ReceiptBarcodeRepositoryImpl(sl()),
    )
    ..registerLazySingleton<ReceiptScanRepository>(
      () => ReceiptScanRepositoryImpl(sl()),
    )
    ..registerLazySingleton<ReceiptGalleryRepository>(
      () => ReceiptGalleryRepositoryImpl(sl()),
    )
    ..registerLazySingleton<ExtractReceiptTextUseCase>(
      () => ExtractReceiptTextUseCase(sl()),
    )
    ..registerLazySingleton<DetectQrCodeInImageUseCase>(
      () => DetectQrCodeInImageUseCase(sl()),
    )
    ..registerLazySingleton<RequestGalleryAccessUseCase>(
      () => RequestGalleryAccessUseCase(sl()),
    )
    ..registerLazySingleton<GetCurrentMonthReceiptImagesUseCase>(
      () => GetCurrentMonthReceiptImagesUseCase(sl()),
    )
    ..registerLazySingleton<AiCacheDataSource>(
      () => AiCacheDataSourceImpl(sl()),
    )
    ..registerLazySingleton<GeminiRemoteDataSource>(
      () => GeminiRemoteDataSourceImpl(dio: sl(), model: insightModel),
    )
    ..registerLazySingleton<AiCategorizationRepository>(
      () => AiCategorizationRepositoryImpl(
        remoteDataSource: sl(),
        cacheDataSource: sl(),
      ),
    )
    ..registerLazySingleton<ReceiptAiCacheDataSource>(
      () => ReceiptAiCacheDataSourceImpl(sl()),
    )
    ..registerLazySingleton<ReceiptAiRemoteDataSource>(
      () => ReceiptAiRemoteDataSourceImpl(dio: sl(), model: scanModel),
    )
    ..registerLazySingleton<ReceiptAiRepository>(
      () => ReceiptAiRepositoryImpl(
        remoteDataSource: sl(),
        cacheDataSource: sl(),
      ),
    )
    ..registerLazySingleton<CategorizeReceiptTextUseCase>(
      () => CategorizeReceiptTextUseCase(sl()),
    )
    ..registerLazySingleton<ParseReceiptTextUseCase>(
      () => ParseReceiptTextUseCase(sl()),
    )
    ..registerLazySingleton<ThemeLocalDataSource>(
      () => ThemeLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<LanguageLocalDataSource>(
      () => LanguageLocalDataSourceImpl(sl()),
    )
    ..registerLazySingleton<ThemeRepository>(() => ThemeRepositoryImpl(sl()))
    ..registerLazySingleton<LanguageRepository>(
      () => LanguageRepositoryImpl(sl()),
    )
    ..registerLazySingleton<GetThemeModeUseCase>(
      () => GetThemeModeUseCase(sl()),
    )
    ..registerLazySingleton<ToggleThemeModeUseCase>(
      () => ToggleThemeModeUseCase(sl()),
    )
    ..registerLazySingleton<GetAppLanguageUseCase>(
      () => GetAppLanguageUseCase(sl()),
    )
    ..registerLazySingleton<SetAppLanguageUseCase>(
      () => SetAppLanguageUseCase(sl()),
    );
}
