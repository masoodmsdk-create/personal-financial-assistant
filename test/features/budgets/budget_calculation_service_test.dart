import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/budgets/domain/models/budget.dart';
import 'package:personal_financial_assistant/features/budgets/domain/services/budget_calculation_service.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

void main() {
  group('BudgetCalculationService Unit Tests', () {
    const service = BudgetCalculationService();
    final categories = Category.generateDefaults('u_1');

    test('1. Calculates Budget vs Actual accurately for on-track category', () {
      final now = DateTime(2026, 8, 15);
      final budgets = [
        Budget(
          id: 'b_groc',
          userId: 'u_1',
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
          userId: 'u_1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.expense,
          amount: 5500.0,
          date: DateTime(2026, 8, 10),
          categoryId: 'cat_groceries',
        ),
      ];

      final summary = service.calculateBudgetVsActual(
        year: 2026,
        month: 8,
        budgets: budgets,
        transactions: transactions,
        categories: categories,
      );

      expect(summary.totalPlanned, 8000.0);
      expect(summary.totalActual, 5500.0);
      expect(summary.totalRemaining, 2500.0);
      expect(summary.overallUtilization, closeTo(68.75, 0.01));
      expect(summary.overBudgetCategoriesCount, 0);

      final groc = summary.categoryBreakdowns.firstWhere(
        (c) => c.category.id == 'cat_groceries',
      );
      expect(groc.planned, 8000.0);
      expect(groc.actual, 5500.0);
      expect(groc.remaining, 2500.0);
      expect(groc.utilizationPercentage, closeTo(68.75, 0.01));
      expect(groc.isOverBudget, isFalse);
      expect(groc.isUnbudgeted, isFalse);
    });

    test('2. Handles Over-Budget spending correctly', () {
      final now = DateTime(2026, 8, 15);
      final budgets = [
        Budget(
          id: 'b_dining',
          userId: 'u_1',
          createdAt: now,
          updatedAt: now,
          year: 2026,
          month: 8,
          categoryId: 'cat_dining',
          plannedAmount: 4000.0,
          active: true,
        ),
      ];

      final transactions = [
        Transaction(
          id: 'tx_1',
          userId: 'u_1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.expense,
          amount: 6000.0,
          date: DateTime(2026, 8, 12),
          categoryId: 'cat_dining',
        ),
      ];

      final summary = service.calculateBudgetVsActual(
        year: 2026,
        month: 8,
        budgets: budgets,
        transactions: transactions,
        categories: categories,
      );

      expect(summary.totalPlanned, 4000.0);
      expect(summary.totalActual, 6000.0);
      expect(summary.totalRemaining, -2000.0);
      expect(summary.overallUtilization, 150.0);
      expect(summary.overBudgetCategoriesCount, 1);

      final dining = summary.categoryBreakdowns.first;
      expect(dining.isOverBudget, isTrue);
      expect(dining.remaining, -2000.0);
    });

    test('3. Handles Zero-Budget (Unbudgeted) spending without divide-by-zero error', () {
      final now = DateTime(2026, 8, 15);
      final transactions = [
        Transaction(
          id: 'tx_1',
          userId: 'u_1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.expense,
          amount: 1200.0,
          date: DateTime(2026, 8, 5),
          categoryId: 'cat_shopping',
        ),
      ];

      final summary = service.calculateBudgetVsActual(
        year: 2026,
        month: 8,
        budgets: const [], // Zero budgets set
        transactions: transactions,
        categories: categories,
      );

      expect(summary.totalPlanned, 0.0);
      expect(summary.totalActual, 1200.0);
      expect(summary.totalRemaining, -1200.0);
      expect(summary.overallUtilization, 100.0);

      final shopping = summary.categoryBreakdowns.first;
      expect(shopping.isUnbudgeted, isTrue);
      expect(shopping.planned, 0.0);
      expect(shopping.actual, 1200.0);
    });

    test('4. Handles Zero-Spending with planned budget cleanly', () {
      final now = DateTime(2026, 8, 1);
      final budgets = [
        Budget(
          id: 'b_travel',
          userId: 'u_1',
          createdAt: now,
          updatedAt: now,
          year: 2026,
          month: 8,
          categoryId: 'cat_transport',
          plannedAmount: 5000.0,
          active: true,
        ),
      ];

      final summary = service.calculateBudgetVsActual(
        year: 2026,
        month: 8,
        budgets: budgets,
        transactions: const [],
        categories: categories,
      );

      expect(summary.totalPlanned, 5000.0);
      expect(summary.totalActual, 0.0);
      expect(summary.totalRemaining, 5000.0);
      expect(summary.overallUtilization, 0.0);
      expect(summary.overBudgetCategoriesCount, 0);
    });

    test(
      '5. Calculates Monthly Cash Flow & Available-to-Spend formula accurately',
      () {
        final now = DateTime(2026, 8, 1);

        // 1. Recurring Salary: ₹80,000
        final recurringSalary = RecurringTransactionRule(
          id: 'rule_sal',
          userId: 'u_1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.income,
          name: 'Salary',
          amount: 80000.0,
          categoryId: 'cat_salary',
          accountId: 'acc_hdfc',
          frequency: RecurrenceFrequency.monthly,
          startDate: now,
          nextOccurrence: now,
          active: true,
        );

        // 2. Recurring Rent: ₹15,000
        final recurringRent = RecurringTransactionRule(
          id: 'rule_rent',
          userId: 'u_1',
          createdAt: now,
          updatedAt: now,
          type: TransactionType.expense,
          name: 'Rent',
          amount: 15000.0,
          categoryId: 'cat_housing',
          accountId: 'acc_hdfc',
          frequency: RecurrenceFrequency.monthly,
          startDate: now,
          nextOccurrence: now,
          active: true,
        );

        // 3. Planned Expense (Internet): ₹1,000
        final plannedInternet = PlannedExpense(
          id: 'plan_wifi',
          userId: 'u_1',
          createdAt: now,
          updatedAt: now,
          name: 'Broadband Internet',
          defaultAmount: 1000.0,
          frequency: RecurrenceFrequency.monthly,
          startDate: now,
          categoryId: 'cat_bills',
          active: true,
        );

        // 4. Loan EMI (Car Loan): ₹9,000
        final carLoan = Loan(
          id: 'loan_car',
          userId: 'u_1',
          createdAt: now,
          updatedAt: now,
          name: 'Car Loan',
          type: LoanType.carLoan,
          interestRateType: InterestRateType.fixed,
          emiAmount: 9000.0,
          outstandingPrincipal: 300000.0,
          interestRate: 8.5,
          remainingTenureMonths: 36,
          active: true,
        );

        // 5. Category Budgets: Groceries ₹12,000 + Dining ₹8,000 = ₹20,000
        final budgets = [
          Budget(
            id: 'b_groc',
            userId: 'u_1',
            createdAt: now,
            updatedAt: now,
            year: 2026,
            month: 8,
            categoryId: 'cat_groceries',
            plannedAmount: 12000.0,
            active: true,
          ),
          Budget(
            id: 'b_dining',
            userId: 'u_1',
            createdAt: now,
            updatedAt: now,
            year: 2026,
            month: 8,
            categoryId: 'cat_dining',
            plannedAmount: 8000.0,
            active: true,
          ),
        ];

        final plan = service.calculateCashFlowPlan(
          year: 2026,
          month: 8,
          budgets: budgets,
          transactions: const [],
          recurringRules: [recurringSalary, recurringRent],
          plannedExpenses: [plannedInternet],
          overrides: const [],
          loans: [carLoan],
        );

        // Calculation Breakdown Verification:
        // Expected Income: ₹80,000
        // Recurring Commitments: ₹15,000
        // Planned Expenses: ₹1,000
        // Loan EMIs: ₹9,000
        // Total Committed Fixed: 15,000 + 1,000 + 9,000 = ₹25,000
        // Budgeted Variable: 12,000 + 8,000 = ₹20,000
        // Total Planned Outflow: 25,000 + 20,000 = ₹45,000
        // Available to Spend: 80,000 - 25,000 - 20,000 = ₹35,000

        expect(plan.expectedIncome, 80000.0);
        expect(plan.recurringCommitments, 15000.0);
        expect(plan.plannedExpenses, 1000.0);
        expect(plan.loanEmis, 9000.0);
        expect(plan.totalCommittedExpenses, 25000.0);
        expect(plan.budgetedVariableExpenses, 20000.0);
        expect(plan.totalPlannedOutflow, 45000.0);
        expect(plan.availableToSpend, 35000.0);
        expect(plan.projectedNetCashFlow, 35000.0);
      },
    );
  });
}
