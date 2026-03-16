import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/receipt_barcode_repository.dart';
import '../datasources/receipt_barcode_data_source.dart';

class ReceiptBarcodeRepositoryImpl implements ReceiptBarcodeRepository {
  const ReceiptBarcodeRepositoryImpl(this._dataSource);

  final ReceiptBarcodeDataSource _dataSource;

  @override
  Future<Either<Failure, bool>> hasQrCode(String imagePath) async {
    try {
      final result = await _dataSource.hasQrCode(imagePath);
      return right(result);
    } catch (error) {
      return left(NetworkFailure('Barcode scanning failed: $error'));
    }
  }
}
