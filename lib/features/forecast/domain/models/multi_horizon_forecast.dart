enum ForecastHealthStatus { healthy, tight, deficit }

class HorizonProjection {
  final int months;
  final DateTime targetDate;
  final double projectedMonthlyIncome;
  final double projectedMonthlyLivingExpenses;
  final double projectedMonthlyLoanEmis;
  final double projectedMonthlyCommitments;
  final double projectedMonthlyNetCashFlow;

  final double cumulativeIncome;
  final double cumulativeLivingExpenses;
  final double cumulativeLoanEmis;
  final double cumulativeCommitments;
  final double cumulativeNetCashFlow;

  final double startingSavings;
  final double projectedSavings;
  final double startingLoanPrincipal;
  final double projectedLoanPrincipal;
  final double projectedNetWorth;

  final List<String> loansClosed;
  final List<String> goalsAchieved;
  final Map<String, double> goalProgressMap;
  final ForecastHealthStatus status;

  const HorizonProjection({
    required this.months,
    required this.targetDate,
    required this.projectedMonthlyIncome,
    required this.projectedMonthlyLivingExpenses,
    required this.projectedMonthlyLoanEmis,
    required this.projectedMonthlyCommitments,
    required this.projectedMonthlyNetCashFlow,
    required this.cumulativeIncome,
    required this.cumulativeLivingExpenses,
    required this.cumulativeLoanEmis,
    required this.cumulativeCommitments,
    required this.cumulativeNetCashFlow,
    required this.startingSavings,
    required this.projectedSavings,
    required this.startingLoanPrincipal,
    required this.projectedLoanPrincipal,
    required this.projectedNetWorth,
    required this.loansClosed,
    required this.goalsAchieved,
    required this.goalProgressMap,
    required this.status,
  });

  String get label {
    switch (months) {
      case 1:
        return '1 Month';
      case 4:
        return '4 Months';
      case 6:
        return '6 Months';
      case 12:
        return '1 Year';
      case 24:
        return '2 Years';
      case 36:
        return '3 Years';
      default:
        return '$months Months';
    }
  }
}

class MultiHorizonForecastResult {
  final DateTime asOfDate;
  final double currentLiquidSavings;
  final double currentTotalDebt;
  final double currentNetWorth;
  final double monthlyRecurringIncome;
  final double monthlyRecurringExpenses;
  final double monthlyLoanEmis;
  final double monthlyNetCashFlow;

  final HorizonProjection month1;
  final HorizonProjection month4;
  final HorizonProjection month6;
  final HorizonProjection month12;
  final List<HorizonProjection> allHorizons;

  const MultiHorizonForecastResult({
    required this.asOfDate,
    required this.currentLiquidSavings,
    required this.currentTotalDebt,
    required this.currentNetWorth,
    required this.monthlyRecurringIncome,
    required this.monthlyRecurringExpenses,
    required this.monthlyLoanEmis,
    required this.monthlyNetCashFlow,
    required this.month1,
    required this.month4,
    required this.month6,
    required this.month12,
    required this.allHorizons,
  });

  HorizonProjection getProjection(int months) {
    return allHorizons.firstWhere(
      (h) => h.months == months,
      orElse: () => month12,
    );
  }
}

class ScenarioComparison {
  final String scenarioName;
  final String description;
  final double baseline12mSavings;
  final double scenario12mSavings;
  final double baseline12mDebt;
  final double scenario12mDebt;
  final double baseline12mNetWorth;
  final double scenario12mNetWorth;
  final double netImprovement;
  final String outcomeExplanation;

  const ScenarioComparison({
    required this.scenarioName,
    required this.description,
    required this.baseline12mSavings,
    required this.scenario12mSavings,
    required this.baseline12mDebt,
    required this.scenario12mDebt,
    required this.baseline12mNetWorth,
    required this.scenario12mNetWorth,
    required this.netImprovement,
    required this.outcomeExplanation,
  });
}
