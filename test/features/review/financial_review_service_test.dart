import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense_override.dart';
import 'package:personal_financial_assistant/features/review/domain/services/financial_review_service.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

void main() {
  final now = DateTime(2026, 8, 1);
  final targetDate = DateTime(2026, 8, 15);

  final categories = [
    Category(
      id: 'cat_food',
      userId: 'user_1',
      name: 'Food & Groceries',
      type: CategoryType.expense,
      createdAt: now,
      updatedAt: now,
    ),
    Category(
      id: 'cat_salary',
      userId: 'user_1',
      name: 'Salary',
      type: CategoryType.income,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  final plans = [
    PlannedExpense(
      id: 'plan_rent',
      userId: 'user_1',
      name: 'Rent',
      categoryId: 'cat_food',
      defaultAmount: 25000.0,
      frequency: RecurrenceFrequency.monthly,
      startDate: DateTime(2026, 1, 1),
      createdAt: now,
      updatedAt: now,
    ),
  ];

  final overrides = [
    PlannedExpenseOverride(
      id: 'override_plan_rent_2026_8',
      userId: 'user_1',
      planId: 'plan_rent',
      year: 2026,
      month: 8,
      amount: 28000.0,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  final transactions = [
    Transaction(
      id: 'tx_1',
      userId: 'user_1',
      type: TransactionType.income,
      amount: 150000.0,
      accountId: 'acc_bank',
      categoryId: 'cat_salary',
      date: DateTime(2026, 8, 5),
      createdAt: now,
      updatedAt: now,
    ),
    Transaction(
      id: 'tx_2',
      userId: 'user_1',
      type: TransactionType.expense,
      amount: 20000.0,
      accountId: 'acc_bank',
      categoryId: 'cat_food',
      date: DateTime(2026, 8, 10),
      createdAt: now,
      updatedAt: now,
    ),
  ];

  final loans = [
    Loan(
      id: 'loan_1',
      userId: 'user_1',
      name: 'Home Loan',
      type: LoanType.homeLoan,
      outstandingPrincipal: 3000000.0,
      interestRate: 8.5,
      emiAmount: 35000.0,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  final goals = [
    Goal(
      id: 'goal_1',
      userId: 'user_1',
      name: 'Emergency Reserve',
      type: GoalType.emergencyFund,
      targetAmount: 100000.0,
      currentAmount: 40000.0,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  group('FinancialReviewService Composition Tests', () {
    test('buildMonthlyReview correctly composes monthly summary, planned vs actual, and forecast', () {
      final review = FinancialReviewService.buildMonthlyReview(
        targetDate: targetDate,
        transactions: transactions,
        plans: plans,
        overrides: overrides,
        categories: categories,
        loans: loans,
        goals: goals,
      );

      expect(review.totalIncome, 150000.0);
      expect(review.totalExpense, 20000.0);
      expect(review.netCashFlow, 130000.0);
      expect(
        review.totalPlannedExpense,
        28000.0,
      ); // Uses August override amount 28k
      expect(review.isAbovePlan, false);
      expect(review.plannedVsActualDiff, 8000.0); // 28k - 20k
      expect(review.expenseCategoryBreakdown.length, 1);
      expect(review.upcomingForecast.year, 2026);
      expect(review.upcomingForecast.month, 9); // September
      expect(
        review.upcomingForecast.expectedExpenses,
        60000.0,
      ); // 25k default rent + 35k loan EMI
      expect(review.goalSummaries.length, 1);
      expect(review.loanSummaries.length, 1);
    });

    test(
      'buildMonthlyReview handles zero transactions and empty data safely',
      () {
        final review = FinancialReviewService.buildMonthlyReview(
          targetDate: targetDate,
          transactions: [],
          plans: [],
          overrides: [],
          categories: categories,
          loans: [],
          goals: [],
        );

        expect(review.totalIncome, 0.0);
        expect(review.totalExpense, 0.0);
        expect(review.hasTransactions, false);
        expect(review.hasPlannedExpenses, false);
        expect(review.expenseCategoryBreakdown.isEmpty, true);
        expect(review.upcomingForecast.expectedExpenses, 0.0);
      },
    );
  });
}
