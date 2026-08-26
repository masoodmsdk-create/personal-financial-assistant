import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/budgets/domain/models/budget.dart';
import 'package:personal_financial_assistant/features/budgets/domain/repositories/budget_repository.dart';
import 'package:personal_financial_assistant/features/budgets/presentation/providers/budget_providers.dart';
import 'package:personal_financial_assistant/features/budgets/presentation/screens/budget_screen.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'user_test_4';
  @override
  String? get email => 'phase4@finaura.com';
  @override
  String? get displayName => 'Phase4 Tester';
}

class _InMemoryBudgetRepository implements BudgetRepository {
  final Map<String, Budget> _storage = {};

  @override
  Future<void> createBudget(Budget budget) async {
    _storage[budget.id] = budget;
  }

  @override
  Future<void> updateBudget(Budget budget) async {
    _storage[budget.id] = budget;
  }

  @override
  Future<void> deleteBudget(String userId, String budgetId) async {
    _storage.remove(budgetId);
  }

  @override
  Stream<List<Budget>> watchBudgets(String userId, {int? year, int? month}) {
    return Stream.value(
      _storage.values.where((b) {
        if (!b.active) return false;
        if (year != null && b.year != year) return false;
        if (month != null && b.month != month) return false;
        return true;
      }).toList(),
    );
  }

  @override
  Future<List<Budget>> getBudgets(
    String userId, {
    int? year,
    int? month,
  }) async {
    return _storage.values.where((b) {
      if (!b.active) return false;
      if (year != null && b.year != year) return false;
      if (month != null && b.month != month) return false;
      return true;
    }).toList();
  }
}

