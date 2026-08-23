import 'dart:math' as math;

import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/domain/models/debt_intelligence.dart';
import 'package:personal_financial_assistant/features/loans/domain/models/loan_forecast.dart';
import 'package:personal_financial_assistant/features/loans/domain/services/loan_forecast_service.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';

/// Pure deterministic financial calculation and intelligence engine for debt analysis.
class DebtIntelligenceService {
  const DebtIntelligenceService();

  /// Detailed analysis of interest proportion and 12-month trajectory for a single loan
  static LoanInterestAnalysis analyzeLoanInterest(
    Loan loan,
    LoanForecastResult forecast,
  ) {
    final principal =
        loan.outstandingPrincipal ?? loan.originalPrincipal ?? 0.0;
    final remainingInterest = forecast.estimatedRemainingInterest ?? 0.0;
    final totalRepayment =
        forecast.totalRemainingRepayment ?? (principal + remainingInterest);

    final interestPercentage = totalRepayment > 0
        ? (remainingInterest / totalRepayment) * 100.0
        : 0.0;

    final next12Rows = forecast.schedule.take(12).toList();
    var next12P = 0.0;
    var next12I = 0.0;
    var next12T = 0.0;

    for (final row in next12Rows) {
      next12P += row.principalComponent;
      next12I += row.interestComponent;
      next12T += row.payment;
    }

    // If schedule is empty (e.g. missing tenure/emi), approximate 12-month interest if rate is available
    if (next12Rows.isEmpty && principal > 0 && (loan.interestRate ?? 0) > 0) {
      final monthlyRate = (loan.interestRate!) / 1200.0;
      next12I = principal * monthlyRate * 12;
      next12T = (loan.emiAmount ?? 0) * 12;
      next12P = math.max(0.0, next12T - next12I);
    }

    return LoanInterestAnalysis(
      totalRemainingPrincipal: double.parse(principal.toStringAsFixed(2)),
      estimatedRemainingInterest: double.parse(
        remainingInterest.toStringAsFixed(2),
      ),
      totalRemainingRepayment: double.parse(totalRepayment.toStringAsFixed(2)),
      interestPercentageOfRepayment: double.parse(
        interestPercentage.toStringAsFixed(1),
      ),
      next12MonthsPrincipal: double.parse(next12P.toStringAsFixed(2)),
      next12MonthsInterest: double.parse(next12I.toStringAsFixed(2)),
      next12MonthsTotalPayment: double.parse(next12T.toStringAsFixed(2)),
      effectiveAnnualCost: loan.interestRate,
    );
  }

  /// Aggregates portfolio-wide metrics across all active user loans
  static DebtPortfolioSummary analyzePortfolio({
    required List<Loan> loans,
    double? recordedMonthlyIncome,
  }) {
    final activeLoans = loans.where((l) => l.active).toList();
    if (activeLoans.isEmpty) {
      return const DebtPortfolioSummary(
        totalLoansCount: 0,
        activeLoansCount: 0,
        totalOutstandingDebt: 0.0,
        totalMonthlyEmi: 0.0,
        estimatedTotalRemainingInterest: 0.0,
      );
    }

    double totalDebt = 0.0;
    double totalEmi = 0.0;
    double totalInterest = 0.0;
    double weightedRateNumerator = 0.0;
    double rateWeightDenominator = 0.0;

    Loan? highestRateLoan;
    Loan? highestCostLoan;
    Loan? largestBalanceLoan;
    double maxRate = -1.0;
    double maxInterestCost = -1.0;
    double maxBalance = -1.0;

    DateTime? earliestClosure;
    DateTime? latestClosure;

    for (final loan in activeLoans) {
      final p = loan.outstandingPrincipal ?? loan.originalPrincipal ?? 0.0;
      final emi = loan.emiAmount ?? 0.0;
      final rate = loan.interestRate ?? 0.0;

      totalDebt += p;
      totalEmi += emi;

      if (rate > 0 && p > 0) {
        weightedRateNumerator += (p * rate);
        rateWeightDenominator += p;
      }

      if (rate > maxRate) {
        maxRate = rate;
        highestRateLoan = loan;
      }

      if (p > maxBalance) {
        maxBalance = p;
        largestBalanceLoan = loan;
      }

      final forecast = LoanForecastService.calculateForecast(loan);
      final estInterest = forecast.estimatedRemainingInterest ?? 0.0;
      totalInterest += estInterest;

      if (estInterest > maxInterestCost) {
        maxInterestCost = estInterest;
        highestCostLoan = loan;
      }

      if (forecast.estimatedClosureDate != null) {
        final closure = forecast.estimatedClosureDate!;
        if (earliestClosure == null || closure.isBefore(earliestClosure)) {
          earliestClosure = closure;
        }
        if (latestClosure == null || closure.isAfter(latestClosure)) {
          latestClosure = closure;
        }
      }
    }

    final weightedRate = rateWeightDenominator > 0
        ? double.parse(
            (weightedRateNumerator / rateWeightDenominator).toStringAsFixed(2),
          )
        : null;

    double? dti;
    if (recordedMonthlyIncome != null && recordedMonthlyIncome > 0) {
      dti = double.parse(
        ((totalEmi / recordedMonthlyIncome) * 100.0).toStringAsFixed(1),
      );
    }

    return DebtPortfolioSummary(
      totalLoansCount: loans.length,
      activeLoansCount: activeLoans.length,
      totalOutstandingDebt: double.parse(totalDebt.toStringAsFixed(2)),
      totalMonthlyEmi: double.parse(totalEmi.toStringAsFixed(2)),
      estimatedTotalRemainingInterest: double.parse(
        totalInterest.toStringAsFixed(2),
      ),
      weightedAverageInterestRate: weightedRate,
      highestInterestRateLoan: highestRateLoan,
      highestInterestCostLoan: highestCostLoan,
      largestBalanceLoan: largestBalanceLoan,
      earliestEstimatedClosure: earliestClosure,
      latestEstimatedClosure: latestClosure,
      recordedMonthlyIncome: recordedMonthlyIncome,
      debtToIncomeRatio: dti,
    );
  }

