import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/domain/models/loan_forecast.dart';
import 'package:personal_financial_assistant/features/loans/domain/models/what_if_scenario.dart';
import 'package:personal_financial_assistant/features/loans/domain/services/loan_forecast_service.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/trade_off/domain/models/trade_off_models.dart';

class TradeOffIntelligenceService {
  const TradeOffIntelligenceService();

  /// Compares Loan-First, Goal-First, Balanced, and Custom allocation strategies for extra cash flow.
  TradeOffComparisonResult compareStrategies({
    required double extraAmount,
    TradeOffAllocationType allocationType =
        TradeOffAllocationType.monthlyRecurring,
    Loan? loan,
    Goal? goal,
    List<Loan> availableLoans = const [],
    List<Goal> availableGoals = const [],
    double customSplitLoanPercentage = 50.0,
    List<String> workspacePriorities = const [],
    String? workspacePurpose,
    DateTime? asOfDate,
  }) {
    final now = asOfDate ?? DateTime.now();
    final clampedCustomPercent = customSplitLoanPercentage.clamp(0.0, 100.0);
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    // 1. Resolve Target Loan
    Loan? targetLoan = loan;
    if (targetLoan == null && availableLoans.isNotEmpty) {
      // Pick active loan with highest interest rate (or largest balance if rates tie)
      final activeLoans = availableLoans.where((l) => l.active).toList();
      if (activeLoans.isNotEmpty) {
        activeLoans.sort((a, b) {
          final rateComp = (b.interestRate ?? 0.0).compareTo(
            a.interestRate ?? 0.0,
          );
          if (rateComp != 0) return rateComp;
          final balA = a.outstandingPrincipal ?? a.originalPrincipal ?? 0.0;
          final balB = b.outstandingPrincipal ?? b.originalPrincipal ?? 0.0;
          return balB.compareTo(balA);
        });
        targetLoan = activeLoans.first;
      }
    }

    // 2. Resolve Target Goal
    Goal? targetGoal = goal;
    if (targetGoal == null && availableGoals.isNotEmpty) {
      // Pick active emergency fund first, or first incomplete goal
      final activeGoals = availableGoals
          .where((g) => g.active && !g.isCompleted)
          .toList();
      if (activeGoals.isNotEmpty) {
        targetGoal = activeGoals.firstWhere(
          (g) => g.type == GoalType.emergencyFund,
          orElse: () => activeGoals.first,
        );
      }
    }

    // 3. Validation: Check if we have sufficient inputs to compare
    if (targetLoan == null && targetGoal == null) {
      return TradeOffComparisonResult(
        extraAmount: extraAmount,
        allocationType: allocationType,
        selectedLoan: null,
        selectedGoal: null,
        strategies: const [],
        recommendedStrategy: null,
        recommendationRationale:
            'No active loans or goals available to evaluate trade-offs.',
        hasSufficientData: false,
        missingDataExplanation: 'Add at least one active Loan or Goal to evaluate trade-off strategies.',
        customSplitLoanPercentage: clampedCustomPercent,
        calculatedAt: now,
      );
    }

    // 4. Handle Zero or Negative Extra Cash
    if (extraAmount <= 0) {
      return TradeOffComparisonResult(
        extraAmount: extraAmount,
        allocationType: allocationType,
        selectedLoan: targetLoan,
        selectedGoal: targetGoal,
        strategies: const [],
        recommendedStrategy: null,
        recommendationRationale: 'Enter an extra cash flow amount greater than ₹0 to compare allocation strategies.',
        hasSufficientData: false,
        missingDataExplanation:
            'Extra cash flow amount must be greater than ₹0.',
        customSplitLoanPercentage: clampedCustomPercent,
        calculatedAt: now,
      );
    }

    // 5. Baseline Loan Calculations
    LoanForecastResult? baselineLoanForecast;
    if (targetLoan != null) {
      baselineLoanForecast = LoanForecastService.calculateForecast(
        targetLoan,
        asOfDate: now,
      );
    }

    // 6. Baseline Goal Calculations
    double goalRemainingAmount = 0.0;
    double baseGoalMonthlyPace = 0.0;
    int baselineGoalMonths = 0;

    if (targetGoal != null) {
      goalRemainingAmount = targetGoal.remainingAmount;
      if (goalRemainingAmount > 0) {
        if (targetGoal.targetDate != null &&
            targetGoal.targetDate!.isAfter(now)) {
          final diffMonths = math.max(
            1,
            (targetGoal.targetDate!.year - now.year) * 12 +
                (targetGoal.targetDate!.month - now.month),
          );
          baseGoalMonthlyPace = goalRemainingAmount / diffMonths;
        } else {
          // Default baseline contribution pace (estimate 12 months)
          baseGoalMonthlyPace = math.max(100.0, goalRemainingAmount / 12.0);
        }
        baselineGoalMonths = math.max(
          1,
          (goalRemainingAmount / baseGoalMonthlyPace).ceil(),
        );
      }
    }

    // 7. Calculate Loan-First Strategy (100% Loan)
    final loanFirstResult = _evaluateStrategy(
      strategy: TradeOffStrategy.loanFirst,
      loanPercentage: 100.0,
      goalPercentage: 0.0,
      extraAmount: extraAmount,
      allocationType: allocationType,
      targetLoan: targetLoan,
      baselineLoanForecast: baselineLoanForecast,
      targetGoal: targetGoal,
      goalRemainingAmount: goalRemainingAmount,
      baseGoalMonthlyPace: baseGoalMonthlyPace,
      baselineGoalMonths: baselineGoalMonths,
      maxPossibleInterestSaved: null, // Will compute
      now: now,
      currency: currency,
    );

    final maxPossibleInterestSaved = loanFirstResult.interestSaved;

    // 8. Calculate Goal-First Strategy (100% Goal)
    final goalFirstResult = _evaluateStrategy(
      strategy: TradeOffStrategy.goalFirst,
      loanPercentage: 0.0,
      goalPercentage: 100.0,
      extraAmount: extraAmount,
      allocationType: allocationType,
      targetLoan: targetLoan,
      baselineLoanForecast: baselineLoanForecast,
      targetGoal: targetGoal,
      goalRemainingAmount: goalRemainingAmount,
      baseGoalMonthlyPace: baseGoalMonthlyPace,
      baselineGoalMonths: baselineGoalMonths,
      maxPossibleInterestSaved: maxPossibleInterestSaved,
      now: now,
      currency: currency,
    );

    // 9. Calculate Balanced Strategy (50% Loan / 50% Goal)
    final balancedResult = _evaluateStrategy(
      strategy: TradeOffStrategy.balanced,
      loanPercentage: 50.0,
      goalPercentage: 50.0,
      extraAmount: extraAmount,
      allocationType: allocationType,
      targetLoan: targetLoan,
      baselineLoanForecast: baselineLoanForecast,
      targetGoal: targetGoal,
      goalRemainingAmount: goalRemainingAmount,
      baseGoalMonthlyPace: baseGoalMonthlyPace,
      baselineGoalMonths: baselineGoalMonths,
      maxPossibleInterestSaved: maxPossibleInterestSaved,
      now: now,
      currency: currency,
    );

    // 10. Calculate Custom Split Strategy
    final customResult = _evaluateStrategy(
      strategy: TradeOffStrategy.custom,
      loanPercentage: clampedCustomPercent,
      goalPercentage: 100.0 - clampedCustomPercent,
      extraAmount: extraAmount,
      allocationType: allocationType,
      targetLoan: targetLoan,
      baselineLoanForecast: baselineLoanForecast,
      targetGoal: targetGoal,
      goalRemainingAmount: goalRemainingAmount,
      baseGoalMonthlyPace: baseGoalMonthlyPace,
      baselineGoalMonths: baselineGoalMonths,
      maxPossibleInterestSaved: maxPossibleInterestSaved,
      now: now,
      currency: currency,
    );

    // 11. Determine Priority-Aware Recommendation
    final recommendation = _determineRecommendation(
      loanFirstResult: loanFirstResult,
      goalFirstResult: goalFirstResult,
      balancedResult: balancedResult,
      customResult: customResult,
      targetLoan: targetLoan,
      targetGoal: targetGoal,
      workspacePriorities: workspacePriorities,
      currency: currency,
    );

    // 12. Assemble Final Strategy List with Updated Badges
    final strategies = [
      loanFirstResult._copyWithRecommendation(
        isRecommended: recommendation.strategy == TradeOffStrategy.loanFirst,
        badge: recommendation.strategy == TradeOffStrategy.loanFirst
            ? recommendation.badge
            : null,
      ),
      goalFirstResult._copyWithRecommendation(
        isRecommended: recommendation.strategy == TradeOffStrategy.goalFirst,
        badge: recommendation.strategy == TradeOffStrategy.goalFirst
            ? recommendation.badge
            : null,
      ),
      balancedResult._copyWithRecommendation(
        isRecommended: recommendation.strategy == TradeOffStrategy.balanced,
        badge: recommendation.strategy == TradeOffStrategy.balanced
            ? recommendation.badge
            : null,
      ),
      customResult._copyWithRecommendation(
        isRecommended: recommendation.strategy == TradeOffStrategy.custom,
        badge: recommendation.strategy == TradeOffStrategy.custom
            ? recommendation.badge
            : null,
      ),
    ];

    final recommendedResult = strategies.firstWhere(
      (s) => s.strategy == recommendation.strategy,
      orElse: () => strategies.first,
    );

    return TradeOffComparisonResult(
      extraAmount: extraAmount,
      allocationType: allocationType,
      selectedLoan: targetLoan,
      selectedGoal: targetGoal,
      strategies: strategies,
      recommendedStrategy: recommendedResult,
      recommendationRationale: recommendation.rationale,
      hasSufficientData: true,
      customSplitLoanPercentage: clampedCustomPercent,
      calculatedAt: now,
    );
  }

