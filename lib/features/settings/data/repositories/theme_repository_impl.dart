import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/theme_repository.dart';
import '../datasources/theme_local_data_source.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  const ThemeRepositoryImpl(this._localDataSource);

  final ThemeLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, ThemeMode>> getThemeMode() async {
    try {
      final mode = await _localDataSource.getThemeMode();
      return right(mode);
    } catch (error) {
      return left(CacheFailure('Load theme mode failed: $error'));
    }
  }

  @override
  Future<Either<Failure, ThemeMode>> toggleThemeMode() async {
    try {
      final mode = await _localDataSource.toggleThemeMode();
      return right(mode);
    } catch (error) {
      return left(CacheFailure('Toggle theme mode failed: $error'));
    }
  }
}
