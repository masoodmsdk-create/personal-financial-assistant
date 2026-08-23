import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/domain/repositories/account_repository.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/services/blueprint_persistence_service.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/services/financial_situation_parser.dart';
import 'package:personal_financial_assistant/features/blueprint/presentation/providers/blueprint_providers.dart';
import 'package:personal_financial_assistant/features/blueprint/presentation/screens/financial_setup_screen.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/domain/repositories/loan_repository.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/domain/repositories/planned_expense_repository.dart';
import 'package:personal_financial_assistant/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:personal_financial_assistant/features/workspaces/presentation/providers/workspace_providers.dart';
import 'package:personal_financial_assistant/features/workspaces/workspace.dart';

class _FakePlannedExpenseRepo implements PlannedExpenseRepository {
  @override
  Future<void> createPlannedExpense(dynamic exp) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLoanRepo implements LoanRepository {
  @override
  Future<void> createLoan(dynamic loan) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAccountRepo implements AccountRepository {
  @override
  Future<void> createAccount(dynamic acc) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoalRepo implements GoalRepository {
  @override
  Future<void> createGoal(dynamic goal) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTransactionRepo implements TransactionRepository {
  @override
  Future<void> createTransaction(dynamic tx) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'FinancialSetupScreen renders header, context badge, and parse button',
    (tester) async {
      final mockWorkspace = Workspace.createDefault('user_1');
      final persistenceService = BlueprintPersistenceService(
        plannedExpenseRepo: _FakePlannedExpenseRepo(),
        loanRepo: _FakeLoanRepo(),
        accountRepo: _FakeAccountRepo(),
        goalRepo: _FakeGoalRepo(),
        transactionRepo: _FakeTransactionRepo(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountsStreamProvider.overrideWith((ref) => Stream.value([])),
            categoriesStreamProvider.overrideWith(
              (ref) => Stream.value(Category.generateDefaults('user_1')),
            ),
            loansStreamProvider.overrideWith((ref) => Stream.value([])),
            goalsStreamProvider.overrideWith((ref) => Stream.value([])),
            workspacesStreamProvider.overrideWith(
              (ref) => Stream.value([mockWorkspace]),
            ),
            activeWorkspaceProvider.overrideWithValue(mockWorkspace),
            blueprintPersistenceServiceProvider.overrideWithValue(
              persistenceService,
            ),
            blueprintControllerProvider.overrideWith(
              (ref) => BlueprintController(
                const FinancialSituationParser(),
                persistenceService,
              ),
            ),
          ],
          child: const MaterialApp(home: FinancialSetupScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tell FINAURA About Your Money'), findsOneWidget);
      expect(find.text('Parse & Build Blueprint'), findsOneWidget);
      expect(find.textContaining('Workspace Context:'), findsOneWidget);
    },
  );
}