  /// Internal strategy simulation helper
  TradeOffStrategyResult _evaluateStrategy({
    required TradeOffStrategy strategy,
    required double loanPercentage,
    required double goalPercentage,
    required double extraAmount,
    required TradeOffAllocationType allocationType,
    required Loan? targetLoan,
    required LoanForecastResult? baselineLoanForecast,
    required Goal? targetGoal,
    required double goalRemainingAmount,
    required double baseGoalMonthlyPace,
    required int baselineGoalMonths,
    required double? maxPossibleInterestSaved,
    required DateTime now,
    required NumberFormat currency,
  }) {
    final loanAllocation = (extraAmount * (loanPercentage / 100.0));
    final goalAllocation = (extraAmount * (goalPercentage / 100.0));

    // --- 1. Loan Simulation ---
    double interestSaved = 0.0;
    int loanMonthsSaved = 0;
    DateTime? newLoanClosureDate = baselineLoanForecast?.estimatedClosureDate;
    double? newLoanTenure = baselineLoanForecast?.estimatedRemainingTenureMonths
        ?.toDouble();
    String? warning;

    if (targetLoan != null &&
        baselineLoanForecast != null &&
        loanAllocation > 0) {
      final baseP =
          targetLoan.outstandingPrincipal ??
          targetLoan.originalPrincipal ??
          0.0;

      if (loanAllocation > baseP &&
          allocationType == TradeOffAllocationType.oneTimeLumpSum) {
        warning =
            'Prepayment exceeds outstanding principal (${currency.format(baseP)}).';
      }

      if (allocationType == TradeOffAllocationType.monthlyRecurring) {
        final scenario = LoanForecastService.calculateWhatIfScenario(
          loan: targetLoan,
          params: WhatIfScenarioParams(extraMonthlyAmount: loanAllocation),
          scenarioType: WhatIfType.extraMonthly,
          asOfDate: now,
        );
        interestSaved = scenario.estimatedInterestSaved;
        loanMonthsSaved = scenario.estimatedTimeSavedMonths;
        newLoanClosureDate = scenario.scenarioForecast.estimatedClosureDate;
        newLoanTenure = scenario.scenarioForecast.estimatedRemainingTenureMonths
            ?.toDouble();
      } else {
        final scenario = LoanForecastService.calculateWhatIfScenario(
          loan: targetLoan,
          params: WhatIfScenarioParams(lumpSumAmount: loanAllocation),
          scenarioType: WhatIfType.lumpSumPrepayment,
          asOfDate: now,
        );
        interestSaved = scenario.estimatedInterestSaved;
        loanMonthsSaved = scenario.estimatedTimeSavedMonths;
        newLoanClosureDate = scenario.scenarioForecast.estimatedClosureDate;
        newLoanTenure = scenario.scenarioForecast.estimatedRemainingTenureMonths
            ?.toDouble();
      }
    }

    // --- 2. Goal Simulation ---
    int goalMonthsSaved = 0;
    DateTime? projectedGoalCompletion;
    double newGoalProgressPercent = targetGoal?.progressPercentage ?? 0.0;

    if (targetGoal != null && goalAllocation > 0 && goalRemainingAmount > 0) {
      if (allocationType == TradeOffAllocationType.monthlyRecurring) {
        final newMonthlyPace = baseGoalMonthlyPace + goalAllocation;
        final newMonths = math.max(
          1,
          (goalRemainingAmount / newMonthlyPace).ceil(),
        );
        goalMonthsSaved = math.max(0, baselineGoalMonths - newMonths);
        projectedGoalCompletion = DateTime(
          now.year,
          now.month + newMonths,
          now.day,
        );
      } else {
        final effectiveNewRemaining = math.max(
          0.0,
          goalRemainingAmount - goalAllocation,
        );
        final newMonths = baseGoalMonthlyPace > 0
            ? math.max(0, (effectiveNewRemaining / baseGoalMonthlyPace).ceil())
            : 0;
        goalMonthsSaved = math.max(0, baselineGoalMonths - newMonths);
        projectedGoalCompletion = DateTime(
          now.year,
          now.month + newMonths,
          now.day,
        );

        final newCurrent =
            targetGoal.currentAmount +
            math.min(goalAllocation, goalRemainingAmount);
        newGoalProgressPercent = targetGoal.targetAmount > 0
            ? ((newCurrent / targetGoal.targetAmount) * 100).clamp(0.0, 100.0)
            : 100.0;
      }
    }

    // --- 3. Financial Semantics & Opportunity Cost ---
    final effectiveMaxInterest = maxPossibleInterestSaved ?? interestSaved;
    final opportunityCost = math.max(0.0, effectiveMaxInterest - interestSaved);
    final liquidityImpact = goalAllocation;

    // --- 4. Headline & Neutral Explanation ---
    String headline;
    String rationale;

    switch (strategy) {
      case TradeOffStrategy.loanFirst:
        if (targetLoan != null) {
          headline =
              'Saves ${currency.format(interestSaved)} interest • ${loanMonthsSaved}m earlier';
          rationale =
              'Directs 100% of your extra ${currency.format(extraAmount)} to debt prepayment, eliminating ${currency.format(interestSaved)} in total interest drain.';
        } else {
          headline = 'No active loan to prepay';
          rationale = '100% allocation toward loan cannot be simulated without an active loan.';
        }
        break;

      case TradeOffStrategy.goalFirst:
        if (targetGoal != null) {
          headline = goalMonthsSaved > 0
              ? 'Reaches goal ${goalMonthsSaved}m earlier • +${currency.format(liquidityImpact)} liquidity'
              : 'Adds ${currency.format(liquidityImpact)} to ${targetGoal.name}';
          rationale =
              'Builds liquid savings and accelerates ${targetGoal.name}. Foregoes ${currency.format(opportunityCost)} in potential loan interest savings.';
        } else {
          headline = 'No active goal selected';
          rationale = '100% allocation toward goal cannot be simulated without an active goal.';
        }
        break;

      case TradeOffStrategy.balanced:
        headline =
            'Saves ${currency.format(interestSaved)} interest • +${currency.format(liquidityImpact)} savings';
        rationale =
            'Splits extra cash equally (${currency.format(loanAllocation)} loan / ${currency.format(goalAllocation)} goal) to reduce debt while steadily building reserves.';
        break;

      case TradeOffStrategy.custom:
        headline =
            '${loanPercentage.toStringAsFixed(0)}% Loan (${currency.format(loanAllocation)}) • ${goalPercentage.toStringAsFixed(0)}% Goal (${currency.format(goalAllocation)})';
        rationale =
            'Allocates ${loanPercentage.toStringAsFixed(0)}% to save ${currency.format(interestSaved)} loan interest and ${goalPercentage.toStringAsFixed(0)}% to add ${currency.format(liquidityImpact)} to savings.';
        break;
    }

    return TradeOffStrategyResult(
      strategy: strategy,
      allocatedToLoan: loanAllocation,
      allocatedToGoal: goalAllocation,
      loanPercentage: loanPercentage,
      goalPercentage: goalPercentage,
      interestSaved: interestSaved,
      monthsSaved: loanMonthsSaved,
      newLoanClosureDate: newLoanClosureDate,
      newLoanTenureMonths: newLoanTenure,
      goalContribution: goalAllocation,
      goalMonthsSaved: goalMonthsSaved,
      projectedGoalCompletionDate: projectedGoalCompletion,
      newGoalProgressPercentage: newGoalProgressPercent,
      liquidityImpact: liquidityImpact,
      opportunityCost: opportunityCost,
      headline: headline,
      rationale: rationale,
      isViable:
          (targetLoan != null || loanPercentage == 0) &&
          (targetGoal != null || goalPercentage == 0),
      warningMessage: warning,
    );
  }

