import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/receipt_scan_result.dart';
import '../../domain/repositories/receipt_scan_repository.dart';
import '../datasources/receipt_text_recognition_data_source.dart';

class ReceiptScanRepositoryImpl implements ReceiptScanRepository {
  const ReceiptScanRepositoryImpl(this._dataSource);

  final ReceiptTextRecognitionDataSource _dataSource;

  @override
  Future<Either<Failure, ReceiptScanResult>> extractTextFromImage(
    String imagePath,
  ) async {
    try {
      final text = await _dataSource.extractText(imagePath);
      return right(
        ReceiptScanResult(
          rawText: text,
          imagePath: imagePath,
          scannedAt: DateTime.now(),
        ),
      );
    } catch (error) {
      return left(NetworkFailure('Text recognition failed: $error'));
    }
  }
}
