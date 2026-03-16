import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_language.dart';

abstract class LanguageRepository {
  Future<Either<Failure, AppLanguage>> getLanguage();
  Future<Either<Failure, AppLanguage>> setLanguage(AppLanguage language);
}
