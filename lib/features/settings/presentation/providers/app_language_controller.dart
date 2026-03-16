import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/usecases/get_app_language_usecase.dart';
import '../../domain/usecases/set_app_language_usecase.dart';

final appLanguageControllerProvider =
    AsyncNotifierProvider<AppLanguageController, AppLanguage>(
      AppLanguageController.new,
    );

class AppLanguageController extends AsyncNotifier<AppLanguage> {
  @override
  Future<AppLanguage> build() async {
    final useCase = sl<GetAppLanguageUseCase>();
    final result = await useCase(const NoParams());
    return result.fold((_) => AppLanguage.thai, (language) => language);
  }

  Future<void> setLanguage(AppLanguage language) async {
    final useCase = sl<SetAppLanguageUseCase>();
    final result = await useCase(SetAppLanguageParams(language: language));
    result.fold(
      (failure) => throw Exception(failure.message),
      (saved) => state = AsyncData(saved),
    );
  }
}
