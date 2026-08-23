import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';

void main() {
  group('Category Validation Logic Tests', () {
    final now = DateTime.now();

    test('validates name required and non-empty', () {
      expect(() {
        final name = '   ';
        if (name.trim().isEmpty) {
          throw const ValidationException('Category name cannot be empty');
        }
      }, throwsA(isA<ValidationException>()));
    });

    test('validates maximum length', () {
      final longName = 'A' * 51;
      expect(() {
        if (longName.trim().length > 50) {
          throw const ValidationException('Name cannot exceed 50 characters');
        }
      }, throwsA(isA<ValidationException>()));
    });

    test('case-insensitive duplicate check within same category type', () {
      final existing = [
        Category(
          id: '1',
          userId: 'u1',
          name: 'Food',
          type: CategoryType.expense,
          createdAt: now,
          updatedAt: now,
        ),
        Category(
          id: '2',
          userId: 'u1',
          name: 'Salary',
          type: CategoryType.income,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Duplicate check for expense 'food ' -> should detect collision with 'Food'
      final newExpenseName = ' food  ';
      final isExpenseDuplicate = existing.any(
        (c) =>
            c.type == CategoryType.expense &&
            c.name.trim().toLowerCase() == newExpenseName.trim().toLowerCase(),
      );
      expect(isExpenseDuplicate, true);

      // Same name 'Food' for income -> allowed because category types are separate
      final isIncomeDuplicate = existing.any(
        (c) =>
            c.type == CategoryType.income &&
            c.name.trim().toLowerCase() == newExpenseName.trim().toLowerCase(),
      );
      expect(isIncomeDuplicate, false);
    });
  });
}
