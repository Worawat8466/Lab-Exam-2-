import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/service_locator.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/summary_period.dart';
import '../../domain/usecases/get_dashboard_summary_usecase.dart';

final dashboardSummaryControllerProvider =
    AutoDisposeAsyncNotifierProviderFamily<
      DashboardSummaryController,
      DashboardSummary,
      SummaryPeriod
    >(DashboardSummaryController.new);

class DashboardSummaryController
    extends AutoDisposeFamilyAsyncNotifier<DashboardSummary, SummaryPeriod> {
  @override
  Future<DashboardSummary> build(SummaryPeriod arg) async {
    final useCase = sl<GetDashboardSummaryUseCase>();
    final result = await useCase(
      GetDashboardSummaryParams(period: arg, anchorDate: DateTime.now()),
    );

    return result.fold((failure) => throw Exception(failure.message), (data) {
      return data;
    });
  }
}
