import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/gallery_receipt_image.dart';
import '../repositories/receipt_gallery_repository.dart';

class GetCurrentMonthReceiptImagesUseCase
    implements
        UseCase<List<GalleryReceiptImage>, GetCurrentMonthReceiptImagesParams> {
  const GetCurrentMonthReceiptImagesUseCase(this._repository);

  final ReceiptGalleryRepository _repository;

  @override
  Future<Either<Failure, List<GalleryReceiptImage>>> call(
    GetCurrentMonthReceiptImagesParams params,
  ) {
    return _repository.getCurrentMonthReceiptImages(
      anchorDate: params.anchorDate,
    );
  }
}

class GetCurrentMonthReceiptImagesParams {
  const GetCurrentMonthReceiptImagesParams({required this.anchorDate});

  final DateTime anchorDate;
}
