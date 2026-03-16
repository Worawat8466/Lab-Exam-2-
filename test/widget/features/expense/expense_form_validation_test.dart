import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ExpenseValidationHarness extends StatelessWidget {
  _ExpenseValidationHarness();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Merchant'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Merchant is required';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Category is required';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null) {
                    return 'Amount must be a valid number';
                  }
                  if (parsed < 0) {
                    return 'Amount must be non-negative';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  _formKey.currentState?.validate();
                },
                child: const Text('Save Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('shows validation errors when required fields are empty', (
    tester,
  ) async {
    await tester.pumpWidget(_ExpenseValidationHarness());

    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    expect(find.text('Merchant is required'), findsOneWidget);
    expect(find.text('Category is required'), findsOneWidget);
    expect(find.text('Amount is required'), findsOneWidget);
  });
}
