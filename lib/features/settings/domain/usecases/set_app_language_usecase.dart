import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_language.dart';
import '../repositories/language_repository.dart';

class SetAppLanguageUseCase
    implements UseCase<AppLanguage, SetAppLanguageParams> {
  const SetAppLanguageUseCase(this._repository);

  final LanguageRepository _repository;

  @override
  Future<Either<Failure, AppLanguage>> call(SetAppLanguageParams params) {
    return _repository.setLanguage(params.language);
  }
}

class SetAppLanguageParams {
  const SetAppLanguageParams({required this.language});

  final AppLanguage language;
}
