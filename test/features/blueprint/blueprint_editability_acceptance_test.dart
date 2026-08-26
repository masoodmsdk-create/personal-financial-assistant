import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/domain/repositories/account_repository.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/models/financial_blueprint.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/services/blueprint_persistence_service.dart';
import 'package:personal_financial_assistant/features/blueprint/presentation/providers/blueprint_providers.dart';
import 'package:personal_financial_assistant/features/blueprint/presentation/screens/financial_setup_screen.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/domain/repositories/loan_repository.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/domain/repositories/planned_expense_repository.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';
import 'package:personal_financial_assistant/features/workspaces/presentation/providers/workspace_providers.dart';
import 'package:personal_financial_assistant/features/workspaces/workspace.dart';

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'user_test_blueprint';
  @override
  String? get email => 'test@example.com';
  @override
  String? get displayName => 'Tester';
}

class _DummyRecurringRepo implements RecurringTransactionRepository {
  final List<RecurringTransactionRule> rules = [];
  @override
  Future<void> createRecurringTransaction(RecurringTransactionRule rule) async {
    rules.add(rule);
  }

  @override
  Future<void> updateRecurringTransaction(
    RecurringTransactionRule rule,
  ) async {}
  @override
  Future<void> deleteRecurringTransaction(String userId, String ruleId) async {
    rules.removeWhere((r) => r.id == ruleId);
  }

