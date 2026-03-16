import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/parsed_receipt_data.dart';

abstract class ReceiptAiRepository {
  Future<Either<Failure, ParsedReceiptData>> parseReceiptText(String rawText);
}
