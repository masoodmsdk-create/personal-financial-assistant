import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/screens/recurring_transactions_screen.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/widgets/add_edit_recurring_transaction_dialog.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/widgets/due_occurrences_banner.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

void main() {
  final now = DateTime(2026, 8, 1);

  final testCategories = [
    Category(
      id: 'cat_sal',
      userId: 'u1',
      name: 'Salary',
      type: CategoryType.income,
      createdAt: now,
      updatedAt: now,
    ),
    Category(
      id: 'cat_rent',
      userId: 'u1',
      name: 'Housing & Rent',
      type: CategoryType.expense,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  final testAccounts = [
    Account(
      id: 'acc_hdfc',
      userId: 'u1',
      name: 'HDFC Salary Bank',
      type: AccountType.bank,
      openingBalance: 50000.0,
      currency: 'INR',
      active: true,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  final testRules = [
    RecurringTransactionRule(
      id: 'rule_sal',
      userId: 'u1',
      createdAt: now,
      updatedAt: now,
      type: TransactionType.income,
      name: 'Monthly Salary',
      amount: 80000.0,
      categoryId: 'cat_sal',
      accountId: 'acc_hdfc',
      frequency: RecurrenceFrequency.monthly,
      dayOfMonth: 1,
      startDate: DateTime(2026, 8, 1),
      nextOccurrence: DateTime(2026, 9, 1),
      active: true,
    ),
    RecurringTransactionRule(
      id: 'rule_rent',
      userId: 'u1',
      createdAt: now,
      updatedAt: now,
      type: TransactionType.expense,
      name: 'Apartment Rent',
      amount: 25000.0,
      categoryId: 'cat_rent',
      accountId: 'acc_hdfc',
      frequency: RecurrenceFrequency.monthly,
      dayOfMonth: 5,
      startDate: DateTime(2026, 8, 1),
      nextOccurrence: DateTime(2026, 8, 5),
      active: true,
    ),
  ];

  Widget createWidgetToTest({
    List<RecurringTransactionRule> rules = const [],
  }) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => null),
        categoriesStreamProvider.overrideWith(
          (ref) => Stream.value(testCategories),
        ),
        accountsStreamProvider.overrideWith(
          (ref) => Stream.value(testAccounts),
        ),
        recurringTransactionsStreamProvider.overrideWith(
          (ref) => Stream.value(rules),
        ),
      ],
      child: const MaterialApp(
        home: RecurringTransactionsScreen(),
      ),
    );
  }

  group('RecurringTransactionsScreen Widget Tests', () {
    testWidgets('Renders empty state with action buttons when rules are empty', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetToTest(rules: []));
      await tester.pumpAndSettle();

      expect(find.text('Recurring Transactions'), findsOneWidget);
      expect(find.text('No Recurring Rules Configured'), findsOneWidget);
      expect(find.text('Add Recurring Rule'), findsWidgets);
      expect(find.text('Add Salary'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Renders rules, summary metrics, and filter chips when populated', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetToTest(rules: testRules));
      await tester.pumpAndSettle();

      expect(find.text('Recurring Transactions'), findsOneWidget);
      expect(find.text('Active Recurring Commitments'), findsOneWidget);
      expect(find.text('Monthly Salary'), findsOneWidget);
      expect(find.text('Apartment Rent'), findsOneWidget);

      // Verify filter chips exist
      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('Income (1)'), findsOneWidget);
      expect(find.text('Expenses (1)'), findsOneWidget);

      // Tap Income filter chip
      await tester.tap(find.text('Income (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Monthly Salary'), findsOneWidget);
      expect(find.text('Apartment Rent'), findsNothing);
    });

    testWidgets('AddEditRecurringTransactionDialog renders mandatory visible buttons', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesStreamProvider.overrideWith(
              (ref) => Stream.value(testCategories),
            ),
            accountsStreamProvider.overrideWith(
              (ref) => Stream.value(testAccounts),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AddEditRecurringTransactionDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Recurring Transaction'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save Recurring Rule'), findsOneWidget);

      // Tap Save without input to verify validation triggers
      await tester.tap(find.text('Save Recurring Rule'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a name'), findsOneWidget);
    });

    testWidgets('DueOccurrencesBanner renders when rules are due', (
      tester,
    ) async {
      final dueRule = RecurringTransactionRule(
        id: 'due_1',
        userId: 'u1',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.income,
        name: 'Salary',
        amount: 80000.0,
        categoryId: 'cat_sal',
        accountId: 'acc_hdfc',
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 8, 1),
        nextOccurrence: DateTime(2026, 8, 1), // Due today
        active: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recurringTransactionsStreamProvider.overrideWith(
              (ref) => Stream.value([dueRule]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DueOccurrencesBanner(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 Recurring Transaction Due'), findsOneWidget);
      expect(find.text('Process Due (1)'), findsOneWidget);
    });
  });
}
