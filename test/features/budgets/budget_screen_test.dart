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
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'user_1';
  @override
  String? get email => 'test@finaura.com';
  @override
  String? get displayName => 'Test User';
}

class _RecordingBudgetRepo implements BudgetRepository {
  final List<Budget> budgets = [];

  @override
  Future<void> createBudget(Budget budget) async {
    budgets.add(budget);
  }

  @override
  Future<void> updateBudget(Budget budget) async {
    final idx = budgets.indexWhere((b) => b.id == budget.id);
    if (idx != -1) budgets[idx] = budget;
  }

  @override
  Future<void> deleteBudget(String userId, String budgetId) async {
    budgets.removeWhere((b) => b.id == budgetId);
  }

  @override
  Stream<List<Budget>> watchBudgets(String userId, {int? year, int? month}) {
    return Stream.value(budgets);
  }

  @override
  Future<List<Budget>> getBudgets(
    String userId, {
    int? year,
    int? month,
  }) async {
    return budgets;
  }
}

void main() {
  final now = DateTime(2026, 8, 1);
  final testCategories = [
    ...Category.generateDefaults('user_1'),
    Category(
      id: 'cat_groceries',
      userId: 'user_1',
      name: 'Groceries',
      type: CategoryType.expense,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  Widget createTestWidget({
    List<Budget> budgets = const [],
    List<Transaction> transactions = const [],
    BudgetRepository? repo,
  }) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => _FakeUser()),
        budgetRepositoryProvider.overrideWithValue(
          repo ?? _RecordingBudgetRepo(),
        ),
        budgetsStreamProvider.overrideWith((ref) => Stream.value(budgets)),
        transactionsStreamProvider.overrideWith(
          (ref) => Stream.value(transactions),
        ),
        categoriesStreamProvider.overrideWith(
          (ref) => Stream.value(testCategories),
        ),
        recurringTransactionsStreamProvider.overrideWith(
          (ref) => Stream.value([]),
        ),
        plannedExpensesStreamProvider.overrideWith((ref) => Stream.value([])),
        monthlyOverridesStreamProvider.overrideWith((ref) => Stream.value([])),
        loansStreamProvider.overrideWith((ref) => Stream.value([])),
        selectedBudgetMonthProvider.overrideWith((ref) => DateTime(2026, 8)),
      ],
      child: const MaterialApp(home: BudgetScreen()),
    );
  }

  group('BudgetScreen Widget Tests', () {
    testWidgets(
      'Renders empty state with action buttons when budgets are empty',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget(budgets: []));
        await tester.pumpAndSettle();

        expect(find.text('Budget & Cash-Flow Planning'), findsOneWidget);
        expect(find.text('August 2026'), findsOneWidget);
        expect(find.text('AVAILABLE TO SPEND'), findsOneWidget);
        expect(find.text('No Category Budgets Set'), findsOneWidget);
        expect(find.text('Set First Category Budget'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Add Budget'), findsOneWidget);
      },
    );

    testWidgets('Renders budget cards, metrics, and progress when populated', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final budgets = [
        Budget(
          id: 'b_groc',
          userId: 'user_1',
          createdAt: now,
          updatedAt: now,
          year: 2026,
          month: 8,
          categoryId: 'cat_groceries',
          plannedAmount: 8000.0,
          active: true,
        ),
      ];

      final transactions = [
        Transaction(
          id: 'tx_1',
          userId: 'user_1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.expense,
          amount: 5000.0,
          date: DateTime(2026, 8, 10),
          categoryId: 'cat_groceries',
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(budgets: budgets, transactions: transactions),
      );
      await tester.pumpAndSettle();

      expect(find.text('Total Budgeted'), findsOneWidget);
      expect(find.text('₹8000'), findsWidgets);
      expect(find.text('Actual Spent'), findsOneWidget);
      expect(find.text('₹5000'), findsWidgets);
      expect(find.text('Remaining Budget'), findsOneWidget);
      expect(find.text('₹3000'), findsWidgets);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.textContaining('% Used'), findsWidgets);
    });

    testWidgets(
      'Add budget dialog renders mandatory action buttons and submits',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final recRepo = _RecordingBudgetRepo();

        await tester.pumpWidget(createTestWidget(repo: recRepo));
        await tester.pumpAndSettle();

        // Tap header Add Budget
        final addBtn = find.widgetWithText(FilledButton, 'Add Budget');
        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        // Dialog is displayed
        expect(find.text('Set Category Budget'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Save Budget'), findsOneWidget);

        // Enter amount
        final amountField = find.byType(TextFormField).first;
        await tester.enterText(amountField, '7500');
        await tester.pumpAndSettle();

        // Tap Save Budget
        final saveBtn = find.widgetWithText(FilledButton, 'Save Budget');
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Assert persisted
        expect(recRepo.budgets.length, 1);
        expect(recRepo.budgets.first.plannedAmount, 7500.0);
      },
    );

    // Responsive multi-viewport verification
    for (final size in [
      const Size(360, 800),
      const Size(390, 844),
      const Size(430, 932),
      const Size(1280, 800),
    ]) {
      testWidgets(
        'Renders cleanly on ${size.width}x${size.height} without overflow',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final budgets = [
            Budget(
              id: 'b_groc',
              userId: 'user_1',
              createdAt: now,
              updatedAt: now,
              year: 2026,
              month: 8,
              categoryId: 'cat_groceries',
              plannedAmount: 8000.0,
              active: true,
            ),
          ];

          await tester.pumpWidget(createTestWidget(budgets: budgets));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Budget & Cash-Flow Planning'), findsOneWidget);
        },
      );
    }
  });
}
