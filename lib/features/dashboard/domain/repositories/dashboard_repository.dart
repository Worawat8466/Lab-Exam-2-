import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/dashboard_summary.dart';
import '../entities/summary_period.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardSummary>> getDashboardSummary({
    required SummaryPeriod period,
    required DateTime anchorDate,
  });
}
