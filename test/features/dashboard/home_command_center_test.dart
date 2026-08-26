import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/domain/models/account_type_definition.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/widgets/account_breakdown_dialog.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/budgets/presentation/providers/budget_providers.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/widgets/financial_position_breakdown_dialog.dart';
import 'package:personal_financial_assistant/features/forecast/presentation/widgets/forecast_breakdown_dialog.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  final testAccount = Account(
    id: 'acc_salary',
    userId: 'user_1',
    name: 'Salary Account',
    type: AccountType.bank,
    openingBalance: 50000.0,
    currency: 'INR',
    active: true,
    createdAt: now,
    updatedAt: now,
  );

  final testCreditCard = Account(
    id: 'acc_cc',
    userId: 'user_1',
    name: 'Rewards Card',
    type: AccountType.creditCard,
    openingBalance: 10000.0,
    currency: 'INR',
    active: true,
    createdAt: now,
    updatedAt: now,
  );

  final testRecurringSalary = RecurringTransactionRule(
    id: 'rec_sal',
    userId: 'user_1',
    name: 'Monthly Salary',
    amount: 75000.0,
    type: TransactionType.income,
    frequency: RecurrenceFrequency.monthly,
    interval: 1,
    categoryId: 'cat_salary',
    startDate: now,
    nextOccurrence: now.add(const Duration(days: 30)),
    accountId: 'acc_salary',
    active: true,
    createdAt: now,
    updatedAt: now,
  );

  final testLoan = Loan(
    id: 'loan_auto',
    userId: 'user_1',
    name: 'Auto Loan',
    type: LoanType.carLoan,
    originalPrincipal: 300000.0,
    outstandingPrincipal: 150000.0,
    interestRate: 9.0,
    emiAmount: 8500.0,
    startDate: now,
    nextEmiDate: now.add(const Duration(days: 15)),
    active: true,
    createdAt: now,
    updatedAt: now,
  );

  Widget createTestWidget({required Widget child}) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(null),
        accountsStreamProvider.overrideWith(
          (ref) => Stream.value([testAccount, testCreditCard]),
        ),
        accountTypesStreamProvider.overrideWith(
          (ref) => Stream.value(AccountTypeDefinition.defaultTypes),
        ),
        recurringTransactionsStreamProvider.overrideWith(
          (ref) => Stream.value([testRecurringSalary]),
        ),
        loansStreamProvider.overrideWith((ref) => Stream.value([testLoan])),
        goalsStreamProvider.overrideWith((ref) => Stream.value([])),
        plannedExpensesStreamProvider.overrideWith((ref) => Stream.value([])),
        budgetsStreamProvider.overrideWith((ref) => Stream.value([])),
        transactionsStreamProvider.overrideWith(
          (ref) => Stream.value([
            Transaction(
              id: 'txn_1',
              userId: 'user_1',
              accountId: 'acc_salary',
              amount: 75000.0,
              type: TransactionType.income,
              date: now,
              note: 'January Salary',
              createdAt: now,
              updatedAt: now,
            ),
          ]),
        ),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('Home Command Center & Account Breakdown Tests', () {
    testWidgets('DashboardScreen renders all key command center sections', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(child: const DashboardScreen()));
      await tester.pumpAndSettle();

      // Verify header and action bar
      expect(find.text('Smart Entry', skipOffstage: false), findsOneWidget);
      expect(
        find.text('Tell FINAURA About Your Money', skipOffstage: false),
        findsWidgets,
      );
      expect(
        find.text('Trade-Off Intelligence', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Add Transaction', skipOffstage: false), findsWidgets);

      // Section 1: Financial Position
      expect(
        find.text('Net Financial Position', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('View Breakdown', skipOffstage: false), findsOneWidget);

      // Section 2: This Month
      expect(
        find.text('This Month’s Cash Flow', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('View Analytics', skipOffstage: false), findsOneWidget);

      // Section 3: Available to Spend
      expect(
        find.text('Available to Safely Spend', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('View Budget', skipOffstage: false), findsWidgets);

      // Section 8: Future Forecast
      expect(
        find.text('Future Financial Forecast', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('View Forecast & Scenarios', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets(
      'Financial Position Breakdown modal opens and displays assets & liabilities',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestWidget(child: const FinancialPositionBreakdownDialog()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Financial Position Breakdown'), findsOneWidget);
        expect(find.text('1. Total Assets'), findsOneWidget);
        expect(find.text('2. Total Liabilities & Debt'), findsOneWidget);
        expect(find.text('Salary Account'), findsOneWidget);
        expect(find.text('Rewards Card'), findsOneWidget);
        expect(find.text('Auto Loan'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);
      },
    );

    testWidgets(
      'Forecast Breakdown dialog opens with math equation and multi-horizon table',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestWidget(child: const ForecastBreakdownDialog()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Comprehensive Financial Forecast'), findsOneWidget);
        expect(
          find.text('Authoritative Monthly Cash Flow Math'),
          findsOneWidget,
        );
        expect(find.text('Expected Income'), findsOneWidget);
        expect(find.text('Net Monthly Cash Flow'), findsOneWidget);
        expect(find.text('Future Horizons (1M, 4M, 6M, 12M)'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);
      },
    );

    testWidgets('Account Breakdown dialog opens with full traceability', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(child: AccountBreakdownDialog(account: testAccount)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Salary Account'), findsOneWidget);
      expect(find.text('Opening Balance'), findsOneWidget);
      expect(find.text('Income Inflows'), findsOneWidget);
      expect(find.text('Expenses Outflows'), findsOneWidget);
      expect(find.text('Net Transfers'), findsOneWidget);
      expect(find.text('Current Dynamic Balance'), findsOneWidget);
      expect(find.text('Edit Account'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });
}
