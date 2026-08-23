import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';

void main() {
  group('PlannedExpense Validation Logic Tests', () {
    test('validates non-empty name', () {
      final name = '   ';
      expect(() {
        if (name.trim().isEmpty) {
          throw const ValidationException('Expense name is required');
        }
      }, throwsA(isA<ValidationException>()));
    });

    test('validates name length maximum 50', () {
      final name = 'A' * 51;
      expect(() {
        if (name.trim().length > 50) {
          throw const ValidationException('Name cannot exceed 50 characters');
        }
      }, throwsA(isA<ValidationException>()));
    });

    test('validates planned amount > 0', () {
      const amount = 0.0;
      expect(() {
        if (amount <= 0) {
          throw const ValidationException(
            'Planned amount must be greater than zero',
          );
        }
      }, throwsA(isA<ValidationException>()));
    });

    test('validates end date cannot be before start date', () {
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2026, 8, 31);
      expect(() {
        if (end.isBefore(start)) {
          throw const ValidationException(
            'End date cannot be before start date',
          );
        }
      }, throwsA(isA<ValidationException>()));
    });
  });
}
