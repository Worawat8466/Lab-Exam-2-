import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/receipt_gallery_repository.dart';

class RequestGalleryAccessUseCase implements UseCase<bool, NoParams> {
  const RequestGalleryAccessUseCase(this._repository);

  final ReceiptGalleryRepository _repository;

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return _repository.requestGalleryAccess();
  }
}
