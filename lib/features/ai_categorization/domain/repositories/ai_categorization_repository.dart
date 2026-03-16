import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/ai_category_result.dart';

abstract class AiCategorizationRepository {
  Future<Either<Failure, AiCategoryResult>> categorizeReceiptText(
    String rawText,
  );
}
