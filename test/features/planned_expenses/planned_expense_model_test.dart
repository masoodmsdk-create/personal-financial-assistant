import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';

void main() {
  group('PlannedExpense Model Tests', () {
    final now = DateTime.parse('2026-08-23T06:00:00.000Z');
    final startDate = DateTime.parse('2026-01-01T00:00:00.000Z');

    final samplePlan = PlannedExpense(
      id: 'plan_123',
      userId: 'user_456',
      createdAt: now,
      updatedAt: now,
      name: 'House Rent',
      categoryId: 'cat_exp_rent',
      defaultAmount: 25000.00,
      frequency: RecurrenceFrequency.monthly,
      startDate: startDate,
      active: true,
    );

    test('serializes to JSON correctly', () {
      final json = samplePlan.toJson();
      expect(json['id'], 'plan_123');
      expect(json['userId'], 'user_456');
      expect(json['name'], 'House Rent');
      expect(json['categoryId'], 'cat_exp_rent');
      expect(json['defaultAmount'], 25000.00);
      expect(json['frequency'], 'monthly');
      expect(json['active'], true);
    });

    test('deserializes from JSON correctly', () {
      final json = samplePlan.toJson();
      final deserialized = PlannedExpense.fromJson(json);
      expect(deserialized.id, samplePlan.id);
      expect(deserialized.userId, samplePlan.userId);
      expect(deserialized.name, samplePlan.name);
      expect(deserialized.categoryId, samplePlan.categoryId);
      expect(deserialized.defaultAmount, samplePlan.defaultAmount);
      expect(deserialized.frequency, RecurrenceFrequency.monthly);
    });

    test(
      'RecurrenceFrequency extensions return proper display names and values',
      () {
        expect(RecurrenceFrequency.monthly.value, 'monthly');
        expect(RecurrenceFrequency.monthly.displayName, 'Monthly');
        expect(RecurrenceFrequency.yearly.displayName, 'Yearly');
        expect(
          RecurrenceFrequencyX.fromString('yearly'),
          RecurrenceFrequency.yearly,
        );
        expect(
          RecurrenceFrequencyX.fromString('unknown'),
          RecurrenceFrequency.monthly,
        );
      },
    );

    test('appliesToMonth returns true for valid active monthly plan', () {
      expect(samplePlan.appliesToMonth(2026, 9), true);
      expect(samplePlan.appliesToMonth(2026, 10), true);

      // Inactive plan does not apply
      final inactive = samplePlan.copyWith(active: false);
      expect(inactive.appliesToMonth(2026, 9), false);
    });
  });
}
