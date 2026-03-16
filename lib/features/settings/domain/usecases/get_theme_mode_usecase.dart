import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/theme_repository.dart';

class GetThemeModeUseCase implements UseCase<ThemeMode, NoParams> {
  const GetThemeModeUseCase(this._repository);

  final ThemeRepository _repository;

  @override
  Future<Either<Failure, ThemeMode>> call(NoParams params) {
    return _repository.getThemeMode();
  }
}
