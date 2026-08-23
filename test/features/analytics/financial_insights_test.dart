import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/analytics/domain/models/financial_insight.dart';
import 'package:personal_financial_assistant/features/analytics/domain/services/financial_insights_service.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense_override.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

void main() {
  group('Financial Insights Service Tests', () {
    final now = DateTime(2026, 8, 23);
    final periodDate = DateTime(2026, 8, 1);

    final categories = [
      Category(
        id: 'cat_rent',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        name: 'Rent',
        type: CategoryType.expense,
        active: true,
      ),
      Category(
        id: 'cat_food',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        name: 'Food',
        type: CategoryType.expense,
        active: true,
      ),
    ];

    final rentPlan = PlannedExpense(
      id: 'p_rent',
      userId: 'u1',
      createdAt: now,
      updatedAt: now,
      name: 'Rent Plan',
      categoryId: 'cat_rent',
      defaultAmount: 25000.0,
      frequency: RecurrenceFrequency.monthly,
      startDate: DateTime(2026, 1, 1),
      active: true,
    );

    final foodPlan = PlannedExpense(
      id: 'p_food',
      userId: 'u1',
      createdAt: now,
      updatedAt: now,
      name: 'Food Budget',
      categoryId: 'cat_food',
      defaultAmount: 10000.0,
      frequency: RecurrenceFrequency.monthly,
      startDate: DateTime(2026, 1, 1),
      active: true,
    );

    test('generates missing planned expense insight when no transaction exists for current/past month', () {
      final insights = FinancialInsightsService.generateInsights(
        transactions: [],
        plans: [rentPlan],
        overrides: [],
        categories: categories,
        periodDate: periodDate,
      );

      final missing = insights
          .where((i) => i.type == InsightType.missingPlannedExpense)
          .toList();
      expect(missing.length, 1);
      expect(missing.first.title, 'Unrecorded Expense Review');
      expect(missing.first.description, contains('Rent'));
      expect(missing.first.severity, InsightSeverity.warning);
    });

    test('generates upcoming planned expense insight for future months', () {
      final futureDate = DateTime(2026, 10, 1);
      final insights = FinancialInsightsService.generateInsights(
        transactions: [],
        plans: [rentPlan],
        overrides: [],
        categories: categories,
        periodDate: futureDate,
      );

      final upcoming = insights
          .where((i) => i.type == InsightType.upcomingPlannedExpense)
          .toList();
      expect(upcoming.length, 1);
      expect(upcoming.first.title, 'Upcoming Planned Expense');
      expect(upcoming.first.severity, InsightSeverity.info);
    });

    test(
      'generates above plan insight when actual expense exceeds planned amount',
      () {
        final txOver = Transaction(
          id: 't_food',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.expense,
          amount: 12500.0, // 2500 above 10000 plan
          accountId: 'acc_1',
          categoryId: 'cat_food',
          date: DateTime(2026, 8, 10),
        );

        final insights = FinancialInsightsService.generateInsights(
          transactions: [txOver],
          plans: [foodPlan],
          overrides: [],
          categories: categories,
          periodDate: periodDate,
        );

        final above = insights
            .where((i) => i.type == InsightType.abovePlan)
            .toList();
        expect(above.isNotEmpty, true);
        expect(
          above.first.description,
          contains('2,500.00 above your planned amount'),
        );
        expect(above.first.severity, InsightSeverity.warning);
      },
    );

    test('generates below plan insight when actual expenses are below monthly plan', () {
      final txUnder = Transaction(
        id: 't_rent',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.expense,
        amount: 20000.0, // 5000 below 25000 plan
        accountId: 'acc_1',
        categoryId: 'cat_rent',
        date: DateTime(2026, 8, 5),
      );

      final insights = FinancialInsightsService.generateInsights(
        transactions: [txUnder],
        plans: [rentPlan],
        overrides: [],
        categories: categories,
        periodDate: periodDate,
      );

      final below = insights
          .where((i) => i.type == InsightType.belowPlan)
          .toList();
      expect(below.isNotEmpty, true);
      expect(
        below.first.description,
        contains('5,000.00 below your monthly plan so far'),
      );
      expect(below.first.severity, InsightSeverity.success);
    });

    test(
      'no false positive missing insight when actual transaction exists',
      () {
        final txActual = Transaction(
          id: 't_rent_done',
          userId: 'u1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.expense,
          amount: 25000.0,
          accountId: 'acc_1',
          categoryId: 'cat_rent',
          date: DateTime(2026, 8, 1),
        );

        final insights = FinancialInsightsService.generateInsights(
          transactions: [txActual],
          plans: [rentPlan],
          overrides: [],
          categories: categories,
          periodDate: periodDate,
        );

        final missing = insights
            .where((i) => i.type == InsightType.missingPlannedExpense)
            .toList();
        expect(missing, isEmpty);
      },
    );

    test('returns empty insights list when insufficient data exists', () {
      final insights = FinancialInsightsService.generateInsights(
        transactions: [],
        plans: [],
        overrides: [],
        categories: [],
        periodDate: periodDate,
      );

      expect(insights, isEmpty);
    });

    test('respects monthly override amount in insight calculations', () {
      final override = PlannedExpenseOverride(
        id: 'ov_food',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        planId: 'p_food',
        year: 2026,
        month: 8,
        amount: 15000.0, // Override default 10000 to 15000
      );

      final tx = Transaction(
        id: 't_food',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.expense,
        amount: 12000.0,
        accountId: 'acc_1',
        categoryId: 'cat_food',
        date: DateTime(2026, 8, 10),
      );

      final insights = FinancialInsightsService.generateInsights(
        transactions: [tx],
        plans: [foodPlan],
        overrides: [override],
        categories: categories,
        periodDate: periodDate,
      );

      // Should be below plan because 12000 < 15000 override
      final below = insights
          .where((i) => i.type == InsightType.belowPlan)
          .toList();
      expect(below.isNotEmpty, true);
    });
  });
}
