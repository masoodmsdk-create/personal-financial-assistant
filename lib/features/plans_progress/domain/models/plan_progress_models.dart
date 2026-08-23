import 'package:flutter/material.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';

enum PlanProgressStatus {
  ahead,
  onTrack,
  slightlyBehind,
  behind,
  atRisk,
  noTarget,
  insufficientData;

  String get displayName {
    switch (this) {
      case PlanProgressStatus.ahead:
        return 'Ahead';
      case PlanProgressStatus.onTrack:
        return 'On Track';
      case PlanProgressStatus.slightlyBehind:
        return 'Slightly Behind';
      case PlanProgressStatus.behind:
        return 'Behind';
      case PlanProgressStatus.atRisk:
        return 'At Risk';
      case PlanProgressStatus.noTarget:
        return 'No Target';
      case PlanProgressStatus.insufficientData:
        return 'Incomplete Data';
    }
  }

  Color get color {
    switch (this) {
      case PlanProgressStatus.ahead:
        return Colors.green;
      case PlanProgressStatus.onTrack:
        return Colors.teal;
      case PlanProgressStatus.slightlyBehind:
        return Colors.amber.shade800;
      case PlanProgressStatus.behind:
        return Colors.deepOrange;
      case PlanProgressStatus.atRisk:
        return Colors.red;
      case PlanProgressStatus.noTarget:
        return Colors.blueGrey;
      case PlanProgressStatus.insufficientData:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case PlanProgressStatus.ahead:
        return Icons.trending_up_rounded;
      case PlanProgressStatus.onTrack:
        return Icons.check_circle_outline_rounded;
      case PlanProgressStatus.slightlyBehind:
        return Icons.warning_amber_rounded;
      case PlanProgressStatus.behind:
        return Icons.error_outline_rounded;
      case PlanProgressStatus.atRisk:
        return Icons.crisis_alert_rounded;
      case PlanProgressStatus.noTarget:
        return Icons.flag_outlined;
      case PlanProgressStatus.insufficientData:
        return Icons.help_outline_rounded;
    }
  }

  bool get needsAttention =>
      this == PlanProgressStatus.slightlyBehind ||
      this == PlanProgressStatus.behind ||
      this == PlanProgressStatus.atRisk;
}

class LoanProgressItem {
  final Loan loan;
  final double outstandingPrincipal;
  final double emi;
  final int? remainingEmis;
  final DateTime? originalClosureDate;
  final DateTime? targetClosureDate;
  final DateTime? projectedClosureDate;
  final double? plannedAnnualPrepayment;
  final double? actualAnnualPrepayment;
  final int?
  varianceMonths; // Positive: months behind target; Negative: months ahead
  final PlanProgressStatus status;
  final String headline;
  final String explanation;

  const LoanProgressItem({
    required this.loan,
    required this.outstandingPrincipal,
    required this.emi,
    this.remainingEmis,
    this.originalClosureDate,
    this.targetClosureDate,
    this.projectedClosureDate,
    this.plannedAnnualPrepayment,
    this.actualAnnualPrepayment,
    this.varianceMonths,
    required this.status,
    required this.headline,
    required this.explanation,
  });

  bool get isCreditCard => loan.type == LoanType.creditCardDebt;
  bool get hasTarget => targetClosureDate != null;
  bool get hasProjection => projectedClosureDate != null;
}

class GoalProgressItem {
  final Goal goal;
  final double currentAmount;
  final double targetAmount;
  final double percentage;
  final DateTime? targetDate;
  final DateTime? projectedCompletionDate;
  final double? plannedMonthlyContribution;
  final double? actualMonthlyAverage;
  final int?
  varianceMonths; // Positive: months behind target; Negative: months ahead
  final PlanProgressStatus status;
  final String headline;
  final String explanation;

  const GoalProgressItem({
    required this.goal,
    required this.currentAmount,
    required this.targetAmount,
    required this.percentage,
    this.targetDate,
    this.projectedCompletionDate,
    this.plannedMonthlyContribution,
    this.actualMonthlyAverage,
    this.varianceMonths,
    required this.status,
    required this.headline,
    required this.explanation,
  });

  bool get isAchieved => currentAmount >= targetAmount && targetAmount > 0;
  bool get hasTargetDate => targetDate != null;
  bool get hasProjection => projectedCompletionDate != null;
}

class FinancialPlansSummary {
  final double totalLoanOutstanding;
  final double totalMonthlyEmi;
  final int activeLoansCount;
  final List<LoanProgressItem> allLoanItems;
  final List<LoanProgressItem> prioritizedLoanItems;

  final double totalGoalTarget;
  final double totalGoalCurrent;
  final int activeGoalsCount;
  final List<GoalProgressItem> allGoalItems;
  final List<GoalProgressItem> prioritizedGoalItems;

  final int attentionItemsCount;

  const FinancialPlansSummary({
    this.totalLoanOutstanding = 0.0,
    this.totalMonthlyEmi = 0.0,
    this.activeLoansCount = 0,
    this.allLoanItems = const [],
    this.prioritizedLoanItems = const [],
    this.totalGoalTarget = 0.0,
    this.totalGoalCurrent = 0.0,
    this.activeGoalsCount = 0,
    this.allGoalItems = const [],
    this.prioritizedGoalItems = const [],
    this.attentionItemsCount = 0,
  });

  bool get hasLoans => activeLoansCount > 0;
  bool get hasGoals => activeGoalsCount > 0;
  bool get hasPlans => hasLoans || hasGoals;
  double get overallGoalProgressPercentage => totalGoalTarget > 0
      ? ((totalGoalCurrent / totalGoalTarget) * 100).clamp(0.0, 100.0)
      : 0.0;
}
