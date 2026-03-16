import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/receipt_scan_result.dart';
import '../repositories/receipt_scan_repository.dart';

class ExtractReceiptTextUseCase
    implements UseCase<ReceiptScanResult, ExtractReceiptTextParams> {
  const ExtractReceiptTextUseCase(this._repository);

  final ReceiptScanRepository _repository;

  @override
  Future<Either<Failure, ReceiptScanResult>> call(
    ExtractReceiptTextParams params,
  ) {
    return _repository.extractTextFromImage(params.imagePath);
  }
}

class ExtractReceiptTextParams {
  const ExtractReceiptTextParams({required this.imagePath});

  final String imagePath;
}
