import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/gallery_receipt_image.dart';
import '../../domain/repositories/receipt_gallery_repository.dart';
import '../datasources/receipt_gallery_data_source.dart';

class ReceiptGalleryRepositoryImpl implements ReceiptGalleryRepository {
  const ReceiptGalleryRepositoryImpl(this._dataSource);

  final ReceiptGalleryDataSource _dataSource;

  @override
  Future<Either<Failure, List<GalleryReceiptImage>>>
  getCurrentMonthReceiptImages({required DateTime anchorDate}) async {
    try {
      final images = await _dataSource.getCurrentMonthReceiptImages(
        anchorDate: anchorDate,
      );
      return right(images);
    } catch (error) {
      return left(CacheFailure('Load gallery receipt images failed: $error'));
    }
  }

  @override
  Future<Either<Failure, bool>> requestGalleryAccess() async {
    try {
      final granted = await _dataSource.requestGalleryAccess();
      return right(granted);
    } catch (error) {
      return left(CacheFailure('Request gallery permission failed: $error'));
    }
  }
}
