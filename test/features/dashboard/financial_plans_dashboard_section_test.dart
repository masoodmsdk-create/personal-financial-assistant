import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/widgets/financial_plans_dashboard_section.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/workspaces/presentation/providers/workspace_providers.dart';
import 'package:personal_financial_assistant/features/workspaces/workspace.dart';

void main() {
  testWidgets(
    'FinancialPlansDashboardSection renders loan and goal progress cards correctly',
    (tester) async {
      final now = DateTime(2026, 8, 23);
      final mockWorkspace = Workspace.createDefault('user_1');

      final testLoans = [
        Loan(
          id: 'loan_1',
          userId: 'user_1',
          name: 'Home Loan',
          type: LoanType.homeLoan,
          outstandingPrincipal: 3840000,
          interestRate: 8.5,
          emiAmount: 52000,
          remainingTenureMonths: 147,
          startDate: DateTime(2026, 1, 1),
          targetClosureDate: DateTime(2034, 3, 1),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final testGoals = [
        Goal(
          id: 'goal_1',
          userId: 'user_1',
          name: 'Emergency Fund',
          type: GoalType.emergencyFund,
          targetAmount: 500000,
          currentAmount: 200000,
          targetDate: DateTime(2027, 12, 1),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: now,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loansStreamProvider.overrideWith((ref) => Stream.value(testLoans)),
            goalsStreamProvider.overrideWith((ref) => Stream.value(testGoals)),
            transactionsStreamProvider.overrideWith((ref) => Stream.value([])),
            workspacesStreamProvider.overrideWith(
              (ref) => Stream.value([mockWorkspace]),
            ),
            activeWorkspaceProvider.overrideWithValue(mockWorkspace),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: FinancialPlansDashboardSection(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Financial Plans'), findsOneWidget);
      expect(
        find.text("How you're progressing toward your targets"),
        findsOneWidget,
      );
      expect(find.text('Home Loan'), findsAtLeastNWidgets(1));
      expect(find.text('Emergency Fund'), findsOneWidget);
      expect(find.text('View All Loans'), findsOneWidget);
      expect(find.text('View All Goals'), findsOneWidget);
    },
  );

  testWidgets(
    'FinancialPlansDashboardSection renders empty state when no plans exist',
    (tester) async {
      final mockWorkspace = Workspace.createDefault('user_1');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loansStreamProvider.overrideWith((ref) => Stream.value([])),
            goalsStreamProvider.overrideWith((ref) => Stream.value([])),
            transactionsStreamProvider.overrideWith((ref) => Stream.value([])),
            workspacesStreamProvider.overrideWith(
              (ref) => Stream.value([mockWorkspace]),
            ),
            activeWorkspaceProvider.overrideWithValue(mockWorkspace),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: FinancialPlansDashboardSection(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Financial Plans Configured'), findsOneWidget);
      expect(find.text('Add Loan'), findsOneWidget);
      expect(find.text('Add Goal'), findsOneWidget);
    },
  );
}
