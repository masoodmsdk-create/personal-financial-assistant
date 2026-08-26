import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/domain/repositories/account_repository.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/models/financial_blueprint.dart';
import 'package:personal_financial_assistant/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/domain/repositories/loan_repository.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/planned_expenses/domain/repositories/planned_expense_repository.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:personal_financial_assistant/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class BlueprintPersistenceResult {
  final int expensesCreated;
  final int loansCreated;
  final int savingsCreated;
  final int goalsCreated;
  final int transactionsCreated;
  final int recurringIncomesCreated;

  const BlueprintPersistenceResult({
    this.expensesCreated = 0,
    this.loansCreated = 0,
    this.savingsCreated = 0,
    this.goalsCreated = 0,
    this.transactionsCreated = 0,
    this.recurringIncomesCreated = 0,
  });

  int get totalRecordsCreated =>
      expensesCreated +
      loansCreated +
      savingsCreated +
      goalsCreated +
      transactionsCreated +
      recurringIncomesCreated;
}

class BlueprintPersistenceService {
  final PlannedExpenseRepository plannedExpenseRepo;
  final LoanRepository loanRepo;
  final AccountRepository accountRepo;
  final GoalRepository goalRepo;
  final TransactionRepository transactionRepo;
  final RecurringTransactionRepository? recurringRepo;

  const BlueprintPersistenceService({
    required this.plannedExpenseRepo,
    required this.loanRepo,
    required this.accountRepo,
    required this.goalRepo,
    required this.transactionRepo,
    this.recurringRepo,
  });

  Future<BlueprintPersistenceResult> persistBlueprint({
    required FinancialBlueprint blueprint,
    required String userId,
  }) async {
    final now = DateTime.now();
    int expensesCount = 0;
    int loansCount = 0;
    int savingsCount = 0;
    int goalsCount = 0;
    int transactionsCount = 0;
    int recurringIncomesCount = 0;

    // 1. Persist Recurring Planned Expenses
    for (final exp in blueprint.recurringExpenses) {
      final planned = PlannedExpense(
        id: 'plan_${now.millisecondsSinceEpoch}_$expensesCount',
        userId: userId,
        createdAt: now,
        updatedAt: now,
        name: exp.categoryName,
        defaultAmount: exp.monthlyAmount,
        frequency: RecurrenceFrequency.monthly,
        startDate: now,
        categoryId: exp.categoryId ?? 'cat_living_expense',
        active: true,
      );
      await plannedExpenseRepo.createPlannedExpense(planned);
      expensesCount++;
    }

    // 2. Persist Loans
    for (final loanItem in blueprint.loans) {
      if (loanItem.isExistingLoanPayment) continue;

      final loan = Loan(
        id: 'loan_${now.millisecondsSinceEpoch}_$loansCount',
        userId: userId,
        createdAt: now,
        updatedAt: now,
        name: loanItem.loanName,
        type: loanItem.loanType,
        interestRateType: InterestRateType.fixed,
        emiAmount: loanItem.emiAmount,
        outstandingPrincipal: loanItem.outstandingPrincipal,
        interestRate: loanItem.interestRate,
        remainingTenureMonths: loanItem.remainingTenureMonths,
        startDate: now,
        active: true,
      );
      await loanRepo.createLoan(loan);
      loansCount++;
    }

    // 3. Persist Savings / Assets as Accounts
    for (final sav in blueprint.savings) {
      if (sav.accountId != null) continue; // Existing account reference

      final acc = Account(
        id: 'acc_${now.millisecondsSinceEpoch}_$savingsCount',
        userId: userId,
        createdAt: now,
        updatedAt: now,
        name: sav.accountName,
        type: sav.accountType,
        openingBalance: sav.amount,
        currency: 'INR',
        active: true,
      );
      await accountRepo.createAccount(acc);
      savingsCount++;
    }

    // 4. Persist Goals
    for (final g in blueprint.goals) {
      final goal = Goal(
        id: 'goal_${now.millisecondsSinceEpoch}_$goalsCount',
        userId: userId,
        createdAt: now,
        updatedAt: now,
        name: g.goalName,
        targetAmount: g.targetAmount,
        currentAmount: 0.0,
        type: g.goalType,
        targetDate: g.targetMonths != null
            ? now.add(Duration(days: g.targetMonths! * 30))
            : now.add(const Duration(days: 365)),
        active: true,
      );
      await goalRepo.createGoal(goal);
      goalsCount++;
    }

    // 5. Persist Actual Transactions
    for (final txItem in blueprint.transactions) {
      final tx = Transaction(
        id: 'tx_${now.millisecondsSinceEpoch}_$transactionsCount',
        userId: userId,
        createdAt: now,
        updatedAt: now,
        type: txItem.type,
        amount: txItem.amount,
        date: txItem.date,
        note: txItem.note,
        categoryId: txItem.categoryId,
        accountId: txItem.accountId,
      );
      await transactionRepo.createTransaction(tx);
      transactionsCount++;
    }

    // 6. Persist Recurring Income Rules
    if (recurringRepo != null) {
      for (final inc in blueprint.incomes) {
        final rule = RecurringTransactionRule(
          id: 'rule_${now.millisecondsSinceEpoch}_$recurringIncomesCount',
          userId: userId,
          createdAt: now,
          updatedAt: now,
          name: inc.label.isNotEmpty ? inc.label : 'Salary',
          type: TransactionType.income,
          amount: inc.monthlyAmount,
          accountId: 'acc_primary',
          categoryId: 'cat_salary',
          frequency: RecurrenceFrequency.monthly,
          interval: 1,
          dayOfMonth: 1,
          startDate: now,
          nextOccurrence: now,
          active: true,
        );
        await recurringRepo!.createRecurringTransaction(rule);
        recurringIncomesCount++;
      }
    }

    return BlueprintPersistenceResult(
      expensesCreated: expensesCount,
      loansCreated: loansCount,
      savingsCreated: savingsCount,
      goalsCreated: goalsCount,
      transactionsCreated: transactionsCount,
      recurringIncomesCreated: recurringIncomesCount,
    );
  }
}
