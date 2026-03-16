import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:labexam2/app/di/service_locator.dart';
import 'package:labexam2/app/router/app_router.dart';
import 'package:labexam2/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App smoke flow: home -> form -> scan', (tester) async {
    await app.main();
    await _pumpFor(tester, const Duration(seconds: 3));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsAtLeastNWidgets(1));
    expect(find.byType(Card), findsWidgets);

    await sl<AppRouter>().push(ExpenseFormRoute());
    await _pumpFor(tester, const Duration(seconds: 1));

    expect(find.byType(TextFormField), findsWidgets);

    await sl<AppRouter>().push(const AutoScanAiReviewRoute());
    await _pumpFor(tester, const Duration(seconds: 1));

    expect(find.byIcon(Icons.photo_library), findsOneWidget);
  });
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final steps = duration.inMilliseconds ~/ 100;
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
