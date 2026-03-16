import 'package:flutter_test/flutter_test.dart';
import 'package:labexam2/features/dashboard/domain/entities/summary_period.dart';

void main() {
  group('Dashboard Summary Unit Tests', () {
    test('SummaryPeriod enum values', () {
      expect(SummaryPeriod.weekly.name, 'weekly');
      expect(SummaryPeriod.monthly.name, 'monthly');
      expect(SummaryPeriod.quarterly.name, 'quarterly');
      expect(SummaryPeriod.yearly.name, 'yearly');
    });

    test('Period label mapping', () {
      final periodNames = {
        'weekly': 'สัปดาห์',
        'monthly': 'เดือน',
        'quarterly': 'ไตรมาส',
        'yearly': 'ปี',
      };

      expect(periodNames['weekly'], 'สัปดาห์');
      expect(periodNames['monthly'], 'เดือน');
    });
  });

  group('Expense Validation Unit Tests', () {
    test('Merchant name validation', () {
      String? validateMerchant(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'กรุณากรอกร้านค้า';
        }
        return null;
      }

      expect(validateMerchant(''), 'กรุณากรอกร้านค้า');
      expect(validateMerchant('CPF'), isNull);
      expect(validateMerchant('  7-11  '), isNull);
    });

    test('Amount validation', () {
      String? validateAmount(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'กรุณากรอกจำนวนเงิน';
        }
        final parsed = double.tryParse(value);
        if (parsed == null) {
          return 'จำนวนเงินต้องเป็นตัวเลข';
        }
        if (parsed < 0) {
          return 'จำนวนเงินต้องไม่ติดลบ';
        }
        return null;
      }

      expect(validateAmount(''), 'กรุณากรอกจำนวนเงิน');
      expect(validateAmount('abc'), 'จำนวนเงินต้องเป็นตัวเลข');
      expect(validateAmount('-100'), 'จำนวนเงินต้องไม่ติดลบ');
      expect(validateAmount('150.50'), isNull);
      expect(validateAmount('100'), isNull);
    });

    test('Currency validation', () {
      String? validateCurrency(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'กรุณากรอกสกุลเงิน';
        }
        return null;
      }

      expect(validateCurrency(''), 'กรุณากรอกสกุลเงิน');
      expect(validateCurrency('THB'), isNull);
      expect(validateCurrency('USD'), isNull);
    });
  });

  group('Number Formatting Tests', () {
    test('Amount format with 2 decimal places', () {
      double amount = 150.556;
      expect(amount.toStringAsFixed(2), '150.56');

      double wholeAmount = 100;
      expect(wholeAmount.toStringAsFixed(2), '100.00');
    });

    test('Currency symbol display', () {
      String formatCurrency(double amount, String currency) {
        return '$currency ${amount.toStringAsFixed(2)}';
      }

      expect(formatCurrency(150.50, 'THB'), 'THB 150.50');
      expect(formatCurrency(100, 'USD'), 'USD 100.00');
    });
  });
}
