import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/gallery_receipt_image.dart';

abstract class ReceiptGalleryRepository {
  Future<Either<Failure, bool>> requestGalleryAccess();

  Future<Either<Failure, List<GalleryReceiptImage>>>
  getCurrentMonthReceiptImages({required DateTime anchorDate});
}
