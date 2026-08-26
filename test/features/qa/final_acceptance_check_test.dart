import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/domain/models/account_type_definition.dart';
import 'package:personal_financial_assistant/features/accounts/domain/repositories/account_repository.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/services/blueprint_persistence_service.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/services/financial_situation_parser.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/dashboard/domain/services/command_center_service.dart';
import 'package:personal_financial_assistant/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_financial_assistant/features/loans/domain/repositories/loan_repository.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/planned_expenses/domain/repositories/planned_expense_repository.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/review/domain/services/financial_review_service.dart';
import 'package:personal_financial_assistant/features/smart_entry/domain/services/smart_parser_service.dart';
import 'package:personal_financial_assistant/features/smart_entry/presentation/screens/smart_entry_screen.dart';
import 'package:personal_financial_assistant/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class _RecordingRecurringRepo implements RecurringTransactionRepository {
  final List<RecurringTransactionRule> rules = [];

  @override
  Future<void> createRecurringTransaction(RecurringTransactionRule rule) async {
    rules.add(rule);
  }

  @override
  Future<void> updateRecurringTransaction(RecurringTransactionRule rule) async {
    final idx = rules.indexWhere((r) => r.id == rule.id);
    if (idx != -1) rules[idx] = rule;
  }

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
  ) {
    return Stream.value(rules);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingTransactionRepo implements TransactionRepository {
  final List<Transaction> transactions = [];

  @override
  Future<void> createTransaction(Transaction tx) async {
    transactions.add(tx);
  }

  @override
  Future<List<Transaction>> getTransactions(
    String userId, {
    TransactionType? type,
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return transactions;
  }

  @override
  Stream<List<Transaction>> watchTransactions(
    String userId, {
    TransactionType? type,
    String? accountId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Stream.value(transactions);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyPlannedExpenseRepo implements PlannedExpenseRepository {
  @override
  Future<void> createPlannedExpense(dynamic exp) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyLoanRepo implements LoanRepository {
  @override
  Future<void> createLoan(dynamic loan) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyAccountRepo implements AccountRepository {
  @override
  Future<void> createAccount(dynamic acc) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyGoalRepo implements GoalRepository {
  @override
  Future<void> createGoal(dynamic goal) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'user_1';
  @override
  String? get email => 'test@finaura.com';
  @override
  String? get displayName => 'Test User';
}

void main() {
  group('MSD FINAURA — Final Acceptance Check', () {
    test('1. Financial Setup -> Recurring Income Persistence', () async {
      final parser = const FinancialSituationParser();
      final blueprint = parser.parseSituation(
        rawText: 'My salary is ₹80,000, rent ₹15,000, groceries ₹5,000',
        accounts: [],
        categories: Category.generateDefaults('user_1'),
      );

      expect(blueprint.incomes.isNotEmpty, isTrue);
      expect(blueprint.incomes.first.monthlyAmount, 80000.0);

      final recRepo = _RecordingRecurringRepo();
      final txRepo = _RecordingTransactionRepo();

      final service = BlueprintPersistenceService(
        plannedExpenseRepo: _DummyPlannedExpenseRepo(),
        loanRepo: _DummyLoanRepo(),
        accountRepo: _DummyAccountRepo(),
        goalRepo: _DummyGoalRepo(),
        transactionRepo: txRepo,
        recurringRepo: recRepo,
      );

      final result = await service.persistBlueprint(
        blueprint: blueprint,
        userId: 'user_1',
      );

      // Verify recurring income was persisted as a RecurringTransactionRule
      expect(result.recurringIncomesCreated, 1);
      expect(recRepo.rules.length, 1);
      expect(recRepo.rules.first.amount, 80000.0);
      expect(recRepo.rules.first.type, TransactionType.income);
      expect(recRepo.rules.first.frequency, RecurrenceFrequency.monthly);

      // Invariant: No premature actual transactions created
      expect(txRepo.transactions.isEmpty, isTrue);
    });

    test(
      '2. Dashboard -> Active Recurring Expense appears in Upcoming Reminders',
      () {
        const service = CommandCenterService();
        final now = DateTime.now();

        final recurringExpense = RecurringTransactionRule(
          id: 'rule_rent_1',
          userId: 'user_1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.expense,
          name: 'House Rent',
          amount: 15000.0,
          categoryId: 'cat_housing',
          accountId: 'acc_hdfc',
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          startDate: now,
          nextOccurrence: now.add(const Duration(days: 3)),
          active: true,
        );

        final reminders = service.getUpcomingReminders(
          loans: const <Loan>[],
          plans: const <PlannedExpense>[],
          recurringRules: [recurringExpense],
          asOfDate: now,
        );

        expect(reminders.isNotEmpty, isTrue);
        final rentReminder = reminders.firstWhere(
          (r) => r.id == 'rem_rec_rule_rent_1',
        );
        expect(rentReminder.title, 'House Rent');
        expect(rentReminder.amount, 15000.0);
        expect(rentReminder.actionRoute, '/recurring-transactions');
        expect(rentReminder.isEmi, isFalse);
      },
    );

    test('3. Monthly Review -> Active Recurring Income & Expense affect Next-Month Forecast', () {
      final now = DateTime.now();
      final targetDate = DateTime(now.year, now.month);

      final recurringSalary = RecurringTransactionRule(
        id: 'rule_sal_1',
        userId: 'user_1',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.income,
        name: 'Primary Salary',
        amount: 80000.0,
        categoryId: 'cat_salary',
        accountId: 'acc_hdfc',
        frequency: RecurrenceFrequency.monthly,
        startDate: now,
        nextOccurrence: now,
        active: true,
      );

      final recurringRent = RecurringTransactionRule(
        id: 'rule_rent_1',
        userId: 'user_1',
        createdAt: now,
        updatedAt: now,
        type: TransactionType.expense,
        name: 'House Rent',
        amount: 15000.0,
        categoryId: 'cat_housing',
        accountId: 'acc_hdfc',
        frequency: RecurrenceFrequency.monthly,
        startDate: now,
        nextOccurrence: now,
        active: true,
      );

      final review = FinancialReviewService.buildMonthlyReview(
        targetDate: targetDate,
        transactions: const <Transaction>[], // No actual transactions yet
        plans: const <PlannedExpense>[],
        overrides: const [],
        categories: Category.generateDefaults('user_1'),
        loans: const <Loan>[],
        goals: const [],
        recurringRules: [recurringSalary, recurringRent],
      );

      // Expected next-month forecast uses active recurring income & expenses
      expect(review.upcomingForecast.expectedIncome, 80000.0);
      expect(review.upcomingForecast.expectedExpenses, 15000.0);
      expect(review.upcomingForecast.expectedNetPosition, 65000.0);
    });

    test(
      '4. Smart Assistant -> Inherent Recurring vs One-time Intent Detection',
      () {
        const parser = SmartParserService();
        final mockAccounts = [
          Account(
            id: 'acc_sbi',
            userId: 'user_1',
            name: 'SBI Bank',
            type: AccountType.bank,
            accountTypeId: 'bank_account',
            nature: AccountNature.asset,
            openingBalance: 10000,
            currency: 'INR',
            active: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        final mockCategories = Category.generateDefaults('user_1');

        // Test A: "Salary ₹80,000" -> Recurring Income
        final r1 = parser.parseText(
          rawText: 'Salary ₹80,000',
          accounts: mockAccounts,
          categories: mockCategories,
        );
        expect(r1.first.isRecurring, isTrue);
        expect(r1.first.type, TransactionType.income);
        expect(r1.first.amount, 80000.0);
        expect(r1.first.frequency, RecurrenceFrequency.monthly);

        // Test B: "Rent ₹15,000" -> Recurring Expense
        final r2 = parser.parseText(
          rawText: 'Rent ₹15,000',
          accounts: mockAccounts,
          categories: mockCategories,
        );
        expect(r2.first.isRecurring, isTrue);
        expect(r2.first.type, TransactionType.expense);
        expect(r2.first.amount, 15000.0);
        expect(r2.first.frequency, RecurrenceFrequency.monthly);

        // Test C: "SIP ₹5,000" -> Recurring
        final r3 = parser.parseText(
          rawText: 'SIP ₹5,000',
          accounts: mockAccounts,
          categories: mockCategories,
        );
        expect(r3.first.isRecurring, isTrue);
        expect(r3.first.amount, 5000.0);
        expect(r3.first.frequency, RecurrenceFrequency.monthly);

        // Test D: "Paid ₹500 groceries today" -> One-time
        final r4 = parser.parseText(
          rawText: 'Paid ₹500 groceries today',
          accounts: mockAccounts,
          categories: mockCategories,
        );
        expect(r4.first.isRecurring, isFalse);
        expect(r4.first.amount, 500.0);

        // Test E: "Paid rent ₹15,000 on 1 August" -> One-time
        final r5 = parser.parseText(
          rawText: 'Paid rent ₹15,000 on 1 August',
          accounts: mockAccounts,
          categories: mockCategories,
        );
        expect(r5.first.isRecurring, isFalse);
        expect(r5.first.amount, 15000.0);
      },
    );

    testWidgets(
      '5 & 6. Smart Entry UI -> Parse recurring draft, save rule without duplicate transactions',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final recRepo = _RecordingRecurringRepo();
        final txRepo = _RecordingTransactionRepo();
        final mockAccounts = [
          Account(
            id: 'acc_hdfc',
            userId: 'user_1',
            name: 'HDFC Bank',
            type: AccountType.bank,
            accountTypeId: 'bank_account',
            nature: AccountNature.asset,
            openingBalance: 20000,
            currency: 'INR',
            active: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProvider.overrideWith((ref) => _FakeUser()),
              recurringTransactionRepositoryProvider.overrideWithValue(recRepo),
              transactionRepositoryProvider.overrideWithValue(txRepo),
              accountsStreamProvider.overrideWith(
                (ref) => Stream.value(mockAccounts),
              ),
              transactionsStreamProvider.overrideWith(
                (ref) => Stream.value([]),
              ),
              categoriesStreamProvider.overrideWith(
                (ref) => Stream.value(Category.generateDefaults('user_1')),
              ),
            ],
            child: const MaterialApp(home: SmartEntryScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Rent 15000');
        await tester.pumpAndSettle();

        final understandBtn = find.widgetWithText(FilledButton, 'Understand');
        await tester.tap(understandBtn);
        await tester.pumpAndSettle();

        // Verify UI displays recurring commitment card
        expect(find.text('RECURRING EXPENSE'), findsOneWidget);
        expect(find.text('Confirm & Save Rule'), findsOneWidget);

        // Tap Confirm & Save Rule
        final saveBtn = find.widgetWithText(
          FilledButton,
          'Confirm & Save Rule',
        );
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Rule is persisted to recurring repo
        expect(recRepo.rules.length, 1);
        expect(recRepo.rules.first.amount, 15000.0);
        expect(recRepo.rules.first.type, TransactionType.expense);

        // Invariant: Zero duplicate transactions generated upon rule creation
        expect(txRepo.transactions.isEmpty, isTrue);
      },
    );
  });
}