  /// Evaluates multiple debt payoff strategies (Avalanche vs Snowball vs Cash-Flow vs Max Savings)
  static DebtPrioritizationPlan calculatePrioritization({
    required List<Loan> loans,
    required DebtStrategyType strategy,
  }) {
    final activeLoans = loans.where((l) => l.active).toList();
    if (activeLoans.isEmpty) {
      return DebtPrioritizationPlan(
        strategy: strategy,
        strategyName: strategy.displayName,
        strategyDescription: 'No active loans to prioritize.',
        tradeOffExplanation: '',
        prioritizedLoans: const [],
        totalMonthlyEmiToFree: 0.0,
      );
    }

    final loanForecastPairs = activeLoans.map((loan) {
      final forecast = LoanForecastService.calculateForecast(loan);
      return _LoanWithForecast(loan: loan, forecast: forecast);
    }).toList();

    String desc = '';
    String tradeOff = '';

    switch (strategy) {
      case DebtStrategyType.avalanche:
        desc = 'Prioritize loans with the highest interest rate first.';
        tradeOff = 'Mathematically minimizes total lifetime interest paid, though closing larger-balance loans may take longer.';
        loanForecastPairs.sort((a, b) {
          final rateA = a.loan.interestRate ?? 0.0;
          final rateB = b.loan.interestRate ?? 0.0;
          return rateB.compareTo(rateA);
        });
        break;

      case DebtStrategyType.snowball:
        desc = 'Prioritize loans with the smallest outstanding balance first.';
        tradeOff = 'Provides fast psychological wins and closes accounts rapidly to free up cash, but may accrue slightly more total interest.';
        loanForecastPairs.sort((a, b) {
          final balA =
              a.loan.outstandingPrincipal ?? a.loan.originalPrincipal ?? 0.0;
          final balB =
              b.loan.outstandingPrincipal ?? b.loan.originalPrincipal ?? 0.0;
          return balA.compareTo(balB);
        });
        break;

      case DebtStrategyType.cashFlowRelief:
        desc = 'Prioritize loans that free the highest monthly EMI cash flow relative to their remaining balance.';
        tradeOff = 'Maximizes monthly budget breathing room for savings and living expenses, ideal if current monthly cash flow is tight.';
        loanForecastPairs.sort((a, b) {
          final balA = math.max(
            1.0,
            a.loan.outstandingPrincipal ?? a.loan.originalPrincipal ?? 1.0,
          );
          final emiA = a.loan.emiAmount ?? a.forecast.effectiveEmi ?? 0.0;
          final ratioA = emiA / balA;

          final balB = math.max(
            1.0,
            b.loan.outstandingPrincipal ?? b.loan.originalPrincipal ?? 1.0,
          );
          final emiB = b.loan.emiAmount ?? b.forecast.effectiveEmi ?? 0.0;
          final ratioB = emiB / balB;

          return ratioB.compareTo(ratioA);
        });
        break;

      case DebtStrategyType.highestInterestSavings:
        desc = 'Prioritize the loan generating the highest total absolute interest rupee drain.';
        tradeOff = 'Eliminates your single largest interest burden, though it often requires a sustained long-term commitment.';
        loanForecastPairs.sort((a, b) {
          final intA = a.forecast.estimatedRemainingInterest ?? 0.0;
          final intB = b.forecast.estimatedRemainingInterest ?? 0.0;
          return intB.compareTo(intA);
        });
        break;
    }

    final prioritizedItems = <PrioritizedLoanItem>[];
    double totalEmi = 0.0;
    int rank = 1;

    for (final pair in loanForecastPairs) {
      final emi = pair.loan.emiAmount ?? pair.forecast.effectiveEmi ?? 0.0;
      final interest = pair.forecast.estimatedRemainingInterest ?? 0.0;
      totalEmi += emi;

      String rationale = '';
      if (strategy == DebtStrategyType.avalanche) {
        rationale =
            'Highest interest rate (${pair.loan.interestRate ?? 0}%). Closing this saves the most interest per rupee prepaid.';
      } else if (strategy == DebtStrategyType.snowball) {
        rationale =
            'Small balance (₹${(pair.loan.outstandingPrincipal ?? 0).toStringAsFixed(0)}). Eliminating this frees ₹${emi.toStringAsFixed(0)}/mo quickly.';
      } else if (strategy == DebtStrategyType.cashFlowRelief) {
        rationale =
            'High cash-flow multiplier. Frees ₹${emi.toStringAsFixed(0)}/mo of monthly commitment.';
      } else {
        rationale =
            'Largest total interest cost (₹${interest.toStringAsFixed(0)}). Targets the heaviest rupee cost in your portfolio.';
      }

      prioritizedItems.add(
        PrioritizedLoanItem(
          rank: rank++,
          loan: pair.loan,
          forecast: pair.forecast,
          rationale: rationale,
          monthlyEmiFreed: emi,
          remainingInterest: interest,
        ),
      );
    }

    return DebtPrioritizationPlan(
      strategy: strategy,
      strategyName: strategy.displayName,
      strategyDescription: desc,
      tradeOffExplanation: tradeOff,
      prioritizedLoans: prioritizedItems,
      totalMonthlyEmiToFree: double.parse(totalEmi.toStringAsFixed(2)),
    );
  }