  /// Evaluates workspace priorities to determine the transparent recommendation
  _Recommendation _determineRecommendation({
    required TradeOffStrategyResult loanFirstResult,
    required TradeOffStrategyResult goalFirstResult,
    required TradeOffStrategyResult balancedResult,
    required TradeOffStrategyResult customResult,
    required Loan? targetLoan,
    required Goal? targetGoal,
    required List<String> workspacePriorities,
    required NumberFormat currency,
  }) {
    // 1. Single entity fallbacks
    if (targetLoan == null && targetGoal != null) {
      return const _Recommendation(
        strategy: TradeOffStrategy.goalFirst,
        badge: 'Only Active Goal Available',
        rationale: 'All extra cash flow is routed to your active goal since no active loans are configured.',
      );
    }
    if (targetGoal == null && targetLoan != null) {
      return const _Recommendation(
        strategy: TradeOffStrategy.loanFirst,
        badge: 'Only Active Loan Available',
        rationale: 'All extra cash flow is routed to your active loan since no active goals are configured.',
      );
    }

    // 2. Completed Goal check
    if (targetGoal != null && targetGoal.isCompleted) {
      return const _Recommendation(
        strategy: TradeOffStrategy.loanFirst,
        badge: 'Goal Completed (100%)',
        rationale: 'Your selected goal is already fully funded. Directing extra funds to debt maximizes financial efficiency.',
      );
    }

    final prioritiesLower = workspacePriorities
        .map((p) => p.toLowerCase())
        .toList();
    final hasDebtPriority = prioritiesLower.any(
      (p) => p.contains('debt') || p.contains('loan'),
    );
    final hasSavePriority = prioritiesLower.any(
      (p) => p.contains('save') || p.contains('goal'),
    );
    final hasEmergencyPriority = prioritiesLower.any(
      (p) => p.contains('emergency'),
    );

    // 3. Emergency Fund Inadequacy Guardrail
    if (targetGoal != null && targetGoal.type == GoalType.emergencyFund) {
      final emergencyFundPercentage = targetGoal.progressPercentage;
      if (emergencyFundPercentage < 50.0) {
        if (hasDebtPriority && (targetLoan?.interestRate ?? 0.0) >= 12.0) {
          // High interest debt + low emergency fund -> Recommend Balanced
          return _Recommendation(
            strategy: TradeOffStrategy.balanced,
            badge: 'Balanced Safety & High-Interest Payoff',
            rationale:
                'Your Emergency Fund is below 50%, but your loan interest is high (${targetLoan!.interestRate}%). A 50/50 split builds critical liquidity while cutting expensive debt.',
          );
        }
        return _Recommendation(
          strategy: TradeOffStrategy.goalFirst,
          badge: 'Emergency Liquidity Priority',
          rationale:
              'Your Emergency Fund is currently at ${emergencyFundPercentage.toStringAsFixed(0)}% of target. Building a baseline safety cushion protects against future debt.',
        );
      }
    }

    // 4. Priority = Reduce Debt
    if (hasDebtPriority && !hasSavePriority) {
      return _Recommendation(
        strategy: TradeOffStrategy.loanFirst,
        badge: 'Matches "Reduce Debt" Priority',
        rationale:
            'Directing 100% to your loan eliminates ${currency.format(loanFirstResult.interestSaved)} in interest and cuts ${loanFirstResult.monthsSaved} months, directly fulfilling your debt reduction priority.',
      );
    }

    // 5. Priority = Save for a Goal
    if (hasSavePriority && !hasDebtPriority && !hasEmergencyPriority) {
      return _Recommendation(
        strategy: TradeOffStrategy.goalFirst,
        badge: 'Matches "Save for Goal" Priority',
        rationale:
            'Directing 100% to ${targetGoal?.name ?? "your goal"} accelerates completion by ${goalFirstResult.goalMonthsSaved} months, directly fulfilling your savings priority.',
      );
    }

    // 6. High Interest Rate Drag (> 10%)
    final interestRate = targetLoan?.interestRate ?? 0.0;
    if (interestRate >= 10.0) {
      return _Recommendation(
        strategy: TradeOffStrategy.loanFirst,
        badge: 'High Interest Rate (${interestRate.toStringAsFixed(1)}%)',
        rationale:
            'At ${interestRate.toStringAsFixed(1)}% interest, debt prepayment provides a guaranteed high-yield return of ${currency.format(loanFirstResult.interestSaved)} in saved interest.',
      );
    }

    // 7. Default Balanced Recommendation
    return _Recommendation(
      strategy: TradeOffStrategy.balanced,
      badge: 'Balanced Growth & Debt Relief',
      rationale:
          'A 50/50 split achieves the optimal balance: saving ${currency.format(balancedResult.interestSaved)} in loan interest while simultaneously growing ${currency.format(balancedResult.liquidityImpact)} in goal savings.',
    );
  }
}

