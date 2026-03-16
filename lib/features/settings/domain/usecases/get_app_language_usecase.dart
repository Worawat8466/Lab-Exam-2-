import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_language.dart';
import '../repositories/language_repository.dart';

class GetAppLanguageUseCase implements UseCase<AppLanguage, NoParams> {
  const GetAppLanguageUseCase(this._repository);

  final LanguageRepository _repository;

  @override
  Future<Either<Failure, AppLanguage>> call(NoParams params) {
    return _repository.getLanguage();
  }
}
