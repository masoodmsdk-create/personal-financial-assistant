import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/domain/services/loan_forecast_service.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/plans_progress/domain/models/plan_progress_models.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class PlanProgressService {
  const PlanProgressService();

  /// Evaluates progress, projection, variance, and explanation for a Loan
  LoanProgressItem evaluateLoanProgress(
    Loan loan, {
    List<Transaction> transactions = const [],
    DateTime? asOfDate,
  }) {
    final now = asOfDate ?? DateTime.now();
    final forecast = LoanForecastService.calculateForecast(loan, asOfDate: now);

    final outstanding =
        loan.outstandingPrincipal ?? loan.originalPrincipal ?? 0.0;
    final emi = loan.emiAmount ?? forecast.effectiveEmi ?? 0.0;
    final remainingEmis =
        forecast.estimatedRemainingTenureMonths ?? loan.remainingTenureMonths;
    final projectedClosure = forecast.estimatedClosureDate;
    final targetClosure = loan.targetClosureDate;

    DateTime? originalClosure;
    if (loan.startDate != null && loan.remainingTenureMonths != null) {
      originalClosure = loan.startDate!.add(
        Duration(days: loan.remainingTenureMonths! * 30),
      );
    }

    // 1. Check if paid off
    if (outstanding <= 0 &&
        (loan.originalPrincipal != null && loan.originalPrincipal! > 0)) {
      return LoanProgressItem(
        loan: loan,
        outstandingPrincipal: 0.0,
        emi: emi,
        remainingEmis: 0,
        originalClosureDate: originalClosure,
        targetClosureDate: targetClosure,
        projectedClosureDate: now,
        status: PlanProgressStatus.ahead,
        headline: 'Paid Off',
        explanation: 'This loan has zero outstanding balance.',
      );
    }

    // 2. Check for insufficient data
    if (outstanding <= 0 || emi <= 0) {
      return LoanProgressItem(
        loan: loan,
        outstandingPrincipal: outstanding,
        emi: emi,
        remainingEmis: remainingEmis,
        originalClosureDate: originalClosure,
        targetClosureDate: targetClosure,
        projectedClosureDate: projectedClosure,
        status: PlanProgressStatus.insufficientData,
        headline: 'Incomplete Details',
        explanation:
            'Enter current balance and EMI to calculate repayment projection.',
      );
    }

    // 3. Check for no target date
    if (targetClosure == null) {
      return LoanProgressItem(
        loan: loan,
        outstandingPrincipal: outstanding,
        emi: emi,
        remainingEmis: remainingEmis,
        originalClosureDate: originalClosure,
        targetClosureDate: null,
        projectedClosureDate: projectedClosure,
        status: PlanProgressStatus.noTarget,
        headline: 'Set Target Date',
        explanation: 'Set a target closure date to track repayment progress.',
      );
    }

    // 4. Check if projected closure couldn't be estimated
    if (projectedClosure == null) {
      return LoanProgressItem(
        loan: loan,
        outstandingPrincipal: outstanding,
        emi: emi,
        remainingEmis: remainingEmis,
        originalClosureDate: originalClosure,
        targetClosureDate: targetClosure,
        projectedClosureDate: null,
        status: PlanProgressStatus.insufficientData,
        headline: 'No Projection',
        explanation: 'Insufficient interest rate or tenure details to estimate closure date.',
      );
    }

    // 5. Evaluate target vs projected variance
    final varianceMonths =
        (projectedClosure.year - targetClosure.year) * 12 +
        (projectedClosure.month - targetClosure.month);

    final targetMonthStr = DateFormat('MMMM yyyy').format(targetClosure);

    if (targetClosure.isBefore(DateTime(now.year, now.month, 1)) &&
        outstanding > 0) {
      return LoanProgressItem(
        loan: loan,
        outstandingPrincipal: outstanding,
        emi: emi,
        remainingEmis: remainingEmis,
        originalClosureDate: originalClosure,
        targetClosureDate: targetClosure,
        projectedClosureDate: projectedClosure,
        varianceMonths: varianceMonths > 0 ? varianceMonths : 1,
        status: PlanProgressStatus.atRisk,
        headline: 'Target Date Passed',
        explanation:
            'Your target closure date was $targetMonthStr and the loan is still active.',
      );
    }

    if (varianceMonths <= -1) {
      final ahead = -varianceMonths;
      return LoanProgressItem(
        loan: loan,
        outstandingPrincipal: outstanding,
        emi: emi,
        remainingEmis: remainingEmis,
        originalClosureDate: originalClosure,
        targetClosureDate: targetClosure,
        projectedClosureDate: projectedClosure,
        varianceMonths: varianceMonths,
        status: PlanProgressStatus.ahead,
        headline: '$ahead month${ahead > 1 ? 's' : ''} ahead',
        explanation:
            'Your current repayment pace projects closure $ahead month${ahead > 1 ? 's' : ''} before your target.',
      );
    }

    if (varianceMonths == 0) {
      return LoanProgressItem(
        loan: loan,
        outstandingPrincipal: outstanding,
        emi: emi,
        remainingEmis: remainingEmis,
        originalClosureDate: originalClosure,
        targetClosureDate: targetClosure,
        projectedClosureDate: projectedClosure,
        varianceMonths: 0,
        status: PlanProgressStatus.onTrack,
        headline: 'On Track',
        explanation:
            'Your current repayment pace is on track for closure in $targetMonthStr.',
      );
    }

    if (varianceMonths <= 4) {
      return LoanProgressItem(
        loan: loan,
        outstandingPrincipal: outstanding,
        emi: emi,
        remainingEmis: remainingEmis,
        originalClosureDate: originalClosure,
        targetClosureDate: targetClosure,
        projectedClosureDate: projectedClosure,
        varianceMonths: varianceMonths,
        status: PlanProgressStatus.slightlyBehind,
        headline:
            '$varianceMonths month${varianceMonths > 1 ? 's' : ''} behind',
        explanation:
            'Your recorded extra prepayment is below the current plan.',
      );
    }

    return LoanProgressItem(
      loan: loan,
      outstandingPrincipal: outstanding,
      emi: emi,
      remainingEmis: remainingEmis,
      originalClosureDate: originalClosure,
      targetClosureDate: targetClosure,
      projectedClosureDate: projectedClosure,
      varianceMonths: varianceMonths,
      status: PlanProgressStatus.behind,
      headline: '$varianceMonths months behind',
      explanation:
          'Your current repayment pace projects closure $varianceMonths months after your target.',
    );
  }

  /// Evaluates progress, projection, variance, and explanation for a Goal
  GoalProgressItem evaluateGoalProgress(
    Goal goal, {
    List<Transaction> transactions = const [],
    DateTime? asOfDate,
  }) {
    final now = asOfDate ?? DateTime.now();
    final current = goal.currentAmount;
    final target = goal.targetAmount;
    final targetDate = goal.targetDate;
    final percentage = target > 0
        ? ((current / target) * 100).clamp(0.0, 100.0)
        : 0.0;

    // 1. Invalid or missing target amount
    if (target <= 0) {
      return GoalProgressItem(
        goal: goal,
        currentAmount: current,
        targetAmount: target,
        percentage: 0.0,
        targetDate: targetDate,
        status: PlanProgressStatus.insufficientData,
        headline: 'No Target Amount',
        explanation: 'Set a target savings amount to track goal progress.',
      );
    }

    // 2. Goal already achieved
    if (current >= target) {
      return GoalProgressItem(
        goal: goal,
        currentAmount: current,
        targetAmount: target,
        percentage: 100.0,
        targetDate: targetDate,
        projectedCompletionDate: now,
        status: PlanProgressStatus.ahead,
        headline: 'Goal Achieved',
        explanation:
            'You have reached 100% of your ₹${target.toStringAsFixed(0)} target.',
      );
    }

    // 3. Missing target date
    if (targetDate == null) {
      return GoalProgressItem(
        goal: goal,
        currentAmount: current,
        targetAmount: target,
        percentage: percentage,
        targetDate: null,
        status: PlanProgressStatus.noTarget,
        headline: 'Set Target Date',
        explanation:
            'Set a target date to track projected completion timeline.',
      );
    }

    // Calculate pace and projection
    final monthsElapsed = math.max(
      1,
      (now.year - goal.createdAt.year) * 12 +
          (now.month - goal.createdAt.month),
    );
    final actualMonthlyAverage = current / monthsElapsed;
    final remainingAmount = target - current;
    final monthsRemainingToTarget = math.max(
      1,
      (targetDate.year - now.year) * 12 + (targetDate.month - now.month),
    );
    final plannedMonthlyContribution =
        remainingAmount / monthsRemainingToTarget;
    final targetMonthStr = DateFormat('MMMM yyyy').format(targetDate);

    // 4. Overdue target date with remaining balance
    if (targetDate.isBefore(DateTime(now.year, now.month, 1)) &&
        remainingAmount > 0) {
      return GoalProgressItem(
        goal: goal,
        currentAmount: current,
        targetAmount: target,
        percentage: percentage,
        targetDate: targetDate,
        plannedMonthlyContribution: plannedMonthlyContribution,
        actualMonthlyAverage: actualMonthlyAverage,
        status: PlanProgressStatus.atRisk,
        headline: 'Target Date Passed',
        explanation:
            'Your target date was $targetMonthStr and ₹${remainingAmount.toStringAsFixed(0)} remains to be saved.',
      );
    }

    // 5. No contributions recorded yet
    if (current <= 0 || actualMonthlyAverage <= 0) {
      return GoalProgressItem(
        goal: goal,
        currentAmount: current,
        targetAmount: target,
        percentage: percentage,
        targetDate: targetDate,
        plannedMonthlyContribution: plannedMonthlyContribution,
        actualMonthlyAverage: 0.0,
        status: PlanProgressStatus.insufficientData,
        headline: 'No Contributions Yet',
        explanation: 'Not enough data to project completion yet. Start saving to project timeline.',
      );
    }

    // 6. Calculate projected completion date
    final estimatedMonths = (remainingAmount / actualMonthlyAverage).ceil();
    final projectedDate = now.add(Duration(days: estimatedMonths * 30));
    final varianceMonths =
        (projectedDate.year - targetDate.year) * 12 +
        (projectedDate.month - targetDate.month);

    if (varianceMonths <= -1) {
      final ahead = -varianceMonths;
      return GoalProgressItem(
        goal: goal,
        currentAmount: current,
        targetAmount: target,
        percentage: percentage,
        targetDate: targetDate,
        projectedCompletionDate: projectedDate,
        plannedMonthlyContribution: plannedMonthlyContribution,
        actualMonthlyAverage: actualMonthlyAverage,
        varianceMonths: varianceMonths,
        status: PlanProgressStatus.ahead,
        headline: '$ahead month${ahead > 1 ? 's' : ''} ahead',
        explanation:
            'Your current contribution pace projects completion $ahead month${ahead > 1 ? 's' : ''} before your target.',
      );
    }

    if (varianceMonths == 0) {
      return GoalProgressItem(
        goal: goal,
        currentAmount: current,
        targetAmount: target,
        percentage: percentage,
        targetDate: targetDate,
        projectedCompletionDate: projectedDate,
        plannedMonthlyContribution: plannedMonthlyContribution,
        actualMonthlyAverage: actualMonthlyAverage,
        varianceMonths: 0,
        status: PlanProgressStatus.onTrack,
        headline: 'On Track',
        explanation:
            'Your contribution pace of ₹${actualMonthlyAverage.toStringAsFixed(0)}/mo is on track to complete by $targetMonthStr.',
      );
    }

    if (varianceMonths <= 3) {
      return GoalProgressItem(
        goal: goal,
        currentAmount: current,
        targetAmount: target,
        percentage: percentage,
        targetDate: targetDate,
        projectedCompletionDate: projectedDate,
        plannedMonthlyContribution: plannedMonthlyContribution,
        actualMonthlyAverage: actualMonthlyAverage,
        varianceMonths: varianceMonths,
        status: PlanProgressStatus.slightlyBehind,
        headline:
            '$varianceMonths month${varianceMonths > 1 ? 's' : ''} behind',
        explanation:
            'Your current contribution pace projects completion about $varianceMonths month${varianceMonths > 1 ? 's' : ''} after your target.',
      );
    }

    return GoalProgressItem(
      goal: goal,
      currentAmount: current,
      targetAmount: target,
      percentage: percentage,
      targetDate: targetDate,
      projectedCompletionDate: projectedDate,
      plannedMonthlyContribution: plannedMonthlyContribution,
      actualMonthlyAverage: actualMonthlyAverage,
      varianceMonths: varianceMonths,
      status: PlanProgressStatus.behind,
      headline: '$varianceMonths months behind',
      explanation:
          'Your current contribution pace projects completion about $varianceMonths months after your target.',
    );
  }

  /// Generates the consolidated FinancialPlansSummary
  FinancialPlansSummary generateSummary({
    required List<Loan> loans,
    required List<Goal> goals,
    List<Transaction> transactions = const [],
    String? workspaceContext,
    List<String> workspacePriorities = const [],
    DateTime? asOfDate,
  }) {
    final activeLoans = loans.where((l) => l.active).toList();
    final activeGoals = goals.where((g) => g.active).toList();

    double totalLoanOutstanding = 0.0;
    double totalMonthlyEmi = 0.0;
    final loanItems = <LoanProgressItem>[];

    for (final loan in activeLoans) {
      final item = evaluateLoanProgress(
        loan,
        transactions: transactions,
        asOfDate: asOfDate,
      );
      loanItems.add(item);
      totalLoanOutstanding += item.outstandingPrincipal;
      totalMonthlyEmi += item.emi;
    }

    double totalGoalTarget = 0.0;
    double totalGoalCurrent = 0.0;
    final goalItems = <GoalProgressItem>[];

    for (final goal in activeGoals) {
      final item = evaluateGoalProgress(
        goal,
        transactions: transactions,
        asOfDate: asOfDate,
      );
      goalItems.add(item);
      totalGoalTarget += item.targetAmount;
      totalGoalCurrent += item.currentAmount;
    }

    int attentionCount = 0;
    attentionCount += loanItems.where((l) => l.status.needsAttention).length;
    attentionCount += goalItems.where((g) => g.status.needsAttention).length;

    // Prioritize top loans
    final sortedLoans = List<LoanProgressItem>.from(loanItems)
      ..sort((a, b) {
        // 1. Needs attention first
        if (a.status.needsAttention && !b.status.needsAttention) return -1;
        if (!a.status.needsAttention && b.status.needsAttention) return 1;
        // 2. Highest outstanding balance
        return b.outstandingPrincipal.compareTo(a.outstandingPrincipal);
      });

    // Prioritize top goals
    final sortedGoals = List<GoalProgressItem>.from(goalItems)
      ..sort((a, b) {
        // 1. Workspace context boost (e.g. emergency fund)
        final aIsEmergency = a.goal.type == GoalType.emergencyFund;
        final bIsEmergency = b.goal.type == GoalType.emergencyFund;
        final hasEmergencyPriority = workspacePriorities.any(
          (p) => p.toLowerCase().contains('emergency'),
        );
        if (hasEmergencyPriority) {
          if (aIsEmergency && !bIsEmergency) return -1;
          if (!aIsEmergency && bIsEmergency) return 1;
        }
        // 2. Needs attention
        if (a.status.needsAttention && !b.status.needsAttention) return -1;
        if (!a.status.needsAttention && b.status.needsAttention) return 1;
        // 3. Highest target amount
        return b.targetAmount.compareTo(a.targetAmount);
      });

    return FinancialPlansSummary(
      totalLoanOutstanding: totalLoanOutstanding,
      totalMonthlyEmi: totalMonthlyEmi,
      activeLoansCount: activeLoans.length,
      allLoanItems: loanItems,
      prioritizedLoanItems: sortedLoans.take(3).toList(),
      totalGoalTarget: totalGoalTarget,
      totalGoalCurrent: totalGoalCurrent,
      activeGoalsCount: activeGoals.length,
      allGoalItems: goalItems,
      prioritizedGoalItems: sortedGoals.take(3).toList(),
      attentionItemsCount: attentionCount,
    );
  }
}
