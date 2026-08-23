import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';

void main() {
  final now = DateTime(2026, 8, 1);

  group('Goal Model Tests', () {
    test('calculates progressPercentage and remainingAmount correctly', () {
      final goal = Goal(
        id: 'goal_1',
        userId: 'user_1',
        name: 'Emergency Fund',
        type: GoalType.emergencyFund,
        targetAmount: 100000.0,
        currentAmount: 25000.0,
        createdAt: now,
        updatedAt: now,
      );

      expect(goal.progressPercentage, 25.0);
      expect(goal.remainingAmount, 75000.0);
      expect(goal.isCompleted, false);
    });

    test('isCompleted returns true when currentAmount >= targetAmount', () {
      final goal = Goal(
        id: 'goal_2',
        userId: 'user_1',
        name: 'Vacation Goal',
        type: GoalType.savingsGoal,
        targetAmount: 50000.0,
        currentAmount: 55000.0,
        createdAt: now,
        updatedAt: now,
      );

      expect(goal.progressPercentage, 100.0);
      expect(goal.remainingAmount, 0.0);
      expect(goal.isCompleted, true);
    });

    test('json serialization roundtrip works cleanly', () {
      final goal = Goal(
        id: 'goal_3',
        userId: 'user_1',
        name: 'Debt Payoff Goal',
        type: GoalType.debtGoal,
        targetAmount: 500000.0,
        currentAmount: 100000.0,
        targetDate: DateTime(2028, 12, 31),
        createdAt: now,
        updatedAt: now,
      );

      final json = goal.toJson();
      final restored = Goal.fromJson(json);

      expect(restored.id, goal.id);
      expect(restored.name, goal.name);
      expect(restored.type, GoalType.debtGoal);
      expect(restored.targetAmount, 500000.0);
    });
  });
}
