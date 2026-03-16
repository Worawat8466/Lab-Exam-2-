import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

import '../../../../core/error/failures.dart';

abstract class ThemeRepository {
  Future<Either<Failure, ThemeMode>> getThemeMode();
  Future<Either<Failure, ThemeMode>> toggleThemeMode();
}
