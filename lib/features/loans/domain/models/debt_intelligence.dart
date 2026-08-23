import 'package:flutter/material.dart';
import 'package:personal_financial_assistant/features/loans/domain/models/loan_forecast.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';

/// Detailed breakdown of interest cost and next 12-month trajectory for a specific loan.
class LoanInterestAnalysis {
  final double totalRemainingPrincipal;
  final double estimatedRemainingInterest;
  final double totalRemainingRepayment;
  final double interestPercentageOfRepayment; // e.g. 42.5%
  final double next12MonthsPrincipal;
  final double next12MonthsInterest;
  final double next12MonthsTotalPayment;
  final double? effectiveAnnualCost;

  const LoanInterestAnalysis({
    required this.totalRemainingPrincipal,
    required this.estimatedRemainingInterest,
    required this.totalRemainingRepayment,
    required this.interestPercentageOfRepayment,
    required this.next12MonthsPrincipal,
    required this.next12MonthsInterest,
    required this.next12MonthsTotalPayment,
    this.effectiveAnnualCost,
  });
}

/// Portfolio-wide aggregation and comparative analytics across all user debts.
class DebtPortfolioSummary {
  final int totalLoansCount;
  final int activeLoansCount;
  final double totalOutstandingDebt;
  final double totalMonthlyEmi;
  final double estimatedTotalRemainingInterest;
  final double? weightedAverageInterestRate;
  final Loan? highestInterestRateLoan;
  final Loan? highestInterestCostLoan;
  final Loan? largestBalanceLoan;
  final DateTime? earliestEstimatedClosure;
  final DateTime? latestEstimatedClosure;
  final double? recordedMonthlyIncome;
  final double? debtToIncomeRatio; // Percentage (e.g. 35.0%)

  const DebtPortfolioSummary({
    required this.totalLoansCount,
    required this.activeLoansCount,
    required this.totalOutstandingDebt,
    required this.totalMonthlyEmi,
    required this.estimatedTotalRemainingInterest,
    this.weightedAverageInterestRate,
    this.highestInterestRateLoan,
    this.highestInterestCostLoan,
    this.largestBalanceLoan,
    this.earliestEstimatedClosure,
    this.latestEstimatedClosure,
    this.recordedMonthlyIncome,
    this.debtToIncomeRatio,
  });

  bool get hasActiveLoans => activeLoansCount > 0;
  bool get hasMultipleLoans => activeLoansCount > 1;
}

enum DebtStrategyType {
  avalanche,
  snowball,
  cashFlowRelief,
  highestInterestSavings,
}

extension DebtStrategyTypeX on DebtStrategyType {
  String get displayName {
    switch (this) {
      case DebtStrategyType.avalanche:
        return 'Debt Avalanche (Highest Rate)';
      case DebtStrategyType.snowball:
        return 'Debt Snowball (Smallest Balance)';
      case DebtStrategyType.cashFlowRelief:
        return 'Cash Flow Relief (Quickest Payoff)';
      case DebtStrategyType.highestInterestSavings:
        return 'Max Interest Savings (Total Cost)';
    }
  }

  String get shortName {
    switch (this) {
      case DebtStrategyType.avalanche:
        return 'Avalanche';
      case DebtStrategyType.snowball:
        return 'Snowball';
      case DebtStrategyType.cashFlowRelief:
        return 'Cash Flow';
      case DebtStrategyType.highestInterestSavings:
        return 'Max Savings';
    }
  }

  IconData get icon {
    switch (this) {
      case DebtStrategyType.avalanche:
        return Icons.trending_down_rounded;
      case DebtStrategyType.snowball:
        return Icons.ac_unit_rounded;
      case DebtStrategyType.cashFlowRelief:
        return Icons.water_drop_outlined;
      case DebtStrategyType.highestInterestSavings:
        return Icons.savings_outlined;
    }
  }
}

class PrioritizedLoanItem {
  final int rank;
  final Loan loan;
  final LoanForecastResult forecast;
  final String rationale;
  final double monthlyEmiFreed;
  final double remainingInterest;

  const PrioritizedLoanItem({
    required this.rank,
    required this.loan,
    required this.forecast,
    required this.rationale,
    required this.monthlyEmiFreed,
    required this.remainingInterest,
  });
}

class DebtPrioritizationPlan {
  final DebtStrategyType strategy;
  final String strategyName;
  final String strategyDescription;
  final String tradeOffExplanation;
  final List<PrioritizedLoanItem> prioritizedLoans;
  final double totalMonthlyEmiToFree;

  const DebtPrioritizationPlan({
    required this.strategy,
    required this.strategyName,
    required this.strategyDescription,
    required this.tradeOffExplanation,
    required this.prioritizedLoans,
    required this.totalMonthlyEmiToFree,
  });
}

class RefinanceAnalysisResult {
  final Loan loan;
  final double currentRate;
  final double scenarioRate;
  final double currentRemainingInterest;
  final double scenarioRemainingInterest;
  final double grossInterestSaved;
  final double estimatedRefinanceCost;
  final double netSavings;
  final int? breakEvenMonths;
  final String recommendationSummary;

  const RefinanceAnalysisResult({
    required this.loan,
    required this.currentRate,
    required this.scenarioRate,
    required this.currentRemainingInterest,
    required this.scenarioRemainingInterest,
    required this.grossInterestSaved,
    required this.estimatedRefinanceCost,
    required this.netSavings,
    this.breakEvenMonths,
    required this.recommendationSummary,
  });

  bool get isFinanciallyBeneficial => netSavings > 0;
}

enum LoanInsightSeverity { info, opportunity, warning }

class LoanInsight {
  final String id;
  final String title;
  final String message;
  final LoanInsightSeverity severity;
  final String? loanId;
  final String? actionLabel;

  const LoanInsight({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    this.loanId,
    this.actionLabel,
  });
}
