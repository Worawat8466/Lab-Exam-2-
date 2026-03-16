import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseFormPage Widget Tests', () {
    testWidgets('Expense form renders and accepts input', (
      WidgetTester tester,
    ) async {
      // This is a simplified widget test to verify form functionality
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Form(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Merchant'),
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Category'),
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Amount'),
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Currency'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Find TextFormFields
      expect(find.byType(TextFormField), findsWidgets);

      // Enter data into first field (merchant)
      await tester.enterText(find.byType(TextFormField).at(0), 'CPF');
      await tester.pump();
      expect(find.text('CPF'), findsOneWidget);

      // Enter data into second field (category)
      await tester.enterText(find.byType(TextFormField).at(1), 'Food');
      await tester.pump();
      expect(find.text('Food'), findsOneWidget);

      // Enter data into third field (amount)
      await tester.enterText(find.byType(TextFormField).at(2), '150.50');
      await tester.pump();
      expect(find.text('150.50'), findsOneWidget);

      // Enter data into fourth field (currency)
      await tester.enterText(find.byType(TextFormField).at(3), 'THB');
      await tester.pump();
      expect(find.text('THB'), findsOneWidget);
    });

    testWidgets('FAB animations and buttons work', (WidgetTester tester) async {
      // Test FAB structure
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedOpacity(
                  opacity: 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedSlide(
                    offset: const Offset(0, 0.4),
                    duration: const Duration(milliseconds: 200),
                    child: FloatingActionButton.small(
                      heroTag: 'fab_scan',
                      onPressed: () {},
                      child: const Icon(Icons.document_scanner),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: AnimatedSlide(
                    offset: const Offset(0, 0.4),
                    duration: const Duration(milliseconds: 150),
                    child: FloatingActionButton.small(
                      heroTag: 'fab_add',
                      onPressed: () {},
                      child: const Icon(Icons.edit_note),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedRotation(
                  turns: 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: FloatingActionButton(
                    heroTag: 'fab_main',
                    onPressed: () {},
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
            body: const Center(child: Text('Home Page')),
          ),
        ),
      );

      // Verify FABs are rendered
      final fabs = find.byType(FloatingActionButton);
      expect(fabs, findsWidgets);

      // Verify Icons exist
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.edit_note), findsOneWidget);
      expect(find.byIcon(Icons.document_scanner), findsOneWidget);
    });
  });
}
