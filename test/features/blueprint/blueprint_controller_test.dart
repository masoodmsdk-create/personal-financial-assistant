import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/domain/repositories/account_repository.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/services/blueprint_persistence_service.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/services/financial_situation_parser.dart';
import 'package:personal_financial_assistant/features/blueprint/presentation/providers/blueprint_providers.dart';

import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_financial_assistant/features/loans/domain/repositories/loan_repository.dart';
import 'package:personal_financial_assistant/features/planned_expenses/domain/repositories/planned_expense_repository.dart';
import 'package:personal_financial_assistant/features/transactions/domain/repositories/transaction_repository.dart';

class FakePlannedExpenseRepo implements PlannedExpenseRepository {
  final List<dynamic> items = [];
  @override
  Future<void> createPlannedExpense(dynamic exp) async => items.add(exp);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLoanRepo implements LoanRepository {
  final List<dynamic> items = [];
  @override
  Future<void> createLoan(dynamic loan) async => items.add(loan);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAccountRepo implements AccountRepository {
  final List<dynamic> items = [];
  @override
  Future<void> createAccount(dynamic acc) async => items.add(acc);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGoalRepo implements GoalRepository {
  final List<dynamic> items = [];
  @override
  Future<void> createGoal(dynamic goal) async => items.add(goal);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTransactionRepo implements TransactionRepository {
  final List<dynamic> items = [];
  @override
  Future<void> createTransaction(dynamic tx) async => items.add(tx);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late BlueprintController controller;
  late FakePlannedExpenseRepo expenseRepo;
  late FakeLoanRepo loanRepo;
  late FakeAccountRepo accountRepo;
  late FakeGoalRepo goalRepo;
  late FakeTransactionRepo transactionRepo;

  setUp(() {
    expenseRepo = FakePlannedExpenseRepo();
    loanRepo = FakeLoanRepo();
    accountRepo = FakeAccountRepo();
    goalRepo = FakeGoalRepo();
    transactionRepo = FakeTransactionRepo();

    final persistenceService = BlueprintPersistenceService(
      plannedExpenseRepo: expenseRepo,
      loanRepo: loanRepo,
      accountRepo: accountRepo,
      goalRepo: goalRepo,
      transactionRepo: transactionRepo,
    );

    controller = BlueprintController(
      const FinancialSituationParser(),
      persistenceService,
    );
  });

  group('BlueprintController Unit Tests', () {
    test(
      'parseSituation populates live blueprint and calculates cash flows',
      () {
        controller.setInput('Salary 100000, rent 25000, groceries 8000');
        controller.parseSituation(
          accounts: [],
          categories: Category.generateDefaults('u1'),
        );

        final bp = controller.state.blueprint;
        expect(bp, isNotNull);
        expect(bp!.totalMonthlyIncome, 100000);
        expect(bp.totalMonthlyExpenses, 33000);
        expect(bp.knownRemainingMonthlyCashFlow, 67000);
      },
    );

    test('answerClarification moves ambiguous EMI to Transaction on actual_payment', () {
      controller.setInput('Paid 1200 EMI yesterday');
      controller.parseSituation(
        accounts: [],
        categories: Category.generateDefaults('u1'),
      );

      final bp = controller.state.blueprint!;
      expect(bp.clarifications.length, 1);
      final qId = bp.clarifications.first.id;

      // Select actual_payment
      controller.answerClarification(
        questionId: qId,
        optionId: 'actual_payment',
      );

      final updatedBp = controller.state.blueprint!;
      expect(updatedBp.loans, isEmpty);
      expect(updatedBp.transactions.length, 1);
      expect(updatedBp.transactions.first.amount, 1200);
    });

    test(
      'confirmAndPersist saves all entities to respective repositories',
      () async {
        controller.setInput(
          'Salary 100000, rent 20000, 1 lakh in savings, emergency fund of 5 lakh',
        );
        controller.parseSituation(
          accounts: [],
          categories: Category.generateDefaults('u1'),
        );

        final success = await controller.confirmAndPersist('user_test_99');

        expect(success, isTrue);
        expect(controller.state.isConfirmed, isTrue);
        expect(expenseRepo.items.length, 1);
        expect(accountRepo.items.length, 1);
        expect(goalRepo.items.length, 1);
      },
    );
  });
}
