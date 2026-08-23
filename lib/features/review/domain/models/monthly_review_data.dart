import 'package:personal_financial_assistant/features/analytics/domain/models/financial_insight.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/domain/models/loan_forecast.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/transactions/domain/services/financial_aggregation_service.dart';

class UpcomingForecastData {
  final int year;
  final int month;
  final double expectedIncome;
  final double expectedExpenses;
  final double expectedNetPosition;
  final int plannedItemsCount;

  const UpcomingForecastData({
    required this.year,
    required this.month,
    required this.expectedIncome,
    required this.expectedExpenses,
    required this.expectedNetPosition,
    required this.plannedItemsCount,
  });
}

class GoalProgressSummary {
  final Goal goal;
  final double targetAmount;
  final double currentAmount;
  final double progressPercentage;
  final double remainingAmount;
  final LoanForecastResult? linkedLoanForecast;

  const GoalProgressSummary({
    required this.goal,
    required this.targetAmount,
    required this.currentAmount,
    required this.progressPercentage,
    required this.remainingAmount,
    this.linkedLoanForecast,
  });
}

class LoanProgressSummary {
  final Loan loan;
  final double? currentEmi;
  final double? outstandingBalance;
  final LoanForecastResult forecast;

  const LoanProgressSummary({
    required this.loan,
    this.currentEmi,
    this.outstandingBalance,
    required this.forecast,
  });
}

class MonthlyReviewData {
  final DateTime targetDate;
  final double totalIncome;
  final double totalExpense;
  final double netCashFlow;
  final double totalPlannedExpense;
  final double plannedVsActualDiff;
  final bool isAbovePlan;
  final List<CategoryBreakdownItem> expenseCategoryBreakdown;
  final List<CategoryBreakdownItem> incomeCategoryBreakdown;
  final List<FinancialInsight> insights;
  final UpcomingForecastData upcomingForecast;
  final List<GoalProgressSummary> goalSummaries;
  final List<LoanProgressSummary> loanSummaries;

  const MonthlyReviewData({
    required this.targetDate,
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashFlow,
    required this.totalPlannedExpense,
    required this.plannedVsActualDiff,
    required this.isAbovePlan,
    this.expenseCategoryBreakdown = const [],
    this.incomeCategoryBreakdown = const [],
    this.insights = const [],
    required this.upcomingForecast,
    this.goalSummaries = const [],
    this.loanSummaries = const [],
  });

  bool get hasTransactions => totalIncome > 0 || totalExpense > 0;
  bool get hasPlannedExpenses => totalPlannedExpense > 0;
}
