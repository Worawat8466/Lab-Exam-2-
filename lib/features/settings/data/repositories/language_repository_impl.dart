import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/repositories/language_repository.dart';
import '../datasources/language_local_data_source.dart';

class LanguageRepositoryImpl implements LanguageRepository {
  const LanguageRepositoryImpl(this._localDataSource);

  final LanguageLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, AppLanguage>> getLanguage() async {
    try {
      final language = await _localDataSource.getLanguage();
      return right(language);
    } catch (error) {
      return left(CacheFailure('Load language failed: $error'));
    }
  }

  @override
  Future<Either<Failure, AppLanguage>> setLanguage(AppLanguage language) async {
    try {
      final saved = await _localDataSource.setLanguage(language);
      return right(saved);
    } catch (error) {
      return left(CacheFailure('Set language failed: $error'));
    }
  }
}