void main() {
  final now = DateTime(2026, 8, 15);
  final categories = [
    ...Category.generateDefaults('user_test_4'),
    Category(
      id: 'cat_groceries',
      userId: 'user_test_4',
      name: 'Groceries',
      type: CategoryType.expense,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  group('MSD FINAURA — Phase 4 Real-Data Acceptance Tests', () {
    testWidgets('1. Budget Creation & Budget vs Actual Calculation Flow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _InMemoryBudgetRepository();

      // Initial budget of ₹8,000 for Groceries
      final initialBudget = Budget(
        id: 'b_groc',
        userId: 'user_test_4',
        createdAt: now,
        updatedAt: now,
        year: 2026,
        month: 8,
        categoryId: 'cat_groceries',
        plannedAmount: 8000.0,
        active: true,
      );
      repo._storage['b_groc'] = initialBudget;

      // Actual spending: ₹5,500
      final tx1 = Transaction(
        id: 'tx_groc_1',
        userId: 'user_test_4',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.expense,
        amount: 5500.0,
        date: DateTime(2026, 8, 10),
        categoryId: 'cat_groceries',
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => _FakeUser()),
          budgetRepositoryProvider.overrideWithValue(repo),
          budgetsStreamProvider.overrideWith(
            (ref) => repo.watchBudgets('user_test_4'),
          ),
          transactionsStreamProvider.overrideWith((ref) => Stream.value([tx1])),
          categoriesStreamProvider.overrideWith(
            (ref) => Stream.value(categories),
          ),
          recurringTransactionsStreamProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          plannedExpensesStreamProvider.overrideWith((ref) => Stream.value([])),
          monthlyOverridesStreamProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          loansStreamProvider.overrideWith((ref) => Stream.value([])),
          selectedBudgetMonthProvider.overrideWith((ref) => DateTime(2026, 8)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: BudgetScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Budget Screen shows ₹8,000 planned, ₹5,500 actual, ₹2,500 remaining, 69% used
      expect(find.text('Budget & Cash-Flow Planning'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('₹8000'), findsWidgets);
      expect(find.text('₹5500'), findsWidgets);
      expect(find.text('₹2500'), findsWidgets);
      expect(find.textContaining('% Used'), findsWidgets);
    });

    testWidgets(
      '2. Over-Budget Result Flow (Additional ₹4,000 -> ₹9,500 Total)',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = _InMemoryBudgetRepository();
        repo._storage['b_groc'] = Budget(
          id: 'b_groc',
          userId: 'user_test_4',
          createdAt: now,
          updatedAt: now,
          year: 2026,
          month: 8,
          categoryId: 'cat_groceries',
          plannedAmount: 8000.0,
          active: true,
        );

        // Spend ₹5,500 + ₹4,000 = ₹9,500
        final txs = [
          Transaction(
            id: 'tx_groc_1',
            userId: 'user_test_4',
            createdAt: now,
            updatedAt: now,
            type: TransactionType.expense,
            amount: 5500.0,
            date: DateTime(2026, 8, 10),
            categoryId: 'cat_groceries',
          ),
          Transaction(
            id: 'tx_groc_2',
            userId: 'user_test_4',
            createdAt: now,
            updatedAt: now,
            type: TransactionType.expense,
            amount: 4000.0,
            date: DateTime(2026, 8, 14),
            categoryId: 'cat_groceries',
          ),
        ];

        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _FakeUser()),
            budgetRepositoryProvider.overrideWithValue(repo),
            budgetsStreamProvider.overrideWith(
              (ref) => repo.watchBudgets('user_test_4'),
            ),
            transactionsStreamProvider.overrideWith((ref) => Stream.value(txs)),
            categoriesStreamProvider.overrideWith(
              (ref) => Stream.value(categories),
            ),
            recurringTransactionsStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            plannedExpensesStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            monthlyOverridesStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            loansStreamProvider.overrideWith((ref) => Stream.value([])),
            selectedBudgetMonthProvider.overrideWith(
              (ref) => DateTime(2026, 8),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: BudgetScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Over-Budget state: Actual ₹9,500, Remaining -₹1,500, Badge "OVER BY ₹1500"
        expect(find.text('₹9500'), findsWidgets);
        expect(find.text('₹-1500'), findsWidgets);
        expect(find.text('OVER BY ₹1500'), findsOneWidget);
      },
    );

    testWidgets('3. Available-to-Spend Controlled Scenario Verification', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Scenario:
      // Expected Income: ₹80,000 (Recurring)
      // Recurring Expenses: ₹15,000
      // Planned Expenses: ₹5,000
      // Budgeted Variable: ₹20,000
      // Expected Available to Spend: ₹80,000 - ₹15,000 - ₹5,000 - ₹20,000 = ₹40,000

      final recurringSalary = RecurringTransactionRule(
        id: 'rule_sal',
        userId: 'user_test_4',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.income,
        name: 'Salary',
        amount: 80000.0,
        categoryId: 'cat_salary',
        accountId: 'acc_bank',
        frequency: RecurrenceFrequency.monthly,
        startDate: now,
        nextOccurrence: now,
        active: true,
      );

      final recurringRent = RecurringTransactionRule(
        id: 'rule_rent',
        userId: 'user_test_4',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.expense,
        name: 'Rent',
        amount: 15000.0,
        categoryId: 'cat_rent',
        accountId: 'acc_bank',
        frequency: RecurrenceFrequency.monthly,
        startDate: now,
        nextOccurrence: now,
        active: true,
      );

      final plannedMaintenance = PlannedExpense(
        id: 'plan_maint',
        userId: 'user_test_4',
        createdAt: now,
        updatedAt: now,
        name: 'Society Maintenance',
        defaultAmount: 5000.0,
        frequency: RecurrenceFrequency.monthly,
        startDate: now,
        categoryId: 'cat_housing',
        active: true,
      );

      final variableBudgets = [
        Budget(
          id: 'b_var_1',
          userId: 'user_test_4',
          createdAt: now,
          updatedAt: now,
          year: 2026,
          month: 8,
          categoryId: 'cat_groceries',
          plannedAmount: 12000.0,
          active: true,
        ),
        Budget(
          id: 'b_var_2',
          userId: 'user_test_4',
          createdAt: now,
          updatedAt: now,
          year: 2026,
          month: 8,
          categoryId: 'cat_dining',
          plannedAmount: 8000.0,
          active: true,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => _FakeUser()),
          budgetsStreamProvider.overrideWith(
            (ref) => Stream.value(variableBudgets),
          ),
          transactionsStreamProvider.overrideWith((ref) => Stream.value([])),
          categoriesStreamProvider.overrideWith(
            (ref) => Stream.value(categories),
          ),
          recurringTransactionsStreamProvider.overrideWith(
            (ref) => Stream.value([recurringSalary, recurringRent]),
          ),
          plannedExpensesStreamProvider.overrideWith(
            (ref) => Stream.value([plannedMaintenance]),
          ),
          monthlyOverridesStreamProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          loansStreamProvider.overrideWith((ref) => Stream.value([])),
          selectedBudgetMonthProvider.overrideWith((ref) => DateTime(2026, 8)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: BudgetScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final plan = container.read(monthlyCashFlowPlanProvider);
      expect(plan.expectedIncome, 80000.0);
      expect(plan.recurringCommitments, 15000.0);
      expect(plan.plannedExpenses, 5000.0);
      expect(plan.totalCommittedExpenses, 20000.0);
      expect(plan.budgetedVariableExpenses, 20000.0);
      expect(plan.availableToSpend, 40000.0);

      // UI explains calculation
      expect(find.text('AVAILABLE TO SPEND'), findsOneWidget);
      expect(find.text('₹40000'), findsOneWidget);
      expect(find.textContaining('Expected Income: '), findsOneWidget);
      expect(find.textContaining('+₹80000'), findsOneWidget);
      expect(find.textContaining('Committed Fixed: '), findsOneWidget);
      expect(find.textContaining('Budgeted Variable: '), findsOneWidget);
      expect(find.textContaining('-₹20000'), findsNWidgets(2));
    });

    testWidgets(
      '4. Month Switching Isolation (August budget does NOT appear in September)',
      (tester) async {
        final repo = _InMemoryBudgetRepository();
        // August budget
        repo._storage['b_aug'] = Budget(
          id: 'b_aug',
          userId: 'user_test_4',
          createdAt: now,
          updatedAt: now,
          year: 2026,
          month: 8,
          categoryId: 'cat_groceries',
          plannedAmount: 8000.0,
          active: true,
        );

        final container = ProviderContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => _FakeUser()),
            budgetRepositoryProvider.overrideWithValue(repo),
            budgetsStreamProvider.overrideWith(
              (ref) => repo.watchBudgets('user_test_4'),
            ),
            transactionsStreamProvider.overrideWith((ref) => Stream.value([])),
            categoriesStreamProvider.overrideWith(
              (ref) => Stream.value(categories),
            ),
            recurringTransactionsStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            plannedExpensesStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            monthlyOverridesStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            loansStreamProvider.overrideWith((ref) => Stream.value([])),
            selectedBudgetMonthProvider.overrideWith(
              (ref) => DateTime(2026, 8),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: BudgetScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // In August: shows Groceries budget
        expect(find.text('August 2026'), findsOneWidget);
        expect(find.text('Groceries'), findsOneWidget);

        // Tap next month (September)
        final nextBtn = find.byTooltip('Next Month');
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();

        // In September: August budget does NOT show
        expect(find.text('September 2026'), findsOneWidget);
        expect(find.text('No Category Budgets Set'), findsOneWidget);
      },
    );

    testWidgets('5. Edit and Delete Budget Workflows with Visible Buttons', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _InMemoryBudgetRepository();
      repo._storage['b_edit'] = Budget(
        id: 'b_edit',
        userId: 'user_test_4',
        createdAt: now,
        updatedAt: now,
        year: 2026,
        month: 8,
        categoryId: 'cat_groceries',
        plannedAmount: 8000.0,
        active: true,
      );

      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => _FakeUser()),
          budgetRepositoryProvider.overrideWithValue(repo),
          budgetsStreamProvider.overrideWith(
            (ref) => repo.watchBudgets('user_test_4'),
          ),
          transactionsStreamProvider.overrideWith((ref) => Stream.value([])),
          categoriesStreamProvider.overrideWith(
            (ref) => Stream.value(categories),
          ),
          recurringTransactionsStreamProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          plannedExpensesStreamProvider.overrideWith((ref) => Stream.value([])),
          monthlyOverridesStreamProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          loansStreamProvider.overrideWith((ref) => Stream.value([])),
          selectedBudgetMonthProvider.overrideWith((ref) => DateTime(2026, 8)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: BudgetScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Edit budget to ₹10,000
      final menuBtn = find.byType(PopupMenuButton<String>);
      await tester.tap(menuBtn);
      await tester.pumpAndSettle();

      final editItem = find.text('Edit Budget');
      await tester.tap(editItem);
      await tester.pumpAndSettle();

      expect(find.text('Edit Budget'), findsWidgets);
      final amountField = find.byType(TextFormField).first;
      await tester.enterText(amountField, '10000');
      await tester.pumpAndSettle();

      final saveBtn = find.widgetWithText(FilledButton, 'Save Budget');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(repo._storage['b_edit']!.plannedAmount, 10000.0);

      // 2. Delete budget with confirmation dialog
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      final deleteItem = find.text('Delete Budget');
      await tester.tap(deleteItem);
      await tester.pumpAndSettle();

      expect(find.text('Delete Budget?'), findsOneWidget);
      final confirmDeleteBtn = find.widgetWithText(FilledButton, 'Delete');
      await tester.tap(confirmDeleteBtn);
      await tester.pumpAndSettle();

      expect(repo._storage.containsKey('b_edit'), isFalse);
    });
  });
}
