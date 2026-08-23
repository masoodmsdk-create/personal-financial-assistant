import 'package:personal_financial_assistant/features/analytics/domain/services/financial_insights_service.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/domain/models/loan_forecast.dart';
import 'package:personal_financial_assistant/features/loans/domain/services/loan_forecast_service.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense_override.dart';
import 'package:personal_financial_assistant/features/review/domain/models/monthly_review_data.dart';
import 'package:personal_financial_assistant/features/transactions/domain/services/financial_aggregation_service.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class FinancialReviewService {
  /// Pure composition domain service creating unified MonthlyReviewData
  static MonthlyReviewData buildMonthlyReview({
    required DateTime targetDate,
    required List<Transaction> transactions,
    required List<PlannedExpense> plans,
    required List<PlannedExpenseOverride> overrides,
    required List<Category> categories,
    required List<Loan> loans,
    required List<Goal> goals,
  }) {
    final year = targetDate.year;
    final month = targetDate.month;

    // Filter transactions for the target month
    final monthTransactions = transactions.where((t) {
      return t.date.year == year && t.date.month == month;
    }).toList();

    // 1. Calculate Monthly Summary (Actuals)
    final totalIncome = FinancialAggregationService.calculateTotalIncome(
      monthTransactions,
    );
    final totalExpense = FinancialAggregationService.calculateTotalExpense(
      monthTransactions,
    );
    final netCashFlow = totalIncome - totalExpense;

    // 2. Calculate Planned vs Actual
    final plannedVsActual =
        FinancialAggregationService.calculatePlannedVsActual(
          plans: plans,
          overrides: overrides,
          transactions: transactions,
          year: year,
          month: month,
        );

    final totalPlanned = plannedVsActual.totalPlannedAmount;
    final diff = totalPlanned - totalExpense;
    final isAbovePlan = totalExpense > totalPlanned;

    // 3. Category Breakdown (Expenses & Income)
    final expenseBreakdown =
        FinancialAggregationService.calculateCategoryBreakdown(
          transactions: monthTransactions,
          categories: categories,
          categoryType: CategoryType.expense,
        );

    final incomeBreakdown =
        FinancialAggregationService.calculateCategoryBreakdown(
          transactions: monthTransactions,
          categories: categories,
          categoryType: CategoryType.income,
        );

    // 4. Financial Insights (Things to Review)
    final insights = FinancialInsightsService.generateInsights(
      transactions: transactions,
      plans: plans,
      overrides: overrides,
      categories: categories,
      periodDate: targetDate,
    );

    // 5. Coming Up Forecast (Next Month)
    final nextMonthDate = DateTime(year, month + 1, 1);
    final nextYear = nextMonthDate.year;
    final nextMonth = nextMonthDate.month;

    final overridesByPlanId = <String, PlannedExpenseOverride>{};
    for (final o in overrides) {
      if (o.year == nextYear && o.month == nextMonth) {
        overridesByPlanId[o.planId] = o;
      }
    }

    var expectedExpenses = 0.0;
    var plannedCount = 0;

    for (final plan in plans.where((p) => p.active)) {
      if (plan.appliesToMonth(nextYear, nextMonth)) {
        final override = overridesByPlanId[plan.id];
        expectedExpenses += override?.amount ?? plan.defaultAmount;
        plannedCount++;
      }
    }

    // Add active loan EMIs to expected expenses forecast
    for (final loan in loans.where((l) => l.active)) {
      if (loan.hasEmiAmount) {
        expectedExpenses += loan.emiAmount!;
        plannedCount++;
      }
    }

    // Expected Income = current month actual income or reasonable baseline
    final expectedIncome = totalIncome > 0 ? totalIncome : 0.0;
    final expectedNetPosition = expectedIncome - expectedExpenses;

    final upcomingForecast = UpcomingForecastData(
      year: nextYear,
      month: nextMonth,
      expectedIncome: expectedIncome,
      expectedExpenses: expectedExpenses,
      expectedNetPosition: expectedNetPosition,
      plannedItemsCount: plannedCount,
    );

    // 6. Goal Summaries
    final loansMap = {for (final l in loans) l.id: l};

    final goalSummaries = goals.where((g) => g.active).map((goal) {
      LoanForecastResult? linkedForecast;
      if (goal.linkedLoanId != null &&
          loansMap.containsKey(goal.linkedLoanId)) {
        linkedForecast = LoanForecastService.calculateForecast(
          loansMap[goal.linkedLoanId]!,
        );
      }

      return GoalProgressSummary(
        goal: goal,
        targetAmount: goal.targetAmount,
        currentAmount: goal.currentAmount,
        progressPercentage: goal.progressPercentage,
        remainingAmount: goal.remainingAmount,
        linkedLoanForecast: linkedForecast,
      );
    }).toList();

    // 7. Loan Summaries
    final loanSummaries = loans.where((l) => l.active).map((loan) {
      final forecast = LoanForecastService.calculateForecast(loan);
      return LoanProgressSummary(
        loan: loan,
        currentEmi: loan.emiAmount,
        outstandingBalance: loan.outstandingPrincipal,
        forecast: forecast,
      );
    }).toList();

    return MonthlyReviewData(
      targetDate: targetDate,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netCashFlow: netCashFlow,
      totalPlannedExpense: totalPlanned,
      plannedVsActualDiff: diff.abs(),
      isAbovePlan: isAbovePlan,
      expenseCategoryBreakdown: expenseBreakdown,
      incomeCategoryBreakdown: incomeBreakdown,
      insights: insights,
      upcomingForecast: upcomingForecast,
      goalSummaries: goalSummaries,
      loanSummaries: loanSummaries,
    );
  }
}
