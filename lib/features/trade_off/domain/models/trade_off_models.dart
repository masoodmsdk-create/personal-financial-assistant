import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';

/// The allocation strategy for extra cash flow between debt prepayment and goal savings.
enum TradeOffStrategy {
  loanFirst('loanFirst'),
  goalFirst('goalFirst'),
  balanced('balanced'),
  custom('custom');

  final String value;
  const TradeOffStrategy(this.value);

  String get displayName {
    switch (this) {
      case TradeOffStrategy.loanFirst:
        return 'Loan-First';
      case TradeOffStrategy.goalFirst:
        return 'Goal-First';
      case TradeOffStrategy.balanced:
        return 'Balanced (50/50)';
      case TradeOffStrategy.custom:
        return 'Custom Split';
    }
  }

  String get shortDescription {
    switch (this) {
      case TradeOffStrategy.loanFirst:
        return '100% toward debt prepayment to minimize interest drain.';
      case TradeOffStrategy.goalFirst:
        return '100% toward savings/emergency goal to build liquidity faster.';
      case TradeOffStrategy.balanced:
        return '50% debt reduction + 50% goal savings for dual progress.';
      case TradeOffStrategy.custom:
        return 'User-defined percentage allocation between loan and goal.';
    }
  }
}

/// The frequency/nature of the extra cash flow being allocated.
enum TradeOffAllocationType {
  monthlyRecurring('monthlyRecurring'),
  oneTimeLumpSum('oneTimeLumpSum');

  final String value;
  const TradeOffAllocationType(this.value);

  String get displayName {
    switch (this) {
      case TradeOffAllocationType.monthlyRecurring:
        return 'Monthly Extra Cash';
      case TradeOffAllocationType.oneTimeLumpSum:
        return 'One-Time Lump Sum';
    }
  }
}

/// Evaluated financial outcome metrics for a specific allocation strategy.
class TradeOffStrategyResult {
  final TradeOffStrategy strategy;
  final double allocatedToLoan;
  final double allocatedToGoal;
  final double loanPercentage;
  final double goalPercentage;

  // Loan Impact Metrics
  final double interestSaved;
  final int monthsSaved;
  final DateTime? newLoanClosureDate;
  final double? newLoanTenureMonths;

  // Goal Impact Metrics
  final double goalContribution;
  final int goalMonthsSaved;
  final DateTime? projectedGoalCompletionDate;
  final double newGoalProgressPercentage;

  // Financial Semantics & Trade-Offs
  final double liquidityImpact;
  final double
  opportunityCost; // Foregone loan interest savings compared to 100% Loan-First
  final String headline;
  final String rationale;
  final bool isRecommended;
  final String? recommendationBadge;
  final bool isViable;
  final String? warningMessage;

  const TradeOffStrategyResult({
    required this.strategy,
    required this.allocatedToLoan,
    required this.allocatedToGoal,
    required this.loanPercentage,
    required this.goalPercentage,
    required this.interestSaved,
    required this.monthsSaved,
    this.newLoanClosureDate,
    this.newLoanTenureMonths,
    required this.goalContribution,
    required this.goalMonthsSaved,
    this.projectedGoalCompletionDate,
    required this.newGoalProgressPercentage,
    required this.liquidityImpact,
    required this.opportunityCost,
    required this.headline,
    required this.rationale,
    this.isRecommended = false,
    this.recommendationBadge,
    this.isViable = true,
    this.warningMessage,
  });
}

/// Complete multi-strategy comparative result with context-aware recommendations.
class TradeOffComparisonResult {
  final double extraAmount;
  final TradeOffAllocationType allocationType;
  final Loan? selectedLoan;
  final Goal? selectedGoal;
  final List<TradeOffStrategyResult> strategies;
  final TradeOffStrategyResult? recommendedStrategy;
  final String recommendationRationale;
  final bool hasSufficientData;
  final String? missingDataExplanation;
  final double customSplitLoanPercentage;
  final DateTime calculatedAt;

  const TradeOffComparisonResult({
    required this.extraAmount,
    required this.allocationType,
    this.selectedLoan,
    this.selectedGoal,
    required this.strategies,
    this.recommendedStrategy,
    required this.recommendationRationale,
    required this.hasSufficientData,
    this.missingDataExplanation,
    this.customSplitLoanPercentage = 50.0,
    required this.calculatedAt,
  });

  /// Helper getter to quickly find a strategy outcome
  TradeOffStrategyResult? getStrategyResult(TradeOffStrategy strategy) {
    try {
      return strategies.firstWhere((s) => s.strategy == strategy);
    } catch (_) {
      return null;
    }
  }
}
