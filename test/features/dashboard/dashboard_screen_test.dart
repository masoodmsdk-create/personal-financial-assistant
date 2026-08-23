import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/domain/models/account_type_definition.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';
import 'package:personal_financial_assistant/features/workspaces/presentation/providers/workspace_providers.dart';
import 'package:personal_financial_assistant/features/workspaces/workspace.dart';

void main() {
  final now = DateTime.now();
  final mockWorkspace = Workspace.createDefault('u1').copyWith(
    name: 'Family Finances',
    purpose: 'Pay off home loan faster and build emergency fund.',
  );

  final List<Account> testAccounts = [
    Account(
      id: 'acc_hdfc',
      userId: 'u1',
      createdAt: now,
      updatedAt: now,
      name: 'HDFC Bank',
      type: AccountType.bank,
      nature: AccountNature.asset,
      openingBalance: 150000.0,
      currency: 'INR',
      active: true,
    ),
  ];

  final List<Category> testCategories = [
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

  final List<Transaction> testTransactions = [
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

  final List<Loan> testLoans = [
    Loan(
      id: 'loan_1',
      userId: 'u1',
      name: 'Home Loan',
      type: LoanType.homeLoan,
      originalPrincipal: 5000000.0,
      outstandingPrincipal: 3840000.0,
      interestRate: 8.5,
      remainingTenureMonths: 147,
      emiAmount: 52000.0,
      nextEmiDate: DateTime(now.year, now.month, 15),
      createdAt: now,
      updatedAt: now,
    ),
  ];

  final List<Goal> testGoals = [
    Goal(
      id: 'goal_1',
      userId: 'u1',
      name: 'Emergency Fund',
      type: GoalType.emergencyFund,
      targetAmount: 500000.0,
      currentAmount: 200000.0,
      targetDate: DateTime(now.year + 1, 12, 1),
      createdAt: now,
      updatedAt: now,
    ),
  ];

  testWidgets('DashboardScreen renders all Financial Command Center sections', (
    WidgetTester tester,
  ) async {
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
          plannedExpensesStreamProvider.overrideWith((ref) => Stream.value([])),
          monthlyOverridesStreamProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          loansStreamProvider.overrideWith((ref) => Stream.value(testLoans)),
          goalsStreamProvider.overrideWith((ref) => Stream.value(testGoals)),
          workspacesStreamProvider.overrideWith(
            (ref) => Stream.value([mockWorkspace]),
          ),
          activeWorkspaceProvider.overrideWithValue(mockWorkspace),
        ],
        child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
      ),
    );

    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    // 1. Workspace Header
    expect(find.text('Family Finances'), findsOneWidget);

    // 2. Section 1: Financial Situation
    expect(find.text('Current Financial Situation'), findsOneWidget);
    expect(find.text('Total Net Balance'), findsOneWidget);
    expect(find.text('Monthly Income'), findsOneWidget);
    expect(find.text('Monthly Expenses'), findsOneWidget);
    expect(find.text('Remaining Cash Flow'), findsOneWidget);
    expect(find.textContaining('Accounts Overview'), findsOneWidget);

    // 3. Section 2 & 3: Financial Plans & Progress
    expect(find.text('Financial Plans'), findsOneWidget);

    // 4. Section 4: FINAURA Suggests
    expect(find.text('FINAURA Suggests'), findsOneWidget);

    // 5. Section 5: Upcoming Reminders
    expect(find.text('Upcoming'), findsOneWidget);

    // 6. Section 6: Recent Activity
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
  });

  testWidgets('DashboardScreen renders empty state gracefully without errors', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          transactionsStreamProvider.overrideWith((ref) => Stream.value([])),
          accountsStreamProvider.overrideWith((ref) => Stream.value([])),
          categoriesStreamProvider.overrideWith((ref) => Stream.value([])),
          plannedExpensesStreamProvider.overrideWith((ref) => Stream.value([])),
          monthlyOverridesStreamProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          loansStreamProvider.overrideWith((ref) => Stream.value([])),
          goalsStreamProvider.overrideWith((ref) => Stream.value([])),
          workspacesStreamProvider.overrideWith(
            (ref) => Stream.value([mockWorkspace]),
          ),
          activeWorkspaceProvider.overrideWithValue(mockWorkspace),
        ],
        child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
      ),
    );

    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    expect(find.text('Current Financial Situation'), findsOneWidget);
    expect(find.text('FINAURA Suggests'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.text('No recent activity'), findsOneWidget);
  });
}
