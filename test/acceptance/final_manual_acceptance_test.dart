import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/domain/models/account_type_definition.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/budgets/presentation/providers/budget_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:personal_financial_assistant/features/forecast/domain/services/multi_horizon_forecast_service.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/insights/presentation/screens/insights_hub_screen.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/money/presentation/screens/money_hub_screen.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/plans/presentation/screens/plans_hub_screen.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/services/recurring_transaction_service.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/smart_entry/domain/services/smart_parser_service.dart';
import 'package:personal_financial_assistant/features/transactions/domain/services/financial_aggregation_service.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';
import 'package:personal_financial_assistant/features/workspaces/presentation/providers/workspace_providers.dart';
import 'package:personal_financial_assistant/features/workspaces/workspace.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  final testAccount1 = Account(
    id: 'acc_hdfc',
    userId: 'user_1',
    name: 'HDFC Bank',
    type: AccountType.bank,
    openingBalance: 200000.0,
    currency: 'INR',
    active: true,
    createdAt: now,
    updatedAt: now,
  );

  final testAccount2 = Account(
    id: 'acc_cash',
    userId: 'user_1',
    name: 'Cash',
    type: AccountType.cash,
    openingBalance: 20000.0,
    currency: 'INR',
    active: true,
    createdAt: now,
    updatedAt: now,
  );

  final testCreditCard = Account(
    id: 'acc_cc',
    userId: 'user_1',
    name: 'Infinia Card',
    type: AccountType.creditCard,
    openingBalance: 15000.0, // ₹15,000 existing debt
    currency: 'INR',
    active: true,
    createdAt: now,
    updatedAt: now,
  );

  final testSalaryRule = RecurringTransactionRule(
    id: 'rule_sal',
    userId: 'user_1',
    name: 'Monthly Salary',
    amount: 80000.0,
    type: TransactionType.income,
    frequency: RecurrenceFrequency.monthly,
    interval: 1,
    categoryId: 'cat_salary',
    startDate: now,
    nextOccurrence: now.add(const Duration(days: 30)),
    accountId: 'acc_hdfc',
    active: true,
    createdAt: now,
    updatedAt: now,
  );

  final testRentRule = RecurringTransactionRule(
    id: 'rule_rent',
    userId: 'user_1',
    name: 'Apartment Rent',
    amount: 15000.0,
    type: TransactionType.expense,
    frequency: RecurrenceFrequency.monthly,
    interval: 1,
    categoryId: 'cat_rent',
    startDate: now,
    nextOccurrence: now.add(const Duration(days: 5)),
    accountId: 'acc_hdfc',
    active: true,
    createdAt: now,
    updatedAt: now,
  );

  final mockWorkspace = Workspace(
    id: 'ws_personal',
    name: 'Family Finances',
    userId: 'user_1',
    purpose: 'Personal & Family Financial Management',
    createdAt: now,
    updatedAt: now,
  );

  Widget createAcceptanceApp({required Widget child}) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(null),
        accountsStreamProvider.overrideWith(
          (ref) => Stream.value([testAccount1, testAccount2, testCreditCard]),
        ),
        accountTypesStreamProvider.overrideWith(
          (ref) => Stream.value(AccountTypeDefinition.defaultTypes),
        ),
        categoriesStreamProvider.overrideWith((ref) => Stream.value([])),
        recurringTransactionsStreamProvider.overrideWith(
          (ref) => Stream.value([testSalaryRule, testRentRule]),
        ),
        loansStreamProvider.overrideWith((ref) => Stream.value([])),
        goalsStreamProvider.overrideWith((ref) => Stream.value([])),
        plannedExpensesStreamProvider.overrideWith((ref) => Stream.value([])),
        monthlyOverridesStreamProvider.overrideWith((ref) => Stream.value([])),
        budgetsStreamProvider.overrideWith((ref) => Stream.value([])),
        transactionsStreamProvider.overrideWith((ref) => Stream.value([])),
        workspacesStreamProvider.overrideWith(
          (ref) => Stream.value([mockWorkspace]),
        ),
        activeWorkspaceProvider.overrideWithValue(mockWorkspace),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('MSD FINAURA Final Manual Acceptance Tests', () {
    test('1. Real Account Balance & Liability Math Audit', () {
      final accounts = [testAccount1, testAccount2, testCreditCard];
      final transactions = [
        Transaction(
          id: 'tx_1',
          userId: 'user_1',
          accountId: 'acc_hdfc',
          amount: 80000.0,
          type: TransactionType.income,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: 'tx_2',
          userId: 'user_1',
          accountId: 'acc_hdfc',
          amount: 15000.0,
          type: TransactionType.expense,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: 'tx_3',
          userId: 'user_1',
          fromAccountId: 'acc_hdfc',
          toAccountId: 'acc_cash',
          amount: 5000.0,
          type: TransactionType.transfer,
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          id: 'tx_4',
          userId: 'user_1',
          accountId: 'acc_cc',
          amount: 3000.0,
          type: TransactionType.expense, // Credit card purchase increases debt
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final balances = FinancialAggregationService.calculateAccountBalances(
        accounts,
        transactions,
      );

      // HDFC: 2,00,000 + 80,000 - 15,000 - 5,000 = 2,60,000
      expect(balances['acc_hdfc'], 260000.0);
      // Cash: 20,000 + 5,000 = 25,000
      expect(balances['acc_cash'], 25000.0);
      // CC Liability: 15,000 + 3,000 = 18,000
      expect(balances['acc_cc'], 18000.0);

      // Total Net Balance: Assets (2,60,000 + 25,000 = 2,85,000) - Liabilities (18,000) = 2,67,000
      final netBalance = FinancialAggregationService.calculateTotalNetBalance(
        accounts,
        balances,
      );
      expect(netBalance, 267000.0);
    });

    test('2. Recurring Calendar 31st / Leap Year / February Clamping', () {
      const service = RecurringTransactionService();

      // Jan 31 -> Feb (non-leap year 2025) clamped to Feb 28
      final jan31 = DateTime(2025, 1, 31);
      final nextFeb = service.calculateNextOccurrence(
        fromDate: jan31,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        dayOfMonth: 31,
      );
      expect(nextFeb, DateTime(2025, 2, 28));

      // Jan 31 -> Feb (leap year 2024) clamped to Feb 29
      final jan31Leap = DateTime(2024, 1, 31);
      final nextFebLeap = service.calculateNextOccurrence(
        fromDate: jan31Leap,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        dayOfMonth: 31,
      );
      expect(nextFebLeap, DateTime(2024, 2, 29));

      // Mar 31 -> Apr 30
      final mar31 = DateTime(2025, 3, 31);
      final nextApr = service.calculateNextOccurrence(
        fromDate: mar31,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        dayOfMonth: 31,
      );
      expect(nextApr, DateTime(2025, 4, 30));
    });

    test('3. Smart Parser Recurring Intent vs One-Time Intent', () {
      const parser = SmartParserService();
      final accounts = [testAccount1, testAccount2];
      final categories = Category.generateDefaults('user_1');

      // "Salary ₹80,000 every month" -> Recurring Monthly
      final draft1 = parser.parseText(
        rawText: 'Salary ₹80,000 every month',
        accounts: accounts,
        categories: categories,
      );
      expect(draft1.length, 1);
      expect(draft1.first.isRecurring, isTrue);
      expect(draft1.first.frequency, RecurrenceFrequency.monthly);
      expect(draft1.first.amount, 80000.0);

      // "Paid ₹500 groceries today" -> One-time Expense
      final draft2 = parser.parseText(
        rawText: 'Paid ₹500 groceries today',
        accounts: accounts,
        categories: categories,
      );
      expect(draft2.length, 1);
      expect(draft2.first.isRecurring, isFalse);
      expect(draft2.first.amount, 500.0);
    });

    test('4. Multi-Horizon Deterministic Forecast Projection Math', () {
      const forecastService = MultiHorizonForecastService();
      final accounts = [testAccount1, testAccount2, testCreditCard];
      final recurring = [testSalaryRule, testRentRule];

      final forecast = forecastService.calculateMultiHorizonForecast(
        accounts: accounts,
        recurringRules: recurring,
        loans: [],
        goals: [],
        plannedExpenses: [],
        asOfDate: now,
      );

      // In 1 month: Net cash flow = 80,000 - 15,000 = +65,000
      expect(forecast.month1.cumulativeIncome, 80000.0);
      expect(forecast.month1.cumulativeLivingExpenses, 15000.0);
      expect(forecast.month1.cumulativeNetCashFlow, 65000.0);

      // In 4 months: 4 * 65,000 = +2,60,000
      expect(forecast.month4.cumulativeNetCashFlow, 260000.0);

      // In 6 months: 6 * 65,000 = +3,90,000
      expect(forecast.month6.cumulativeNetCashFlow, 390000.0);

      // In 12 months: 12 * 65,000 = +7,80,000
      expect(forecast.month12.cumulativeNetCashFlow, 780000.0);
    });

    testWidgets('5a. DashboardScreen renders cleanly on 390px mobile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createAcceptanceApp(child: const DashboardScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Financial Position'), findsOneWidget);
      expect(find.text('This Month’s Cash Flow'), findsOneWidget);
    });

    testWidgets('5b. MoneyHubScreen renders cleanly on 390px mobile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createAcceptanceApp(child: const MoneyHubScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Accounts'), findsWidgets);
      expect(find.text('Transactions'), findsWidgets);
      expect(find.text('Recurring Rules'), findsWidgets);
    });

    testWidgets('5c. PlansHubScreen renders cleanly on 390px mobile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createAcceptanceApp(child: const PlansHubScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Budgets'), findsWidgets);
      expect(find.text('Goals'), findsWidgets);
    });

    testWidgets('5d. InsightsHubScreen renders cleanly on 390px mobile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createAcceptanceApp(child: const InsightsHubScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Analytics'), findsWidgets);
      expect(find.text('Forecast'), findsWidgets);
    });
  });
}
