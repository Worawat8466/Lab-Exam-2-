import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/receipt_barcode_repository.dart';

class DetectQrCodeInImageUseCase
    implements UseCase<bool, DetectQrCodeInImageParams> {
  const DetectQrCodeInImageUseCase(this._repository);

  final ReceiptBarcodeRepository _repository;

  @override
  Future<Either<Failure, bool>> call(DetectQrCodeInImageParams params) {
    return _repository.hasQrCode(params.imagePath);
  }
}

class DetectQrCodeInImageParams {
  const DetectQrCodeInImageParams({required this.imagePath});

  final String imagePath;
}
