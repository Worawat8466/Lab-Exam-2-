// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

abstract class _$AppRouter extends RootStackRouter {
  // ignore: unused_element
  _$AppRouter({super.navigatorKey});

  @override
  final Map<String, PageFactory> pagesMap = {
    AutoScanAiReviewRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const AutoScanAiReviewPage(),
      );
    },
    ExpenseDetailRoute.name: (routeData) {
      final args = routeData.argsAs<ExpenseDetailRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: ExpenseDetailPage(
          key: args.key,
          expenseId: args.expenseId,
        ),
      );
    },
    ExpenseFormRoute.name: (routeData) {
      final args = routeData.argsAs<ExpenseFormRouteArgs>(
          orElse: () => const ExpenseFormRouteArgs());
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: ExpenseFormPage(
          key: args.key,
          expenseId: args.expenseId,
        ),
      );
    },
    ExpenseListRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const ExpenseListPage(),
      );
    },
    ExpenseMetadataRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const ExpenseMetadataPage(),
      );
    },
    HomeShellRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const HomeShellPage(),
      );
    },
    SettingsRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SettingsPage(),
      );
    },
  };
}

/// generated route for
/// [AutoScanAiReviewPage]
class AutoScanAiReviewRoute extends PageRouteInfo<void> {
  const AutoScanAiReviewRoute({List<PageRouteInfo>? children})
      : super(
          AutoScanAiReviewRoute.name,
          initialChildren: children,
        );

  static const String name = 'AutoScanAiReviewRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [ExpenseDetailPage]
class ExpenseDetailRoute extends PageRouteInfo<ExpenseDetailRouteArgs> {
  ExpenseDetailRoute({
    Key? key,
    required int expenseId,
    List<PageRouteInfo>? children,
  }) : super(
          ExpenseDetailRoute.name,
          args: ExpenseDetailRouteArgs(
            key: key,
            expenseId: expenseId,
          ),
          initialChildren: children,
        );

  static const String name = 'ExpenseDetailRoute';

  static const PageInfo<ExpenseDetailRouteArgs> page =
      PageInfo<ExpenseDetailRouteArgs>(name);
}

class ExpenseDetailRouteArgs {
  const ExpenseDetailRouteArgs({
    this.key,
    required this.expenseId,
  });

  final Key? key;

  final int expenseId;

  @override
  String toString() {
    return 'ExpenseDetailRouteArgs{key: $key, expenseId: $expenseId}';
  }
}

/// generated route for
/// [ExpenseFormPage]
class ExpenseFormRoute extends PageRouteInfo<ExpenseFormRouteArgs> {
  ExpenseFormRoute({
    Key? key,
    int? expenseId,
    List<PageRouteInfo>? children,
  }) : super(
          ExpenseFormRoute.name,
          args: ExpenseFormRouteArgs(
            key: key,
            expenseId: expenseId,
          ),
          initialChildren: children,
        );

  static const String name = 'ExpenseFormRoute';

  static const PageInfo<ExpenseFormRouteArgs> page =
      PageInfo<ExpenseFormRouteArgs>(name);
}

class ExpenseFormRouteArgs {
  const ExpenseFormRouteArgs({
    this.key,
    this.expenseId,
  });

  final Key? key;

  final int? expenseId;

  @override
  String toString() {
    return 'ExpenseFormRouteArgs{key: $key, expenseId: $expenseId}';
  }
}

/// generated route for
/// [ExpenseListPage]
class ExpenseListRoute extends PageRouteInfo<void> {
  const ExpenseListRoute({List<PageRouteInfo>? children})
      : super(
          ExpenseListRoute.name,
          initialChildren: children,
        );

  static const String name = 'ExpenseListRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [ExpenseMetadataPage]
class ExpenseMetadataRoute extends PageRouteInfo<void> {
  const ExpenseMetadataRoute({List<PageRouteInfo>? children})
      : super(
          ExpenseMetadataRoute.name,
          initialChildren: children,
        );

  static const String name = 'ExpenseMetadataRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [HomeShellPage]
class HomeShellRoute extends PageRouteInfo<void> {
  const HomeShellRoute({List<PageRouteInfo>? children})
      : super(
          HomeShellRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeShellRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [SettingsPage]
class SettingsRoute extends PageRouteInfo<void> {
  const SettingsRoute({List<PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}
