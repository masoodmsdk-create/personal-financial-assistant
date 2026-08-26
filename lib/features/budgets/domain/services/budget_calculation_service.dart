import 'package:personal_financial_assistant/features/budgets/domain/models/budget.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense_override.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/transactions/domain/services/financial_aggregation_service.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class BudgetVsActualCategory {
  final Budget? budget;
  final Category category;
  final double planned;
  final double actual;
  final double remaining;
  final double utilizationPercentage;
  final bool isOverBudget;
  final bool isUnbudgeted;

  const BudgetVsActualCategory({
    this.budget,
    required this.category,
    required this.planned,
    required this.actual,
    required this.remaining,
    required this.utilizationPercentage,
    required this.isOverBudget,
    required this.isUnbudgeted,
  });
}

class MonthlyBudgetSummary {
  final int year;
  final int month;
  final double totalPlanned;
  final double totalActual;
  final double totalRemaining;
  final double overallUtilization;
  final int budgetedCategoriesCount;
  final int overBudgetCategoriesCount;
  final List<BudgetVsActualCategory> categoryBreakdowns;

  const MonthlyBudgetSummary({
    required this.year,
    required this.month,
    required this.totalPlanned,
    required this.totalActual,
    required this.totalRemaining,
    required this.overallUtilization,
    required this.budgetedCategoriesCount,
    required this.overBudgetCategoriesCount,
    required this.categoryBreakdowns,
  });
}

class MonthlyCashFlowPlan {
  final int year;
  final int month;
  final double expectedIncome;
  final double actualIncome;
  final double recurringCommitments;
  final double plannedExpenses;
  final double loanEmis;
  final double totalCommittedExpenses;
  final double budgetedVariableExpenses;
  final double totalPlannedOutflow;
  final double availableToSpend;
  final double actualExpenses;
  final double actualNetCashFlow;
  final double projectedNetCashFlow;
  final String explainableBreakdown;

  const MonthlyCashFlowPlan({
    required this.year,
    required this.month,
    required this.expectedIncome,
    required this.actualIncome,
    required this.recurringCommitments,
    required this.plannedExpenses,
    required this.loanEmis,
    required this.totalCommittedExpenses,
    required this.budgetedVariableExpenses,
    required this.totalPlannedOutflow,
    required this.availableToSpend,
    required this.actualExpenses,
    required this.actualNetCashFlow,
    required this.projectedNetCashFlow,
    required this.explainableBreakdown,
  });
}

class BudgetCalculationService {
  const BudgetCalculationService();

