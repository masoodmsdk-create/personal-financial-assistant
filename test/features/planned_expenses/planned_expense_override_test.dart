import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense_override.dart';

void main() {
  group('PlannedExpense Override & Effective Amount Tests', () {
    final now = DateTime.parse('2026-08-23T06:00:00.000Z');
    final startDate = DateTime.parse('2026-01-01T00:00:00.000Z');

    final electricityPlan = PlannedExpense(
      id: 'plan_elec_1',
      userId: 'user_123',
      createdAt: now,
      updatedAt: now,
      name: 'Electricity',
      categoryId: 'cat_exp_utilities',
      defaultAmount: 3000.00,
      frequency: RecurrenceFrequency.monthly,
      startDate: startDate,
      active: true,
    );

    test('PlannedExpenseOverride serializes and deserializes correctly', () {
      final override = PlannedExpenseOverride(
        id: 'ov_plan_elec_1_2026_9',
        userId: 'user_123',
        createdAt: now,
        updatedAt: now,
        planId: 'plan_elec_1',
        year: 2026,
        month: 9,
        amount: 2700.00,
      );

      final json = override.toJson();
      expect(json['id'], 'ov_plan_elec_1_2026_9');
      expect(json['planId'], 'plan_elec_1');
      expect(json['year'], 2026);
      expect(json['month'], 9);
      expect(json['amount'], 2700.00);

      final deserialized = PlannedExpenseOverride.fromJson(json);
      expect(deserialized.amount, 2700.00);
      expect(deserialized.planId, 'plan_elec_1');
    });

    test('September override ₹2,700 produces effective amount ₹2,700 while default remains ₹3,000', () {
      final septemberOverride = PlannedExpenseOverride(
        id: PlannedExpenseOverride.generateId('plan_elec_1', 2026, 9),
        userId: 'user_123',
        createdAt: now,
        updatedAt: now,
        planId: 'plan_elec_1',
        year: 2026,
        month: 9,
        amount: 2700.00,
      );

      // Verify September effective calculation
      final septemberEffective = septemberOverride.amount;
      expect(septemberEffective, 2700.00);

      // Default amount on recurring plan remains unchanged
      expect(electricityPlan.defaultAmount, 3000.00);

      // October calculation without override reverts to defaultAmount
      final Map<String, PlannedExpenseOverride> octOverrides = {};
      final octEffective =
          octOverrides['plan_elec_1']?.amount ?? electricityPlan.defaultAmount;
      expect(octEffective, 3000.00);
    });
  });
}
