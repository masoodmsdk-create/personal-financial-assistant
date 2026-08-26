import 'dart:math' as math;

import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/domain/models/account_type_definition.dart';
import 'package:personal_financial_assistant/features/budgets/domain/models/budget.dart';
import 'package:personal_financial_assistant/features/forecast/domain/models/multi_horizon_forecast.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class MultiHorizonForecastService {
  const MultiHorizonForecastService();

  /// Calculates a full deterministic multi-horizon projection across 1M, 4M, 6M, 12M
  MultiHorizonForecastResult calculateMultiHorizonForecast({
    required List<Account> accounts,
    required List<RecurringTransactionRule> recurringRules,
    required List<Loan> loans,
    required List<Goal> goals,
    required List<PlannedExpense> plannedExpenses,
    List<Budget> budgets = const [],
    Map<String, double>? dynamicBalances,
    DateTime? asOfDate,
  }) {
    final now = asOfDate ?? DateTime.now();

    // 1. Current Asset & Liability Baselines
    double currentLiquidSavings = 0.0;
    double currentCreditCardDebt = 0.0;

    for (final acc in accounts.where((a) => a.active)) {
      final balance = dynamicBalances?[acc.id] ?? acc.openingBalance;
      if (acc.nature == AccountNature.asset) {
        currentLiquidSavings += balance;
      } else {
        currentCreditCardDebt += balance.abs();
      }
    }

    final activeLoans = loans.where((l) => l.active).toList();
    final double startingLoanPrincipal = activeLoans.fold<double>(
      0.0,
      (sum, l) => sum + (l.outstandingPrincipal ?? l.originalPrincipal ?? 0.0),
    );

    final double currentTotalDebt =
        currentCreditCardDebt + startingLoanPrincipal;
    final double currentNetWorth = currentLiquidSavings - currentTotalDebt;

    // 2. Authoritative Monthly Inflows & Commitments
    final activeIncomeRules = recurringRules.where(
      (r) => r.active && r.type == TransactionType.income,
    );
    final double monthlyIncome = activeIncomeRules.fold<double>(0.0, (sum, r) {
      return sum + _normalizeToMonthly(r.amount, r.frequency);
    });

    final activeExpenseRules = recurringRules.where(
      (r) => r.active && r.type == TransactionType.expense,
    );
    final double monthlyRecurringExpenses = activeExpenseRules.fold<double>(
      0.0,
      (sum, r) {
        return sum + _normalizeToMonthly(r.amount, r.frequency);
      },
    );

    final activePlans = plannedExpenses.where((p) => p.active);
    final double monthlyPlannedExpenses = activePlans.fold<double>(
      0.0,
      (sum, p) => sum + p.defaultAmount,
    );

    // Sum variable budget amounts where not covered by recurring
    final double monthlyBudgetsAmount = budgets.fold<double>(
      0.0,
      (sum, b) => sum + b.plannedAmount,
    );
    final double monthlyLivingExpenses = math.max(
      monthlyRecurringExpenses + monthlyPlannedExpenses,
      monthlyBudgetsAmount > 0
          ? monthlyBudgetsAmount
          : (monthlyRecurringExpenses + monthlyPlannedExpenses),
    );

    final double monthlyLoanEmis = activeLoans.fold<double>(
      0.0,
      (sum, l) => sum + (l.emiAmount ?? 0.0),
    );

    final double monthlyCommitments = monthlyLivingExpenses + monthlyLoanEmis;
    final double monthlyNetCashFlow = monthlyIncome - monthlyCommitments;

    // 3. Project each horizon (1, 4, 6, 12, 24, 36)
    final horizonMonthsList = [1, 4, 6, 12, 24, 36];
    final List<HorizonProjection> projections = [];

    for (final m in horizonMonthsList) {
      final targetDate = DateTime(now.year, now.month + m, now.day);
      final cumulativeIncome = monthlyIncome * m;
      final cumulativeLivingExpenses = monthlyLivingExpenses * m;
      final cumulativeLoanEmis = monthlyLoanEmis * m;
      final cumulativeCommitments = monthlyCommitments * m;
      final cumulativeNetCashFlow = monthlyNetCashFlow * m;

      final projectedSavings = math.max(
        0.0,
        currentLiquidSavings + cumulativeNetCashFlow,
      );

      // Loan Amortization Simulation after m months
      final loanSimulation = _simulateLoansAmortization(activeLoans, m);
      final projectedLoanPrincipal =
          loanSimulation.totalRemainingPrincipal + currentCreditCardDebt;
      final projectedNetWorth = projectedSavings - projectedLoanPrincipal;

      // Goal Progression Simulation
      final goalSimulation = _simulateGoalProgression(
        goals,
        cumulativeNetCashFlow,
        m,
      );

      ForecastHealthStatus status;
      if (monthlyNetCashFlow >= 0 && projectedSavings > 0) {
        status = ForecastHealthStatus.healthy;
      } else if (monthlyNetCashFlow >= 0 && projectedSavings == 0) {
        status = ForecastHealthStatus.tight;
      } else {
        status = ForecastHealthStatus.deficit;
      }

      projections.add(
        HorizonProjection(
          months: m,
          targetDate: targetDate,
          projectedMonthlyIncome: monthlyIncome,
          projectedMonthlyLivingExpenses: monthlyLivingExpenses,
          projectedMonthlyLoanEmis: monthlyLoanEmis,
          projectedMonthlyCommitments: monthlyCommitments,
          projectedMonthlyNetCashFlow: monthlyNetCashFlow,
          cumulativeIncome: cumulativeIncome,
          cumulativeLivingExpenses: cumulativeLivingExpenses,
          cumulativeLoanEmis: cumulativeLoanEmis,
          cumulativeCommitments: cumulativeCommitments,
          cumulativeNetCashFlow: cumulativeNetCashFlow,
          startingSavings: currentLiquidSavings,
          projectedSavings: projectedSavings,
          startingLoanPrincipal: startingLoanPrincipal,
          projectedLoanPrincipal: projectedLoanPrincipal,
          projectedNetWorth: projectedNetWorth,
          loansClosed: loanSimulation.closedLoanNames,
          goalsAchieved: goalSimulation.achievedGoalNames,
          goalProgressMap: goalSimulation.goalProgress,
          status: status,
        ),
      );
    }

    return MultiHorizonForecastResult(
      asOfDate: now,
      currentLiquidSavings: currentLiquidSavings,
      currentTotalDebt: currentTotalDebt,
      currentNetWorth: currentNetWorth,
      monthlyRecurringIncome: monthlyIncome,
      monthlyRecurringExpenses: monthlyLivingExpenses,
      monthlyLoanEmis: monthlyLoanEmis,
      monthlyNetCashFlow: monthlyNetCashFlow,
      month1: projections.firstWhere((h) => h.months == 1),
      month4: projections.firstWhere((h) => h.months == 4),
      month6: projections.firstWhere((h) => h.months == 6),
      month12: projections.firstWhere((h) => h.months == 12),
      allHorizons: projections,
    );
  }

  /// Calculates What-If scenario comparisons vs Baseline
  List<ScenarioComparison> calculateScenarioComparisons(
    MultiHorizonForecastResult baseline,
  ) {
    final List<ScenarioComparison> comparisons = [];
    final baseline12 = baseline.month12;

    // Scenario A: Extra Savings (+₹5,000/mo)
    final extraSavings12 = baseline12.projectedSavings + (5000.0 * 12);
    final extraNetWorth12 = baseline12.projectedNetWorth + (5000.0 * 12);
    comparisons.add(
      ScenarioComparison(
        scenarioName: 'Accelerate Savings (+₹5,000/mo)',
        description: 'Saving an additional ₹5,000 per month by curbing discretionary spending.',
        baseline12mSavings: baseline12.projectedSavings,
        scenario12mSavings: extraSavings12,
        baseline12mDebt: baseline12.projectedLoanPrincipal,
        scenario12mDebt: baseline12.projectedLoanPrincipal,
        baseline12mNetWorth: baseline12.projectedNetWorth,
        scenario12mNetWorth: extraNetWorth12,
        netImprovement: 60000.0,
        outcomeExplanation: 'Adds ₹60,000 directly to your liquid safety net and boosts 1-year Net Worth.',
      ),
    );

    // Scenario B: Extra Savings (+₹10,000/mo)
    final extra10kSavings12 = baseline12.projectedSavings + (10000.0 * 12);
    final extra10kNetWorth12 = baseline12.projectedNetWorth + (10000.0 * 12);
    comparisons.add(
      ScenarioComparison(
        scenarioName: 'Aggressive Wealth Pace (+₹10,000/mo)',
        description: 'Channeling bonus/freelance or living lean to save ₹10,000 extra monthly.',
        baseline12mSavings: baseline12.projectedSavings,
        scenario12mSavings: extra10kSavings12,
        baseline12mDebt: baseline12.projectedLoanPrincipal,
        scenario12mDebt: baseline12.projectedLoanPrincipal,
        baseline12mNetWorth: baseline12.projectedNetWorth,
        scenario12mNetWorth: extra10kNetWorth12,
        netImprovement: 120000.0,
        outcomeExplanation:
            'Builds an additional ₹1,20,000 in reserves over 12 months.',
      ),
    );

    // Scenario C: Loan Prepayment (+₹5,000/mo towards debt)
    if (baseline.currentTotalDebt > 0) {
      final reducedDebt12 = math.max(
        0.0,
        baseline12.projectedLoanPrincipal - (5000.0 * 12),
      );
      final prepayNetWorth12 =
          baseline12.projectedNetWorth +
          (5000.0 * 12 * 0.1); // approx interest avoided
      comparisons.add(
        ScenarioComparison(
          scenarioName: 'Loan Prepayment (+₹5,000/mo to Principal)',
          description: 'Applying ₹5,000 extra monthly payment to accelerate loan amortization.',
          baseline12mSavings: baseline12.projectedSavings - (5000.0 * 12),
          scenario12mSavings: baseline12.projectedSavings - (5000.0 * 12),
          baseline12mDebt: baseline12.projectedLoanPrincipal,
          scenario12mDebt: reducedDebt12,
          baseline12mNetWorth: baseline12.projectedNetWorth,
          scenario12mNetWorth: prepayNetWorth12 + baseline12.projectedNetWorth,
          netImprovement: 60000.0,
          outcomeExplanation: 'Reduces outstanding debt by ₹60,000 faster and saves substantial future interest.',
        ),
      );
    }

    return comparisons;
  }

  // Internal Helpers
  static double _normalizeToMonthly(double amount, RecurrenceFrequency freq) {
    switch (freq) {
      case RecurrenceFrequency.daily:
        return amount * 30.0;
      case RecurrenceFrequency.weekly:
        return amount * (52.0 / 12.0);
      case RecurrenceFrequency.monthly:
        return amount;
      case RecurrenceFrequency.quarterly:
        return amount / 3.0;
      case RecurrenceFrequency.halfYearly:
        return amount / 6.0;
      case RecurrenceFrequency.yearly:
        return amount / 12.0;
      case RecurrenceFrequency.oneTime:
        return 0.0;
    }
  }

  static _LoanAmortizationSimulationResult _simulateLoansAmortization(
    List<Loan> loans,
    int months,
  ) {
    double totalRemaining = 0.0;
    final List<String> closedLoans = [];

    for (final loan in loans) {
      final P = loan.outstandingPrincipal ?? loan.originalPrincipal ?? 0.0;
      final emi = loan.emiAmount ?? 0.0;
      final rate = (loan.interestRate ?? 0.0) / 1200.0;

      var currentP = P;
      for (int m = 1; m <= months; m++) {
        if (currentP <= 0) break;
        final interest = currentP * rate;
        final principalPaid = emi - interest;
        if (principalPaid > 0) {
          currentP -= principalPaid;
        } else {
          currentP -= emi;
        }
        if (currentP <= 0) {
          currentP = 0.0;
          closedLoans.add(loan.name);
          break;
        }
      }
      totalRemaining += currentP;
    }

    return _LoanAmortizationSimulationResult(
      totalRemainingPrincipal: totalRemaining,
      closedLoanNames: closedLoans,
    );
  }

  static _GoalProgressionSimulationResult _simulateGoalProgression(
    List<Goal> goals,
    double cumulativeSurplus,
    int months,
  ) {
    final Map<String, double> progress = {};
    final List<String> achieved = [];

    final activeGoals = goals.where((g) => g.active).toList();
    if (activeGoals.isEmpty) {
      return _GoalProgressionSimulationResult(
        goalProgress: progress,
        achievedGoalNames: achieved,
      );
    }

    // Allocate 50% of positive cash flow surplus towards goals
    final allocatableSurplus = cumulativeSurplus > 0
        ? (cumulativeSurplus * 0.5)
        : 0.0;
    final perGoalSurplus = allocatableSurplus / activeGoals.length;

    for (final goal in activeGoals) {
      final current = goal.currentAmount;
      final target = goal.targetAmount;
      final projected = current + perGoalSurplus;
      progress[goal.id] = projected;
      if (projected >= target) {
        achieved.add(goal.name);
      }
    }

    return _GoalProgressionSimulationResult(
      goalProgress: progress,
      achievedGoalNames: achieved,
    );
  }
}

class _LoanAmortizationSimulationResult {
  final double totalRemainingPrincipal;
  final List<String> closedLoanNames;
  const _LoanAmortizationSimulationResult({
    required this.totalRemainingPrincipal,
    required this.closedLoanNames,
  });
}

class _GoalProgressionSimulationResult {
  final Map<String, double> goalProgress;
  final List<String> achievedGoalNames;
  const _GoalProgressionSimulationResult({
    required this.goalProgress,
    required this.achievedGoalNames,
  });
}
