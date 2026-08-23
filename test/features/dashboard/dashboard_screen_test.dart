import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';

import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/screens/dashboard_screen.dart';
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
  ];

  testWidgets(
    'DashboardScreen renders overview cards, insights section, chart, and recent transactions',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
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
              (ref) => Stream.value([]),
            ),
            monthlyOverridesStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
          ],

          child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
        ),
      );

      await tester.pump(Duration.zero);
      await tester.pumpAndSettle();

      expect(find.text('Financial Overview'), findsOneWidget);
      expect(find.text('Total Net Balance'), findsOneWidget);

      expect(find.text('Monthly Income'), findsOneWidget);
      expect(find.text('Monthly Expenses'), findsOneWidget);
      expect(find.text('Net Cash Flow'), findsWidgets);

      expect(find.text('Things to Review'), findsOneWidget);
      expect(find.text('Income vs Expense'), findsOneWidget);
      expect(find.text('Recent Transactions'), findsOneWidget);
    },
  );
}
