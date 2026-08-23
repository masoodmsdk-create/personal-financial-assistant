import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

void main() {
  final now = DateTime.now();

  final testAccounts = [
    Account(
      id: 'acc_hdfc',
      userId: 'u1',
      createdAt: now,
      updatedAt: now,
      name: 'HDFC Bank',
      type: AccountType.bank,
      openingBalance: 50000.0,
      currency: 'INR',
      active: true,
    ),
    Account(
      id: 'acc_card',
      userId: 'u1',
      createdAt: now,
      updatedAt: now,
      name: 'HDFC Credit Card',
      type: AccountType.creditCard,
      openingBalance: 10000.0,
      currency: 'INR',
      active: true,
    ),
  ];

  final testCategories = [
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
      id: 'cat_food',
      userId: 'u1',
      createdAt: now,
      updatedAt: now,
      name: 'Food',
      type: CategoryType.expense,
      active: true,
    ),
  ];

  final testTransactions = [
    Transaction(
      id: 'tx_inc',
      userId: 'u1',
      createdAt: now,
      updatedAt: now,
      type: TransactionType.income,
      amount: 100000.0,
      accountId: 'acc_hdfc',
      categoryId: 'cat_salary',
      date: DateTime(now.year, now.month, 10),
    ),
    Transaction(
      id: 'tx_exp',
      userId: 'u1',
      createdAt: now,
      updatedAt: now,
      type: TransactionType.expense,
      amount: 30000.0,
      accountId: 'acc_hdfc',
      categoryId: 'cat_food',
      date: DateTime(now.year, now.month, 15),
    ),
  ];

  final testPlans = [
    PlannedExpense(
      id: 'p_food',
      userId: 'u1',
      createdAt: now,
      updatedAt: now,
      name: 'Food Budget',
      categoryId: 'cat_food',
      defaultAmount: 25000.0,
      frequency: RecurrenceFrequency.monthly,
      startDate: DateTime(2026, 1, 1),
      active: true,
    ),
  ];

  testWidgets(
    'AnalyticsScreen renders headers, period selector, charts, and breakdown cards',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionsStreamProvider.overrideWith(
              (ref) => Stream.value(testTransactions),
            ),
            accountsStreamProvider.overrideWith(
              (ref) => Stream.value(testAccounts),
            ),
            categoriesStreamProvider.overrideWith(
              (ref) => Stream.value(testCategories),
            ),
            plannedExpensesStreamProvider.overrideWith(
              (ref) => Stream.value(testPlans),
            ),
            monthlyOverridesStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
          ],
          child: const MaterialApp(home: AnalyticsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Analytics & Trends'), findsOneWidget);

      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);

      expect(find.text('Planned vs Actual (Monthly)'), findsOneWidget);
      expect(find.text('Things to Review'), findsOneWidget);
      expect(find.text('Income vs Expense'), findsOneWidget);
      expect(find.text('Expense Categories'), findsOneWidget);
      expect(find.text('Income Categories'), findsOneWidget);
      expect(find.text('Account Balances & Liabilities'), findsOneWidget);
    },
  );

  testWidgets('AnalyticsScreen period switching changes period selector mode', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsStreamProvider.overrideWith(
            (ref) => Stream.value(testTransactions),
          ),
          accountsStreamProvider.overrideWith(
            (ref) => Stream.value(testAccounts),
          ),
          categoriesStreamProvider.overrideWith(
            (ref) => Stream.value(testCategories),
          ),
          plannedExpensesStreamProvider.overrideWith((ref) => Stream.value([])),
          monthlyOverridesStreamProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
        ],
        child: const MaterialApp(home: AnalyticsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Weekly segment
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    expect(find.text('Weekly'), findsOneWidget);

    // Tap Yearly segment
    await tester.tap(find.text('Yearly'));
    await tester.pumpAndSettle();

    expect(find.text('Yearly'), findsOneWidget);
  });

  testWidgets(
    'AnalyticsScreen renders empty state when no transactions exist',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionsStreamProvider.overrideWith((ref) => Stream.value([])),
            accountsStreamProvider.overrideWith((ref) => Stream.value([])),
            categoriesStreamProvider.overrideWith((ref) => Stream.value([])),
            plannedExpensesStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            monthlyOverridesStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
          ],
          child: const MaterialApp(home: AnalyticsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Analytics & Trends'), findsOneWidget);

      expect(find.textContaining('No transactions recorded'), findsOneWidget);
    },
  );
}
