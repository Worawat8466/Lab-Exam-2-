import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/parsed_receipt_data.dart';
import '../repositories/receipt_ai_repository.dart';

class ParseReceiptTextUseCase
    implements UseCase<ParsedReceiptData, ParseReceiptTextParams> {
  const ParseReceiptTextUseCase(this._repository);

  final ReceiptAiRepository _repository;

  @override
  Future<Either<Failure, ParsedReceiptData>> call(
    ParseReceiptTextParams params,
  ) {
    return _repository.parseReceiptText(params.rawText);
  }
}

class ParseReceiptTextParams {
  const ParseReceiptTextParams({required this.rawText});

  final String rawText;
}
