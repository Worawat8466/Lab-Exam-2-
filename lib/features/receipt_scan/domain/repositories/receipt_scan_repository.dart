import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/receipt_scan_result.dart';

abstract class ReceiptScanRepository {
  Future<Either<Failure, ReceiptScanResult>> extractTextFromImage(
    String imagePath,
  );
}