  /// Refinancing / Rate Reduction Cost-Benefit Analyzer
  static RefinanceAnalysisResult calculateRefinanceComparison({
    required Loan loan,
    required double scenarioRate,
    double? scenarioProcessingFee,
    double? scenarioPrepaymentPenalty,
  }) {
    final baseline = LoanForecastService.calculateForecast(loan);
    final scenarioLoan = loan.copyWith(interestRate: scenarioRate);
    final scenarioForecast = LoanForecastService.calculateForecast(
      scenarioLoan,
    );

    final currentInterest = baseline.estimatedRemainingInterest ?? 0.0;
    final scenarioInterest = scenarioForecast.estimatedRemainingInterest ?? 0.0;
    final grossSavings = math.max(0.0, currentInterest - scenarioInterest);

    final refinanceCost =
        (scenarioProcessingFee ?? loan.processingFee ?? 0.0) +
        (scenarioPrepaymentPenalty ?? loan.prepaymentCharges ?? 0.0);

    final netSavings = grossSavings - refinanceCost;

    // Estimate break-even months based on monthly interest difference
    int? breakEven;
    final p = loan.outstandingPrincipal ?? loan.originalPrincipal ?? 0.0;
    final currentMonthlyInterest = p * ((loan.interestRate ?? 0.0) / 1200.0);
    final scenarioMonthlyInterest = p * (scenarioRate / 1200.0);
    final monthlySavings = currentMonthlyInterest - scenarioMonthlyInterest;

    if (refinanceCost > 0 && monthlySavings > 0) {
      breakEven = (refinanceCost / monthlySavings).ceil();
    } else if (refinanceCost == 0 && grossSavings > 0) {
      breakEven = 0;
    }

    String recommendation;
    if (netSavings > 5000) {
      final breakEvenText = breakEven != null && breakEven > 0
          ? ' Estimated break-even in ~$breakEven months.'
          : '';
      recommendation =
          'Potential net interest savings of ₹${netSavings.toStringAsFixed(0)} after accounting for estimated switching costs (₹${refinanceCost.toStringAsFixed(0)}).$breakEvenText';
    } else if (netSavings > 0) {
      recommendation =
          'Marginal net savings of ₹${netSavings.toStringAsFixed(0)}. Evaluate whether the paperwork and fees are justified.';
    } else {
      recommendation =
          'Refinancing costs (₹${refinanceCost.toStringAsFixed(0)}) exceed the estimated interest reduction. Sticking with your current terms is more cost-effective.';
    }

    return RefinanceAnalysisResult(
      loan: loan,
      currentRate: loan.interestRate ?? 0.0,
      scenarioRate: scenarioRate,
      currentRemainingInterest: currentInterest,
      scenarioRemainingInterest: scenarioInterest,
      grossInterestSaved: double.parse(grossSavings.toStringAsFixed(2)),
      estimatedRefinanceCost: double.parse(refinanceCost.toStringAsFixed(2)),
      netSavings: double.parse(netSavings.toStringAsFixed(2)),
      breakEvenMonths: breakEven,
      recommendationSummary: recommendation,
    );
  }

