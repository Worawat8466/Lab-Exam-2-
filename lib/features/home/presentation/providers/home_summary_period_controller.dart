import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/di/service_locator.dart';
import '../../../dashboard/domain/entities/summary_period.dart';

final homeSummaryPeriodControllerProvider =
    AsyncNotifierProvider<HomeSummaryPeriodController, SummaryPeriod>(
      HomeSummaryPeriodController.new,
    );

class HomeSummaryPeriodController extends AsyncNotifier<SummaryPeriod> {
  static const _periodKey = 'home_summary_period';

  @override
  Future<SummaryPeriod> build() async {
    final preferences = sl<SharedPreferences>();
    final raw = preferences.getString(_periodKey);
    return _fromStorage(raw) ?? SummaryPeriod.monthly;
  }

  void setPeriod(SummaryPeriod period) {
    final preferences = sl<SharedPreferences>();
    state = AsyncData(period);
    unawaited(preferences.setString(_periodKey, period.name));
  }

  SummaryPeriod? _fromStorage(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    for (final period in SummaryPeriod.values) {
      if (period.name == value) {
        return period;
      }
    }
    return null;
  }
}
