import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

import '../../features/home/presentation/pages/home_shell_page.dart';
import '../../features/expense/presentation/pages/expense_detail_page.dart';
import '../../features/expense/presentation/pages/expense_form_page.dart';
import '../../features/expense/presentation/pages/expense_list_page.dart';
import '../../features/expense/presentation/pages/expense_metadata_page.dart';
import '../../features/receipt_scan/presentation/pages/auto_scan_ai_review_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends _$AppRouter {
  AppRouter({super.navigatorKey});

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeShellRoute.page, initial: true),
    AutoRoute(page: ExpenseFormRoute.page),
    AutoRoute(page: ExpenseDetailRoute.page),
    AutoRoute(page: AutoScanAiReviewRoute.page),
    AutoRoute(page: ExpenseListRoute.page),
    AutoRoute(page: ExpenseMetadataRoute.page),
    AutoRoute(page: SettingsRoute.page),
  ];
}