class _Recommendation {
  final TradeOffStrategy strategy;
  final String badge;
  final String rationale;

  const _Recommendation({
    required this.strategy,
    required this.badge,
    required this.rationale,
  });
}

extension on TradeOffStrategyResult {
  TradeOffStrategyResult _copyWithRecommendation({
    required bool isRecommended,
    String? badge,
  }) {
    return TradeOffStrategyResult(
      strategy: strategy,
      allocatedToLoan: allocatedToLoan,
      allocatedToGoal: allocatedToGoal,
      loanPercentage: loanPercentage,
      goalPercentage: goalPercentage,
      interestSaved: interestSaved,
      monthsSaved: monthsSaved,
      newLoanClosureDate: newLoanClosureDate,
      newLoanTenureMonths: newLoanTenureMonths,
      goalContribution: goalContribution,
      goalMonthsSaved: goalMonthsSaved,
      projectedGoalCompletionDate: projectedGoalCompletionDate,
      newGoalProgressPercentage: newGoalProgressPercentage,
      liquidityImpact: liquidityImpact,
      opportunityCost: opportunityCost,
      headline: headline,
      rationale: rationale,
      isRecommended: isRecommended,
      recommendationBadge: badge,
      isViable: isViable,
      warningMessage: warningMessage,
    );
  }
}