  @override
  Future<void> toggleRecurringTransactionStatus(
    String userId,
    String ruleId,
    bool active,
  ) async {}
  @override
  Stream<List<RecurringTransactionRule>> getRecurringTransactions(
    String userId,
  ) => Stream.value(rules);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyPlannedExpenseRepo implements PlannedExpenseRepository {
  @override
  Future<void> createPlannedExpense(dynamic exp) async {}
  @override
  Future<void> updatePlannedExpense(dynamic exp) async {}
  @override
  Future<void> archivePlannedExpense({
    required String userId,
    required String planId,
  }) async {}
  @override
  Stream<List<PlannedExpense>> watchPlannedExpenses(String userId) =>
      Stream.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyLoanRepo implements LoanRepository {
  @override
  Future<void> createLoan(dynamic loan) async {}
  @override
  Future<void> updateLoan(dynamic loan) async {}
  @override
  Future<void> deleteLoan({
    required String userId,
    required String loanId,
  }) async {}
  @override
  Stream<List<Loan>> watchLoans(String userId) => Stream.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyAccountRepo implements AccountRepository {
  @override
  Future<void> createAccount(dynamic acc) async {}
  @override
  Future<void> updateAccount(dynamic acc) async {}
  @override
  Future<void> deleteAccount({
    required String userId,
    required String accountId,
  }) async {}
  @override
  Stream<List<Account>> watchAccounts(String userId) => Stream.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyGoalRepo implements GoalRepository {
  @override
  Future<void> createGoal(dynamic goal) async {}
  @override
  Future<void> updateGoal(dynamic goal) async {}
  @override
  Future<void> deleteGoal({
    required String userId,
    required String goalId,
  }) async {}
  @override
  Stream<List<Goal>> watchGoals(String userId) => Stream.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyTransactionRepo implements TransactionRepository {
  @override
  Future<void> createTransaction(dynamic tx) async {}
  @override
  Stream<List<Transaction>> watchTransactions(
    String userId, {
    TransactionType? type,
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) => Stream.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime(2026, 8, 1);

  final testWorkspace = Workspace(
    id: 'ws_default',
    userId: 'user_test_blueprint',
    name: 'Personal Space',
    purpose: 'Personal Wealth',
    createdAt: now,
    updatedAt: now,
  );

  final defaultCategories = Category.generateDefaults('user_test_blueprint');

  final testAccount = Account(
    id: 'acc_bank',
    userId: 'user_test_blueprint',
    name: 'HDFC Main',
    type: AccountType.bank,
    openingBalance: 200000.0,
    currency: 'INR',
    active: true,
    createdAt: now,
    updatedAt: now,
  );

  List<Override> buildOverrides({
    List<RecurringTransactionRule> recurringRules = const [],
    List<PlannedExpense> plannedExpenses = const [],
    List<Account> accounts = const [],
    List<Loan> loans = const [],
    List<Goal> goals = const [],
  }) {
    return [
      currentUserProvider.overrideWith((ref) => _FakeUser()),
      workspacesStreamProvider.overrideWith(
        (ref) => Stream.value([testWorkspace]),
      ),
      activeWorkspaceProvider.overrideWith((ref) => testWorkspace),
      categoriesStreamProvider.overrideWith(
        (ref) => Stream.value(defaultCategories),
      ),
      accountsStreamProvider.overrideWith((ref) => Stream.value(accounts)),
      recurringTransactionsStreamProvider.overrideWith(
        (ref) => Stream.value(recurringRules),
      ),
      plannedExpensesStreamProvider.overrideWith(
        (ref) => Stream.value(plannedExpenses),
      ),
      loansStreamProvider.overrideWith((ref) => Stream.value(loans)),
      goalsStreamProvider.overrideWith((ref) => Stream.value(goals)),
      recurringTransactionRepositoryProvider.overrideWith(
        (ref) => _DummyRecurringRepo(),
      ),
      plannedExpenseRepositoryProvider.overrideWith(
        (ref) => _DummyPlannedExpenseRepo(),
      ),
      loanRepositoryProvider.overrideWith((ref) => _DummyLoanRepo()),
      accountRepositoryProvider.overrideWith((ref) => _DummyAccountRepo()),
      goalRepositoryProvider.overrideWith((ref) => _DummyGoalRepo()),
      transactionRepositoryProvider.overrideWith(
        (ref) => _DummyTransactionRepo(),
      ),
      blueprintPersistenceServiceProvider.overrideWith(
        (ref) => BlueprintPersistenceService(
          plannedExpenseRepo: _DummyPlannedExpenseRepo(),
          loanRepo: _DummyLoanRepo(),
          accountRepo: _DummyAccountRepo(),
          goalRepo: _DummyGoalRepo(),
          transactionRepo: _DummyTransactionRepo(),
          recurringRepo: _DummyRecurringRepo(),
        ),
      ),
    ];
  }

  group('MSD FINAURA — Your Money Blueprint UX & Editability Tests', () {
    testWidgets(
      '1. Blueprint Creation, Save Button Visibility & Accessibility',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer(
          overrides: buildOverrides(accounts: [testAccount]),
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: FinancialSetupScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Enter financial input text
        final inputField = find.byType(TextField);
        expect(inputField, findsOneWidget);
        await tester.enterText(
          inputField,
          'Salary ₹1,00,000, rent ₹20,000, groceries ₹8,000, car loan EMI ₹15,000',
        );
        await tester.pump();

        // Tap visible "Parse & Build Blueprint"
        final parseButton = find.widgetWithText(
          FilledButton,
          'Parse & Build Blueprint',
        );
        expect(parseButton, findsOneWidget);
        await tester.tap(parseButton);
        await tester.pumpAndSettle();

        // Verify draft sections appear
        expect(find.text('Extracted Blueprint Overview'), findsOneWidget);
        expect(find.text('Income Sources'), findsOneWidget);
        expect(find.text('Recurring Living Expenses'), findsOneWidget);
        expect(find.text('Loans & Commitments'), findsOneWidget);

        // Verify explicit single primary "Save Blueprint" button in PageHeader
        final saveButton = find.widgetWithText(FilledButton, 'Save Blueprint');
        expect(saveButton, findsOneWidget);
      },
    );

    testWidgets(
      '2. Edit Draft Income and Expense Items with Type-Change (Income <-> Expense)',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final draftBlueprint = FinancialBlueprint(
          id: 'bp_draft_1',
          rawInput: 'Salary 80000, Rent 15000',
          incomes: [
            const BlueprintIncomeItem(
              id: 'inc_1',
              label: 'Salary',
              monthlyAmount: 80000.0,
              sourceText: 'Salary 80000',
            ),
          ],
          recurringExpenses: [
            const BlueprintExpenseItem(
              id: 'exp_1',
              categoryName: 'Rent',
              monthlyAmount: 15000.0,
              sourceText: 'Rent 15000',
            ),
          ],
        );

        final container = ProviderContainer(
          overrides: buildOverrides(accounts: [testAccount]),
        );
        addTearDown(container.dispose);

        // Set blueprint in controller
        container.read(blueprintControllerProvider.notifier).state =
            BlueprintState(blueprint: draftBlueprint);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: FinancialSetupScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Edit buttons exist
        final editButtons = find.byTooltip('Edit Item');
        expect(editButtons, findsNWidgets(2));

        // 1. Edit Income: change Salary ₹80,000 -> ₹90,000
        await tester.ensureVisible(editButtons.first);
        await tester.pumpAndSettle();
        await tester.tap(editButtons.first);
        await tester.pumpAndSettle();

        expect(find.text('Edit Income Item'), findsOneWidget);
        final amountField = find.widgetWithText(
          TextFormField,
          'Monthly Amount (₹) *',
        );
        await tester.enterText(amountField, '90000');
        await tester.pump();

        final saveChangesButton = find.widgetWithText(
          FilledButton,
          'Save Changes',
        );
        expect(saveChangesButton, findsOneWidget);
        await tester.tap(saveChangesButton);
        await tester.pumpAndSettle();

        expect(find.text('₹90,000/mo'), findsOneWidget);

        // 2. Type Change: Edit Rent (Expense) and change Type to Income (Rental Income ₹25,000)
        final expenseEditButton = find.byTooltip('Edit Item').last;
        await tester.ensureVisible(expenseEditButton);
        await tester.pumpAndSettle();
        await tester.tap(expenseEditButton);
        await tester.pumpAndSettle();

        expect(find.text('Edit Expense Item'), findsOneWidget);
        // Change type dropdown from Expense to Income
        final typeDropdown = find.byType(DropdownButtonFormField<String>);
        await tester.tap(typeDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Income').last);
        await tester.pumpAndSettle();

        final nameField = find.widgetWithText(
          TextFormField,
          'Category / Expense Name *',
        );
        await tester.enterText(nameField, 'Rental Income');
        final expAmountField = find.widgetWithText(
          TextFormField,
          'Monthly Amount (₹) *',
        );
        await tester.enterText(expAmountField, '25000');
        await tester.pump();

        await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
        await tester.pumpAndSettle();

        // Verify that Rent is now listed under Income Sources!
        expect(find.text('Rental Income'), findsOneWidget);
        expect(find.text('₹25,000/mo'), findsOneWidget);
        // Incomes count should now be 2
        expect(find.text('Income Sources'), findsOneWidget);
      },
    );

    testWidgets('3. Delete Draft Item with Confirmation Dialog', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final draftBlueprint = FinancialBlueprint(
        id: 'bp_draft_del',
        rawInput: 'Salary 80000, Gym 2000',
        incomes: [
          const BlueprintIncomeItem(
            id: 'inc_1',
            label: 'Salary',
            monthlyAmount: 80000.0,
            sourceText: 'Salary 80000',
          ),
        ],
        recurringExpenses: [
          const BlueprintExpenseItem(
            id: 'exp_1',
            categoryName: 'Gym Membership',
            monthlyAmount: 2000.0,
            sourceText: 'Gym 2000',
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: buildOverrides(accounts: [testAccount]),
      );
      addTearDown(container.dispose);

      container.read(blueprintControllerProvider.notifier).state =
          BlueprintState(blueprint: draftBlueprint);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: FinancialSetupScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Delete on Gym Membership
      final deleteButtons = find.byTooltip('Delete Item');
      expect(deleteButtons, findsNWidgets(2));
      await tester.ensureVisible(deleteButtons.last);
      await tester.pumpAndSettle();
      await tester.tap(deleteButtons.last);
      await tester.pumpAndSettle();

      // Confirmation dialog must appear
      expect(find.text('Delete Blueprint Item'), findsOneWidget);
      expect(
        find.text('Are you sure you want to remove "Gym Membership"?'),
        findsOneWidget,
      );

      // Tap Confirm Delete
      final confirmDeleteBtn = find.widgetWithText(FilledButton, 'Delete');
      expect(confirmDeleteBtn, findsOneWidget);
      await tester.tap(confirmDeleteBtn);
      await tester.pumpAndSettle();

      // Gym Membership is removed
      expect(find.text('Gym Membership'), findsNothing);
      expect(find.text('Salary'), findsOneWidget);
    });

    testWidgets(
      '4. Active Blueprint Management: View & Edit Existing Rules without Duplicates',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final existingSalaryRule = RecurringTransactionRule(
          id: 'rule_sal_exist',
          userId: 'user_test_blueprint',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.income,
          name: 'Primary Job Salary',
          amount: 80000.0,
          categoryId: 'cat_salary',
          accountId: 'acc_bank',
          frequency: RecurrenceFrequency.monthly,
          startDate: now,
          nextOccurrence: now,
          active: true,
        );

        final existingLoan = Loan(
          id: 'loan_car',
          userId: 'user_test_blueprint',
          createdAt: now,
          updatedAt: now,
          name: 'Car Loan',
          type: LoanType.carLoan,
          interestRateType: InterestRateType.fixed,
          emiAmount: 14000.0,
          outstandingPrincipal: 500000.0,
          interestRate: 8.5,
          remainingTenureMonths: 36,
          startDate: now,
          linkedAccountId: 'acc_bank',
        );

        final container = ProviderContainer(
          overrides: buildOverrides(
            accounts: [testAccount],
            recurringRules: [existingSalaryRule],
            loans: [existingLoan],
          ),
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: FinancialSetupScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Active Blueprint section is rendered
        expect(find.text('Your Active Financial Blueprint'), findsOneWidget);
        expect(find.text('Primary Job Salary'), findsOneWidget);
        expect(find.text('₹80,000/mo'), findsOneWidget);
        expect(find.text('Car Loan'), findsOneWidget);
        expect(find.text('₹14,000/mo'), findsOneWidget);

        // Verify Edit buttons exist for active items
        expect(find.byTooltip('Edit Income Rule'), findsOneWidget);
        expect(find.byTooltip('Edit Loan'), findsOneWidget);
      },
    );

    testWidgets('5. Responsive UI Audit across 360px, 390px, 430px viewports', (
      tester,
    ) async {
      for (final width in [360.0, 390.0, 430.0]) {
        tester.view.physicalSize = Size(width, 740);
        tester.view.devicePixelRatio = 1.0;

        final container = ProviderContainer(
          overrides: buildOverrides(accounts: [testAccount]),
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: FinancialSetupScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Check that there is no RenderFlex overflow
        expect(tester.takeException(), isNull);
        expect(find.text('Your Money Blueprint'), findsOneWidget);

        container.dispose();
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
