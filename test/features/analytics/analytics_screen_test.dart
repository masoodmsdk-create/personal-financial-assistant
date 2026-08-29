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

  group('AnalyticsScreen Responsive & Layout Constraint Tests', () {
    const viewports = <String, Size>{
      '360px (Small Mobile)': Size(360, 780),
      '390px (Standard Mobile)': Size(390, 844),
      '430px (Large Mobile)': Size(430, 932),
      '600px (Tablet Portrait)': Size(600, 900),
      '1024px (Tablet Landscape)': Size(1024, 768),
      '1280px (Desktop HD)': Size(1280, 800),
      '1440px (Desktop Widescreen)': Size(1440, 900),
    };

    for (final entry in viewports.entries) {
      testWidgets('Renders Planned vs Actual card correctly on ${entry.key}', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = entry.value;
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

        // 1. Verify Planned vs Actual title exists and is NOT collapsed
        final titleFinder = find.text('Planned vs Actual (Monthly)');
        expect(titleFinder, findsOneWidget);

        final titleSize = tester.getSize(titleFinder);
        // Verify width is substantial (greater than 120px) and not collapsed to ~15px character width
        expect(titleSize.width, greaterThan(120.0));
        // Verify height is normal single/two-line height (less than 60px) and not multi-character vertical stack
        expect(titleSize.height, lessThan(60.0));

        // 2. Verify metric tiles exist with readable dimensions
        expect(find.text('Planned'), findsOneWidget);
        expect(find.text('Actual'), findsOneWidget);
        expect(find.text('Manage Budget'), findsOneWidget);

        // 3. Verify zero exceptions / overflow errors
        expect(tester.takeException(), isNull);
      });
    }
  });
}
