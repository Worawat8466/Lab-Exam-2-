import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

abstract class ReceiptBarcodeRepository {
  Future<Either<Failure, bool>> hasQrCode(String imagePath);
}