  /// Generates deterministic, explainable financial insights based on user's recorded loans and goals
  static List<LoanInsight> generateLoanInsights({
    required List<Loan> loans,
    double? recordedMonthlyIncome,
    List<Goal>? goals,
  }) {
    final insights = <LoanInsight>[];
    final activeLoans = loans.where((l) => l.active).toList();
    if (activeLoans.isEmpty) return insights;

    final portfolio = analyzePortfolio(
      loans: activeLoans,
      recordedMonthlyIncome: recordedMonthlyIncome,
    );

    // 1. High Interest Rate Alert (e.g. Credit card / Personal loan >= 13%)
    for (final loan in activeLoans) {
      final rate = loan.interestRate ?? 0.0;
      if (rate >= 13.0) {
        insights.add(
          LoanInsight(
            id: 'high_rate_${loan.id}',
            title: 'High-Interest Debt: ${loan.name}',
            message:
                '${loan.name} has an annual interest rate of $rate%. Prioritizing early prepayments or balance transfer could significantly reduce interest accumulation.',
            severity: LoanInsightSeverity.warning,
            loanId: loan.id,
            actionLabel: 'Simulate Prepayment',
          ),
        );
      }
    }

    // 2. Rate vs. Absolute Cost Distinction
    if (portfolio.hasMultipleLoans &&
        portfolio.highestInterestRateLoan != null &&
        portfolio.highestInterestCostLoan != null &&
        portfolio.highestInterestRateLoan!.id !=
            portfolio.highestInterestCostLoan!.id) {
      final highRate = portfolio.highestInterestRateLoan!;
      final highCost = portfolio.highestInterestCostLoan!;
      insights.add(
        LoanInsight(
          id: 'rate_vs_cost_distinction',
          title: 'Rate vs. Absolute Cost Nuance',
          message:
              '${highRate.name} has your highest interest rate (${highRate.interestRate}%), but ${highCost.name} represents your highest absolute interest drain (est. ₹${(LoanForecastService.calculateForecast(highCost).estimatedRemainingInterest ?? 0).toStringAsFixed(0)}). Consider your goal: rate minimization (Avalanche) vs rupee drain elimination.',
          severity: LoanInsightSeverity.info,
          loanId: highRate.id,
          actionLabel: 'Compare Strategies',
        ),
      );
    }

    // 3. Debt-to-Income Commitment Warning
    if (portfolio.debtToIncomeRatio != null &&
        portfolio.debtToIncomeRatio! > 40.0) {
      insights.add(
        LoanInsight(
          id: 'high_dti_warning',
          title: 'Elevated EMI-to-Income Commitment',
          message:
              'Your recorded monthly EMI obligations (₹${portfolio.totalMonthlyEmi.toStringAsFixed(0)}) represent ${portfolio.debtToIncomeRatio}% of recorded monthly income. Standard financial guidelines suggest keeping debt commitments below 35-40% of income.',
          severity: LoanInsightSeverity.warning,
          actionLabel: 'View Cash Flow Plan',
        ),
      );
    }

    // 4. Missing Data Progressive Insights
    for (final loan in activeLoans) {
      final missing = LoanForecastService.identifyMissingFields(loan);
      if (missing.isNotEmpty) {
        insights.add(
          LoanInsight(
            id: 'missing_info_${loan.id}',
            title: 'Improve Forecast: ${loan.name}',
            message:
                'Adding your ${missing.map((m) => m.title).join(", ")} will allow FINAURA to calculate precise payoff dates and interest schedules.',
            severity: LoanInsightSeverity.opportunity,
            loanId: loan.id,
            actionLabel: 'Complete Details',
          ),
        );
      }
    }

    // 5. Loan vs. Goal Trade-Off Analysis
    if (goals != null && goals.isNotEmpty && portfolio.totalMonthlyEmi > 0) {
      final emergencyGoals = goals
          .where((g) => g.type == GoalType.emergencyFund && g.active)
          .toList();
      if (emergencyGoals.isNotEmpty) {
        final g = emergencyGoals.first;
        insights.add(
          LoanInsight(
            id: 'loan_vs_emergency_goal',
            title: 'Debt Payoff vs. Emergency Fund Balance',
            message:
                'Accelerating loan prepayments reduces total interest, but balance it with your "${g.name}" goal to avoid taking new high-interest debt during sudden emergencies.',
            severity: LoanInsightSeverity.info,
            actionLabel: 'Review Goals',
          ),
        );
      }
    }

    return insights;
  }
}

class _LoanWithForecast {
  final Loan loan;
  final LoanForecastResult forecast;
  const _LoanWithForecast({required this.loan, required this.forecast});
}
