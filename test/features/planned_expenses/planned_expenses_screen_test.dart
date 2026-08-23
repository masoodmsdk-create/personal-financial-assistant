import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense_override.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/screens/planned_expenses_screen.dart';

void main() {
  final now = DateTime.parse('2026-08-23T06:00:00.000Z');
  final testPlans = [
    PlannedExpense(
      id: 'plan_1',
      userId: 'user_1',
      createdAt: now,
      updatedAt: now,
      name: 'House Rent',
      categoryId: 'cat_rent',
      defaultAmount: 25000.00,
      frequency: RecurrenceFrequency.monthly,
      startDate: DateTime(2026, 1, 1),
      active: true,
    ),
    PlannedExpense(
      id: 'plan_2',
      userId: 'user_1',
      createdAt: now,
      updatedAt: now,
      name: 'Electricity',
      categoryId: 'cat_util',
      defaultAmount: 3000.00,
      frequency: RecurrenceFrequency.monthly,
      startDate: DateTime(2026, 1, 1),
      active: true,
    ),
  ];

  final testCategories = [
    Category(
      id: 'cat_rent',
      userId: 'user_1',
      createdAt: now,
      updatedAt: now,
      name: 'Rent',
      type: CategoryType.expense,
      active: true,
    ),
    Category(
      id: 'cat_util',
      userId: 'user_1',
      createdAt: now,
      updatedAt: now,
      name: 'Utilities',
      type: CategoryType.expense,
      active: true,
    ),
  ];

  testWidgets(
    'PlannedExpensesScreen renders Monthly Forecast tab and total forecast amount',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            plannedExpensesStreamProvider.overrideWith(
              (ref) => Stream.value(testPlans),
            ),
            monthlyOverridesStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            categoriesStreamProvider.overrideWith(
              (ref) => Stream.value(testCategories),
            ),
            selectedForecastDateProvider.overrideWith(
              (ref) => DateTime(2026, 9),
            ),
          ],
          child: const MaterialApp(home: PlannedExpensesScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Planned Expenses & Forecast'), findsOneWidget);
      expect(find.text('Monthly Forecast'), findsOneWidget);
      expect(find.text('Recurring Plans'), findsOneWidget);

      expect(find.text('Total Forecasted Expense'), findsOneWidget);
      expect(find.text('₹ 28000.00'), findsOneWidget); // 25000 + 3000
      expect(find.text('House Rent'), findsOneWidget);
      expect(find.text('Electricity'), findsOneWidget);
    },
  );

  testWidgets(
    'PlannedExpensesScreen reflects monthly override in forecast calculation',
    (WidgetTester tester) async {
      final override = PlannedExpenseOverride(
        id: 'ov_plan_2_2026_9',
        userId: 'user_1',
        createdAt: now,
        updatedAt: now,
        planId: 'plan_2',
        year: 2026,
        month: 9,
        amount: 2700.00,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            plannedExpensesStreamProvider.overrideWith(
              (ref) => Stream.value(testPlans),
            ),
            monthlyOverridesStreamProvider.overrideWith(
              (ref) => Stream.value([override]),
            ),
            categoriesStreamProvider.overrideWith(
              (ref) => Stream.value(testCategories),
            ),
            selectedForecastDateProvider.overrideWith(
              (ref) => DateTime(2026, 9),
            ),
          ],
          child: const MaterialApp(home: PlannedExpensesScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('₹ 27700.00'), findsOneWidget); // 25000 + 2700
      expect(find.text('Overridden'), findsOneWidget);
      expect(find.text('₹ 2700.00'), findsOneWidget);
    },
  );
}
