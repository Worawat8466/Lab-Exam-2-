import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/dashboard_summary.dart';
import '../entities/summary_period.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardSummaryUseCase
    implements UseCase<DashboardSummary, GetDashboardSummaryParams> {
  const GetDashboardSummaryUseCase(this._repository);

  final DashboardRepository _repository;

  @override
  Future<Either<Failure, DashboardSummary>> call(
    GetDashboardSummaryParams params,
  ) {
    return _repository.getDashboardSummary(
      period: params.period,
      anchorDate: params.anchorDate,
    );
  }
}

class GetDashboardSummaryParams {
  const GetDashboardSummaryParams({
    required this.period,
    required this.anchorDate,
  });

  final SummaryPeriod period;
  final DateTime anchorDate;
}
