import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

void main() {
  group('Analytics Providers & Period Calculations Tests', () {
    final now = DateTime(2026, 8, 23);

    final categories = [
      Category(
        id: 'cat_salary',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        name: 'Salary',
        type: CategoryType.income,
        active: true,
      ),
      Category(
        id: 'cat_bonus',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        name: 'Wife Salary', // Custom user category
        type: CategoryType.income,
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
      Category(
        id: 'cat_old',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        name: 'Archived Category',
        type: CategoryType.expense,
        active: false,
      ),
    ];

    final transactions = [
      Transaction(
        id: 't1',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.income,
        amount: 100000.0,
        accountId: 'acc_1',
        categoryId: 'cat_salary',
        date: DateTime(2026, 8, 5),
      ),
      Transaction(
        id: 't2',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.income,
        amount: 50000.0,
        accountId: 'acc_1',
        categoryId: 'cat_bonus',
        date: DateTime(2026, 8, 10),
      ),
      Transaction(
        id: 't3',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.expense,
        amount: 30000.0,
        accountId: 'acc_1',
        categoryId: 'cat_food',
        date: DateTime(2026, 8, 15),
      ),
      Transaction(
        id: 't4',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.expense,
        amount: 5000.0,
        accountId: 'acc_1',
        categoryId: 'cat_old', // Archived category transaction
        date: DateTime(2026, 8, 20),
      ),
      Transaction(
        id: 't5',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.transfer,
        amount: 15000.0,
        fromAccountId: 'acc_1',
        toAccountId: 'acc_2',
        date: DateTime(2026, 8, 22),
      ),
    ];

    test('periodDateRangeProvider computes correct date boundaries for Weekly, Monthly, Yearly', () {
      final container = ProviderContainer(
        overrides: [
          selectedAnalyticsDateProvider.overrideWith(
            (ref) => DateTime(2026, 8, 23),
          ),
        ],
      );

      // Monthly default
      final monthRange = container.read(periodDateRangeProvider);
      expect(monthRange.start, DateTime(2026, 8, 1));
      expect(monthRange.label, 'August 2026');

      // Weekly
      container.read(selectedAnalyticsPeriodModeProvider.notifier).state =
          AnalyticsPeriodMode.weekly;
      final weekRange = container.read(periodDateRangeProvider);
      expect(weekRange.start.weekday, DateTime.monday);

      // Yearly
      container.read(selectedAnalyticsPeriodModeProvider.notifier).state =
          AnalyticsPeriodMode.yearly;
      final yearRange = container.read(periodDateRangeProvider);
      expect(yearRange.start, DateTime(2026, 1, 1));
      expect(yearRange.label, '2026');
    });

    test('periodSummaryProvider correctly computes Income, Expense, Net Cash Flow, Transfers', () async {
      final container = ProviderContainer(
        overrides: [
          transactionsStreamProvider.overrideWith(
            (ref) => Stream.value(transactions),
          ),
          selectedAnalyticsDateProvider.overrideWith(
            (ref) => DateTime(2026, 8, 23),
          ),
        ],
      );

      // Listen to force stream evaluation
      container.listen(transactionsStreamProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final summary = container.read(periodSummaryProvider);
      expect(summary.totalIncome, 150000.0); // 100k + 50k
      expect(summary.totalExpense, 35000.0); // 30k + 5k
      expect(summary.netCashFlow, 115000.0); // 150k - 35k
      expect(summary.totalTransfers, 15000.0);
    });

    test('dynamic category breakdown handles custom categories and archived categories correctly', () async {
      final container = ProviderContainer(
        overrides: [
          transactionsStreamProvider.overrideWith(
            (ref) => Stream.value(transactions),
          ),
          categoriesStreamProvider.overrideWith(
            (ref) => Stream.value(categories),
          ),
          selectedAnalyticsDateProvider.overrideWith(
            (ref) => DateTime(2026, 8, 23),
          ),
        ],
      );

      container.listen(transactionsStreamProvider, (_, _) {});
      container.listen(categoriesStreamProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final incomeBreakdown = container.read(incomeCategoryBreakdownProvider);
      expect(incomeBreakdown.length, 2);
      expect(
        incomeBreakdown.any((item) => item.categoryName == 'Wife Salary'),
        true,
      );

      final expenseBreakdown = container.read(expenseCategoryBreakdownProvider);
      expect(expenseBreakdown.length, 2);
      expect(
        expenseBreakdown.any(
          (item) => item.categoryName == 'Archived Category',
        ),
        true,
      );
    });
  });
}
