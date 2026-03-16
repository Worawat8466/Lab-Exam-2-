import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_theme_mode_usecase.dart';
import '../../domain/usecases/toggle_theme_mode_usecase.dart';

final themeModeControllerProvider =
    AsyncNotifierProvider<ThemeModeController, ThemeMode>(
      ThemeModeController.new,
    );

class ThemeModeController extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final useCase = sl<GetThemeModeUseCase>();
    final result = await useCase(const NoParams());
    return result.fold((_) => ThemeMode.light, (mode) => mode);
  }

  Future<void> toggle() async {
    final useCase = sl<ToggleThemeModeUseCase>();
    final result = await useCase(const NoParams());
    result.fold(
      (failure) => throw Exception(failure.message),
      (mode) => state = AsyncData(mode),
    );
  }
}
