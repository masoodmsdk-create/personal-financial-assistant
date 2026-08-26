import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/budgets/domain/models/budget.dart';

void main() {
  group('Budget Model Unit Tests', () {
    final now = DateTime(2026, 8, 1);

    test('Creates and serializes Budget instance accurately', () {
      final budget = Budget(
        id: 'b_1',
        userId: 'u_1',
        createdAt: now,
        updatedAt: now,
        year: 2026,
        month: 8,
        categoryId: 'cat_groceries',
        plannedAmount: 8000.0,
        note: 'Monthly Groceries Cap',
        active: true,
      );

      expect(budget.id, 'b_1');
      expect(budget.userId, 'u_1');
      expect(budget.year, 2026);
      expect(budget.month, 8);
      expect(budget.categoryId, 'cat_groceries');
      expect(budget.plannedAmount, 8000.0);
      expect(budget.note, 'Monthly Groceries Cap');
      expect(budget.active, isTrue);

      final map = budget.toMap();
      expect(map['id'], 'b_1');
      expect(map['userId'], 'u_1');
      expect(map['year'], 2026);
      expect(map['month'], 8);
      expect(map['categoryId'], 'cat_groceries');
      expect(map['plannedAmount'], 8000.0);
      expect(map['note'], 'Monthly Groceries Cap');
      expect(map['active'], isTrue);

      final fromMap = Budget.fromMap(map, 'b_1');
      expect(fromMap.id, budget.id);
      expect(fromMap.userId, budget.userId);
      expect(fromMap.year, budget.year);
      expect(fromMap.month, budget.month);
      expect(fromMap.categoryId, budget.categoryId);
      expect(fromMap.plannedAmount, budget.plannedAmount);
      expect(fromMap.note, budget.note);
      expect(fromMap.active, budget.active);
    });

    test('copyWith updates specified fields only', () {
      final budget = Budget(
        id: 'b_1',
        userId: 'u_1',
        createdAt: now,
        updatedAt: now,
        year: 2026,
        month: 8,
        categoryId: 'cat_groceries',
        plannedAmount: 8000.0,
        note: 'Initial Note',
        active: true,
      );

      final updated = budget.copyWith(
        plannedAmount: 10000.0,
        note: 'Updated Note',
      );

      expect(updated.id, 'b_1');
      expect(updated.plannedAmount, 10000.0);
      expect(updated.note, 'Updated Note');
      expect(updated.year, 2026);
      expect(updated.month, 8);
    });
  });
}
