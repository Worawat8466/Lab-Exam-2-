import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/ai_category_result.dart';
import '../repositories/ai_categorization_repository.dart';

class CategorizeReceiptTextUseCase
    implements UseCase<AiCategoryResult, CategorizeReceiptTextParams> {
  const CategorizeReceiptTextUseCase(this._repository);

  final AiCategorizationRepository _repository;

  @override
  Future<Either<Failure, AiCategoryResult>> call(
    CategorizeReceiptTextParams params,
  ) {
    return _repository.categorizeReceiptText(params.rawText);
  }
}

class CategorizeReceiptTextParams {
  const CategorizeReceiptTextParams({required this.rawText});

  final String rawText;
}
