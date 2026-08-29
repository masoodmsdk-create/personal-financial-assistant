import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/core/routing/app_router.dart';
import 'package:personal_financial_assistant/features/accounts/domain/repositories/account_repository.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/services/blueprint_persistence_service.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/services/financial_situation_parser.dart';
import 'package:personal_financial_assistant/features/blueprint/presentation/providers/blueprint_providers.dart';
import 'package:personal_financial_assistant/features/budgets/presentation/providers/budget_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/domain/repositories/loan_repository.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/domain/repositories/planned_expense_repository.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/workspaces/presentation/providers/workspace_providers.dart';
import 'package:personal_financial_assistant/features/workspaces/workspace.dart';

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'u1';
  @override
  String? get email => 'test@finaura.com';
  @override
  String? get displayName => 'Test User';
}

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

class _FakeRecurringRepo implements RecurringTransactionRepository {
  @override
  Future<void> createRecurringTransaction(dynamic rule) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final fakeUser = _FakeUser();
  final mockWorkspace = Workspace.createDefault('u1');

  testWidgets(
    'Direct route navigation resolves successfully for all key app destinations',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final persistenceService = BlueprintPersistenceService(
        accountRepo: _FakeAccountRepo(),
        loanRepo: _FakeLoanRepo(),
        plannedExpenseRepo: _FakePlannedExpenseRepo(),
        goalRepo: _FakeGoalRepo(),
        recurringRepo: _FakeRecurringRepo(),
        transactionRepo: _FakeTransactionRepo(),
      );

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(fakeUser),
          ),
          currentUserProvider.overrideWith((ref) => fakeUser),
          workspacesStreamProvider.overrideWith(
            (ref) => Stream.value([mockWorkspace]),
          ),
          activeWorkspaceProvider.overrideWithValue(mockWorkspace),
          accountsStreamProvider.overrideWith((ref) => Stream.value([])),
          transactionsStreamProvider.overrideWith((ref) => Stream.value([])),
          recurringTransactionsStreamProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          loansStreamProvider.overrideWith((ref) => Stream.value([])),
          goalsStreamProvider.overrideWith((ref) => Stream.value([])),
          budgetsStreamProvider.overrideWith((ref) => Stream.value([])),
          plannedExpensesStreamProvider.overrideWith((ref) => Stream.value([])),
          monthlyOverridesStreamProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          categoriesStreamProvider.overrideWith((ref) => Stream.value([])),
          incomeCategoriesProvider.overrideWith(
            (ref) => const AsyncValue.data(<Category>[]),
          ),
          expenseCategoriesProvider.overrideWith(
            (ref) => const AsyncValue.data(<Category>[]),
          ),
          accountTypesStreamProvider.overrideWith((ref) => Stream.value([])),
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
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify 5 Primary Pillar Destinations
      router.go('/home');
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/home');

      router.go('/money');
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/money');

      router.go('/plans');
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/plans');

      router.go('/insights');
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/insights');

      router.go('/settings');
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/settings');

      // 2. Verify Canonical Redirects
      router.go('/dashboard');
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/home');

      // 3. Verify Legacy Sub-Route Redirects into Pillars
      router.go('/accounts');
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/money');
      expect(
        router.routerDelegate.currentConfiguration.uri.queryParameters['tab'],
        '0',
      );

      router.go('/transactions');
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/money');
      expect(
        router.routerDelegate.currentConfiguration.uri.queryParameters['tab'],
        '1',
      );

      router.go('/recurring-transactions');
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/money');
      expect(
        router.routerDelegate.currentConfiguration.uri.queryParameters['tab'],
        '2',
      );

      router.go('/budgets');
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/plans');
      expect(
        router.routerDelegate.currentConfiguration.uri.queryParameters['tab'],
        '0',
      );

      router.go('/goals');
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/plans');
      expect(
        router.routerDelegate.currentConfiguration.uri.queryParameters['tab'],
        '1',
      );

      router.go('/loans');
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/plans');
      expect(
        router.routerDelegate.currentConfiguration.uri.queryParameters['tab'],
        '2',
      );

      router.go('/analytics');
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/insights');
      expect(
        router.routerDelegate.currentConfiguration.uri.queryParameters['tab'],
        '0',
      );

      router.go('/monthly-review');
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/insights');
      expect(
        router.routerDelegate.currentConfiguration.uri.queryParameters['tab'],
        '1',
      );

      router.go('/forecast');
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/insights');
      expect(
        router.routerDelegate.currentConfiguration.uri.queryParameters['tab'],
        '2',
      );

      // 4. Verify Standalone Utility / Modal Routes
      final secondaryRoutes = [
        '/trade-off',
        '/categories',
        '/account-types',
        '/smart-entry',
        '/planned-expenses',
        '/financial-setup',
      ];

      for (final route in secondaryRoutes) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.uri.path, route);
      }
    },
  );
}
