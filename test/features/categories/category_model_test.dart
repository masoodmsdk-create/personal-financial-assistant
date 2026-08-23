import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';

void main() {
  group('Category Model Tests', () {
    final now = DateTime.parse('2026-08-23T06:00:00.000Z');
    final sampleCategory = Category(
      id: 'cat_123',
      userId: 'user_456',
      createdAt: now,
      updatedAt: now,
      name: 'Groceries',
      type: CategoryType.expense,
      active: true,
      isDefault: false,
      sortOrder: 1,
    );

    test('serializes to JSON correctly', () {
      final json = sampleCategory.toJson();
      expect(json['id'], 'cat_123');
      expect(json['userId'], 'user_456');
      expect(json['name'], 'Groceries');
      expect(json['type'], 'expense');
      expect(json['active'], true);
      expect(json['isDefault'], false);
      expect(json['sortOrder'], 1);
    });

    test('deserializes from JSON correctly', () {
      final json = sampleCategory.toJson();
      final deserialized = Category.fromJson(json);
      expect(deserialized.id, sampleCategory.id);
      expect(deserialized.userId, sampleCategory.userId);
      expect(deserialized.name, sampleCategory.name);
      expect(deserialized.type, sampleCategory.type);
      expect(deserialized.active, sampleCategory.active);
      expect(deserialized.isDefault, sampleCategory.isDefault);
    });

    test('copyWith updates fields correctly', () {
      final updated = sampleCategory.copyWith(
        name: 'Supermarket Groceries',
        active: false,
      );
      expect(updated.name, 'Supermarket Groceries');
      expect(updated.active, false);
      expect(updated.type, CategoryType.expense);
      expect(updated.id, sampleCategory.id);
    });

    test('CategoryType extensions return proper values', () {
      expect(CategoryType.income.value, 'income');
      expect(CategoryType.expense.value, 'expense');
      expect(CategoryType.income.displayName, 'Income');
      expect(CategoryType.expense.displayName, 'Expense');
      expect(CategoryTypeX.fromString('income'), CategoryType.income);
      expect(CategoryTypeX.fromString('expense'), CategoryType.expense);
      expect(CategoryTypeX.fromString('unknown'), CategoryType.expense);
    });

    test('generateDefaults creates default income and expense categories', () {
      final defaults = Category.generateDefaults('user_789', now: now);
      expect(defaults.isNotEmpty, true);

      final incomeDefaults = defaults
          .where((c) => c.type == CategoryType.income)
          .toList();
      final expenseDefaults = defaults
          .where((c) => c.type == CategoryType.expense)
          .toList();

      expect(incomeDefaults.map((c) => c.name), contains('Salary'));
      expect(incomeDefaults.map((c) => c.name), contains('Freelance'));
      expect(expenseDefaults.map((c) => c.name), contains('Food'));
      expect(expenseDefaults.map((c) => c.name), contains('Rent'));
      expect(
        expenseDefaults.map((c) => c.name),
        contains('EMI / Loan Payment'),
      );

      // Ensure no specific family member income names are present
      expect(incomeDefaults.any((c) => c.name.contains('Wife')), false);
      expect(incomeDefaults.any((c) => c.name.contains('Father')), false);

      for (final cat in defaults) {
        expect(cat.isDefault, true);
        expect(cat.active, true);
        expect(cat.userId, 'user_789');
      }
    });

    test('generateDefaults produces deterministic unique category IDs', () {
      final defaults1 = Category.generateDefaults('user_123', now: now);
      final defaults2 = Category.generateDefaults('user_123', now: now);

      final ids1 = defaults1.map((c) => c.id).toList();
      final ids2 = defaults2.map((c) => c.id).toList();

      expect(ids1, equals(ids2));
      expect(ids1.length, equals(ids1.toSet().length));
    });
  });
}
