import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FAB and Navigation Tests', () {
    testWidgets('Speed Dial FAB animates correctly', (
      WidgetTester tester,
    ) async {
      // Simple FAB animation test
      bool fabOpen = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                appBar: AppBar(title: const Text('Test')),
                body: const Center(child: Text('Body')),
                floatingActionButton: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedOpacity(
                      opacity: fabOpen ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedSlide(
                        offset: fabOpen ? Offset.zero : const Offset(0, 0.4),
                        duration: const Duration(milliseconds: 200),
                        child: IgnorePointer(
                          ignoring: !fabOpen,
                          child: FloatingActionButton.small(
                            heroTag: 'fab_edit',
                            onPressed: () {},
                            child: const Icon(Icons.edit_note),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedRotation(
                      turns: fabOpen ? 0.125 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutBack,
                      child: FloatingActionButton(
                        heroTag: 'fab_main',
                        onPressed: () {
                          setState(() => fabOpen = !fabOpen);
                        },
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Find main FAB
      final mainFab = find.byIcon(Icons.add);
      final editFab = find.byIcon(Icons.edit_note);
      final editFabIgnorePointer = find.ancestor(
        of: editFab,
        matching: find.byType(IgnorePointer),
      );
      expect(mainFab, findsOneWidget);

      // Sub-button stays in the tree but starts disabled/faded.
      expect(editFab, findsOneWidget);
      expect(
        tester.widget<IgnorePointer>(editFabIgnorePointer.first).ignoring,
        isTrue,
      );

      // Tap main FAB
      await tester.tap(mainFab);
      await tester.pumpAndSettle();

      // Sub-button should now be interactive
      expect(editFab, findsOneWidget);
      expect(
        tester.widget<IgnorePointer>(editFabIgnorePointer.first).ignoring,
        isFalse,
      );

      // Tap main FAB again to close
      await tester.tap(mainFab);
      await tester.pumpAndSettle();

      // Sub-button should be disabled again
      expect(editFab, findsOneWidget);
      expect(
        tester.widget<IgnorePointer>(editFabIgnorePointer.first).ignoring,
        isTrue,
      );
    });

    testWidgets('Form fields render with styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Form Test')),
            body: Form(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'ร้านค้า',
                        prefixIcon: const Icon(Icons.storefront),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'จำนวนเงิน',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Verify fields render
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.byIcon(Icons.storefront), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);

      // Enter text in first field
      await tester.enterText(find.byType(TextFormField).first, 'CPF Coffee');
      await tester.pump();
      expect(find.text('CPF Coffee'), findsOneWidget);
    });
  });
}
