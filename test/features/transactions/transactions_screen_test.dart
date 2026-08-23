import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

void main() {
  final now = DateTime.now();
  final txDate = DateTime(now.year, now.month, 10);

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
      id: 'acc_sbi',
      userId: 'u1',
      createdAt: now,
      updatedAt: now,
      name: 'SBI Bank',
      type: AccountType.bank,
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
      id: 'tx_inc_1',
      userId: 'u1',
      createdAt: now,
      updatedAt: now,
      type: TransactionType.income,
      amount: 100000.0,
      accountId: 'acc_hdfc',
      categoryId: 'cat_salary',
      date: txDate,
      note: 'August Salary',
    ),
    Transaction(
      id: 'tx_exp_1',
      userId: 'u1',
      createdAt: now,
      updatedAt: now,
      type: TransactionType.expense,
      amount: 30000.0,
      accountId: 'acc_hdfc',
      categoryId: 'cat_food',
      date: txDate,
      note: 'Groceries and Dining',
    ),
    Transaction(
      id: 'tx_trf_1',
      userId: 'u1',
      createdAt: now,
      updatedAt: now,
      type: TransactionType.transfer,
      amount: 20000.0,
      fromAccountId: 'acc_hdfc',
      toAccountId: 'acc_sbi',
      date: txDate,
    ),
  ];

  testWidgets(
    'TransactionsScreen renders summary metrics and list items correctly',
    (WidgetTester tester) async {
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
            incomeCategoriesProvider.overrideWithValue(
              AsyncData(
                testCategories
                    .where((c) => c.type == CategoryType.income)
                    .toList(),
              ),
            ),
            expenseCategoriesProvider.overrideWithValue(
              AsyncData(
                testCategories
                    .where((c) => c.type == CategoryType.expense)
                    .toList(),
              ),
            ),
          ],
          child: const MaterialApp(home: TransactionsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Month Income'), findsOneWidget);
      expect(find.text('Month Expense'), findsOneWidget);
      expect(find.text('Net Cash Flow'), findsOneWidget);

      expect(
        find.text('+ ₹ 100000.00'),
        findsNWidgets(2),
      ); // Banner + List Tile
      expect(find.text('- ₹ 30000.00'), findsNWidgets(2)); // Banner + List Tile
      expect(find.text('₹ 20000.00'), findsOneWidget);
    },
  );

  testWidgets('Filter chip Income hides Expense and Transfer items', (
    WidgetTester tester,
  ) async {
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
        ],
        child: const MaterialApp(home: TransactionsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Income filter chip
    await tester.tap(find.widgetWithText(FilterChip, 'Income'));
    await tester.pumpAndSettle();

    expect(
      find.text('+ ₹ 100000.00'),
      findsNWidgets(2),
    ); // Banner + Income List Item
    expect(
      find.text('- ₹ 30000.00'),
      findsOneWidget,
    ); // Banner only (Expense item filtered out)
    expect(find.text('₹ 20000.00'), findsNothing); // Transfer item filtered out
  });
}
