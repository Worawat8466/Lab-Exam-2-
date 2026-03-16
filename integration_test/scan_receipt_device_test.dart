import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:labexam2/app/di/service_locator.dart';
import 'package:labexam2/app/router/app_router.dart';
import 'package:labexam2/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('เปิดหน้า Scan และกดโหลดแกลเลอรีไม่พัง', (tester) async {
    _logStep('STEP 1: Launch app');
    await app.main();
    await _pumpFor(tester, const Duration(seconds: 3));

    _logStep('STEP 2: Navigate directly to scan page');
    await sl<AppRouter>().push(const AutoScanAiReviewRoute());
    await _pumpFor(tester, const Duration(seconds: 1));

    expect(find.byType(Scaffold), findsWidgets);
    expect(find.byIcon(Icons.photo_library), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

    final loadGalleryButton = find.byIcon(Icons.photo_library);
    expect(loadGalleryButton, findsOneWidget);

    await tester.tap(loadGalleryButton);
    await _pumpFor(tester, const Duration(seconds: 1));

    expect(find.byType(Scaffold), findsWidgets);
  });
}

void _logStep(String message) {
  debugPrint(message);
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final steps = duration.inMilliseconds ~/ 100;
  for (var index = 0; index < steps; index++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