  /// Calculates deterministic Budget vs Actual summary for a given month/year.
  MonthlyBudgetSummary calculateBudgetVsActual({
    required int year,
    required int month,
    required List<Budget> budgets,
    required List<Transaction> transactions,
    required List<Category> categories,
  }) {
    // 1. Filter active budgets for the requested month
    final monthBudgets = budgets
        .where((b) => b.active && b.year == year && b.month == month)
        .toList();

    final budgetMap = {for (final b in monthBudgets) b.categoryId: b};

    // 2. Filter transactions for the requested month (expenses only)
    final monthExpenseTransactions = transactions.where((t) {
      return t.type == TransactionType.expense &&
          t.date.year == year &&
          t.date.month == month;
    }).toList();

    // Map expense totals by category ID
    final actualsByCategory = <String, double>{};
    for (final tx in monthExpenseTransactions) {
      if (tx.categoryId != null) {
        actualsByCategory[tx.categoryId!] =
            (actualsByCategory[tx.categoryId!] ?? 0.0) + tx.amount;
      }
    }

    // Categories map for quick lookup
    final categoriesMap = {for (final c in categories) c.id: c};

    // 3. Build category breakdowns
    final breakdowns = <BudgetVsActualCategory>[];
    double totalPlanned = 0.0;
    double totalActual = 0.0;
    int overBudgetCount = 0;

    // Collect all relevant category IDs: those with a budget or with actual spend
    final allCategoryIds = <String>{
      ...budgetMap.keys,
      ...actualsByCategory.keys,
    };

    for (final catId in allCategoryIds) {
      final budget = budgetMap[catId];
      final category =
          categoriesMap[catId] ??
          Category(
            id: catId,
            userId: '',
            name: 'Other',
            type: CategoryType.expense,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

      final planned = budget?.plannedAmount ?? 0.0;
      final actual = actualsByCategory[catId] ?? 0.0;
      final remaining = planned - actual;

      double utilization = 0.0;
      if (planned > 0) {
        utilization = (actual / planned) * 100.0;
      } else if (actual > 0) {
        utilization = 100.0; // Unbudgeted spending
      }

      final isOverBudget = planned > 0 && actual > planned;
      final isUnbudgeted = planned <= 0 && actual > 0;

      if (isOverBudget) {
        overBudgetCount++;
      }

      totalPlanned += planned;
      totalActual += actual;

      breakdowns.add(
        BudgetVsActualCategory(
          budget: budget,
          category: category,
          planned: planned,
          actual: actual,
          remaining: remaining,
          utilizationPercentage: utilization,
          isOverBudget: isOverBudget,
          isUnbudgeted: isUnbudgeted,
        ),
      );
    }

    // Sort: Over-budget first, then highest planned
    breakdowns.sort((a, b) {
      if (a.isOverBudget && !b.isOverBudget) return -1;
      if (!a.isOverBudget && b.isOverBudget) return 1;
      return b.planned.compareTo(a.planned);
    });

    final totalRemaining = totalPlanned - totalActual;
    final overallUtilization = totalPlanned > 0
        ? (totalActual / totalPlanned) * 100.0
        : (totalActual > 0 ? 100.0 : 0.0);

    return MonthlyBudgetSummary(
      year: year,
      month: month,
      totalPlanned: totalPlanned,
      totalActual: totalActual,
      totalRemaining: totalRemaining,
      overallUtilization: overallUtilization,
      budgetedCategoriesCount: monthBudgets.length,
      overBudgetCategoriesCount: overBudgetCount,
      categoryBreakdowns: breakdowns,
    );
  }

  /// Calculates deterministic Cash Flow & Available-to-Spend projection.
  MonthlyCashFlowPlan calculateCashFlowPlan({
    required int year,
    required int month,
    required List<Budget> budgets,
    required List<Transaction> transactions,
    required List<RecurringTransactionRule> recurringRules,
    required List<PlannedExpense> plannedExpenses,
    required List<PlannedExpenseOverride> overrides,
    required List<Loan> loans,
  }) {
    // 1. Actuals for the month
    final monthTransactions = transactions.where((t) {
      return t.date.year == year && t.date.month == month;
    }).toList();

    final actualIncome = FinancialAggregationService.calculateTotalIncome(
      monthTransactions,
    );
    final actualExpenses = FinancialAggregationService.calculateTotalExpense(
      monthTransactions,
    );
    final actualNetCashFlow = actualIncome - actualExpenses;

    // 2. Expected Income
    // Use actual income if already received for this month; otherwise fallback to active recurring income
    double activeRecurringIncome = 0.0;
    for (final rule in recurringRules.where(
      (r) => r.active && r.type == TransactionType.income,
    )) {
      activeRecurringIncome += rule.amount;
    }

    final expectedIncome = actualIncome > 0
        ? actualIncome
        : activeRecurringIncome;

    // 3. Committed Outflows
    // A. Recurring expense rules (e.g. Rent, Subscriptions)
    double recurringCommitments = 0.0;
    for (final rule in recurringRules.where(
      (r) => r.active && r.type == TransactionType.expense,
    )) {
      recurringCommitments += rule.amount;
    }

    // B. Active planned expenses for this month
    final overridesByPlanId = <String, PlannedExpenseOverride>{};
    for (final o in overrides) {
      if (o.year == year && o.month == month) {
        overridesByPlanId[o.planId] = o;
      }
    }

    double totalPlannedExpenses = 0.0;
    for (final plan in plannedExpenses.where((p) => p.active)) {
      if (plan.appliesToMonth(year, month)) {
        final override = overridesByPlanId[plan.id];
        totalPlannedExpenses += override?.amount ?? plan.defaultAmount;
      }
    }

    // C. Active Loan EMIs
    double loanEmis = 0.0;
    for (final loan in loans.where((l) => l.active && l.hasEmiAmount)) {
      loanEmis += loan.emiAmount!;
    }

    final totalCommittedExpenses =
        recurringCommitments + totalPlannedExpenses + loanEmis;

    // 4. Budgeted Variable Expenses (active budgets for this month)
    double budgetedVariableExpenses = 0.0;
    for (final b in budgets.where(
      (b) => b.active && b.year == year && b.month == month,
    )) {
      budgetedVariableExpenses += b.plannedAmount;
    }

    final totalPlannedOutflow =
        totalCommittedExpenses + budgetedVariableExpenses;

    // Available to Spend = Expected Income - Committed Outflows - Budgeted Variable Spend
    final availableToSpend =
        expectedIncome - totalCommittedExpenses - budgetedVariableExpenses;

    final projectedNetCashFlow = expectedIncome - totalPlannedOutflow;

    final breakdown = StringBuffer();
    breakdown.writeln('Expected Income: ₹${expectedIncome.toStringAsFixed(0)}');
    breakdown.writeln(
      '(-) Committed Fixed (Recurring + Planned + EMIs): ₹${totalCommittedExpenses.toStringAsFixed(0)}',
    );
    breakdown.writeln(
      '(-) Budgeted Variable Expenses: ₹${budgetedVariableExpenses.toStringAsFixed(0)}',
    );
    breakdown.writeln(
      '(=) Available to Spend: ₹${availableToSpend.toStringAsFixed(0)}',
    );

    return MonthlyCashFlowPlan(
      year: year,
      month: month,
      expectedIncome: expectedIncome,
      actualIncome: actualIncome,
      recurringCommitments: recurringCommitments,
      plannedExpenses: totalPlannedExpenses,
      loanEmis: loanEmis,
      totalCommittedExpenses: totalCommittedExpenses,
      budgetedVariableExpenses: budgetedVariableExpenses,
      totalPlannedOutflow: totalPlannedOutflow,
      availableToSpend: availableToSpend,
      actualExpenses: actualExpenses,
      actualNetCashFlow: actualNetCashFlow,
      projectedNetCashFlow: projectedNetCashFlow,
      explainableBreakdown: breakdown.toString(),
    );
  }
}
