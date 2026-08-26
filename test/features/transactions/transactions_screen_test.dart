import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/screens/transactions_screen.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/widgets/add_edit_transaction_dialog.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class FakeTransactionController extends StateNotifier<AsyncValue<void>>
    implements TransactionController {
  FakeTransactionController() : super(const AsyncData(null));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
            recurringTransactionsStreamProvider.overrideWith(
              (ref) => Stream.value([]),
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
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
          recurringTransactionsStreamProvider.overrideWith(
            (ref) => Stream.value([]),
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

  testWidgets(
    'AddEditTransactionDialog displays One-time / Recurring toggle and switches fields seamlessly',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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
            recurringTransactionsStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            transactionControllerProvider.overrideWith(
              (ref) => FakeTransactionController(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const AddEditTransactionDialog(),
                    ),
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final ex = tester.takeException();
      if (ex != null) {
        // ignore: avoid_print
        print('DIAGNOSTIC EXCEPTION: $ex');
      }

      // Verify One-time and Recurring segments exist
      expect(find.text('One-time'), findsOneWidget);
      expect(find.text('Recurring'), findsOneWidget);

      // Default is One-time -> Save Transaction button
      expect(find.text('Save Transaction'), findsOneWidget);
      expect(find.text('Transaction Date *'), findsOneWidget);

      // Tap Recurring segment
      await tester.tap(find.text('Recurring'));
      await tester.pumpAndSettle();

      // Recurring fields should now appear
      expect(find.text('Rule Title / Description *'), findsOneWidget);
      expect(find.text('Frequency *'), findsOneWidget);
      expect(find.text('Start Date *'), findsOneWidget);
      expect(find.text('Save Recurring Rule'), findsOneWidget);

      // Switch back to One-time
      await tester.tap(find.text('One-time'));
      await tester.pumpAndSettle();

      expect(find.text('Save Transaction'), findsOneWidget);
      expect(find.text('Transaction Date *'), findsOneWidget);
    },
  );

  testWidgets(
    'AddEditTransactionDialog in Edit Mode locks to editing transaction and hides recurring toggle',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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
            recurringTransactionsStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            transactionControllerProvider.overrideWith(
              (ref) => FakeTransactionController(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AddEditTransactionDialog(
                        transaction: testTransactions.first,
                      ),
                    ),
                    child: const Text('Edit Dialog'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Dialog'));
      await tester.pumpAndSettle();

      // Title should be Edit Transaction
      expect(find.text('Edit Transaction'), findsOneWidget);
      // Segmented toggle between One-time and Recurring must NOT be shown in edit mode
      expect(find.text('One-time'), findsNothing);
      expect(find.text('Recurring'), findsNothing);
      // Save Changes button
      expect(find.text('Save Changes'), findsOneWidget);
    },
  );
}
