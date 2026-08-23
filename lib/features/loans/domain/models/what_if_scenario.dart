import 'package:personal_financial_assistant/features/loans/domain/models/loan_forecast.dart';

enum WhatIfType {
  extraMonthly,
  annualPrepayment,
  lumpSumPrepayment,
  increasedEmi,
  targetClosureDate,
  interestRateChange,
  refinanceComparison,
}

extension WhatIfTypeX on WhatIfType {
  String get displayName {
    switch (this) {
      case WhatIfType.extraMonthly:
        return 'Extra Monthly Payment';
      case WhatIfType.annualPrepayment:
        return 'Annual Prepayment';
      case WhatIfType.lumpSumPrepayment:
        return 'One-time Prepayment';
      case WhatIfType.increasedEmi:
        return 'Increased EMI';
      case WhatIfType.targetClosureDate:
        return 'Target Closure Date';
      case WhatIfType.interestRateChange:
        return 'Interest Rate Scenario';
      case WhatIfType.refinanceComparison:
        return 'Refinancing / Rate Reduction';
    }
  }
}

class WhatIfScenarioParams {
  final double? extraMonthlyAmount;
  final double? annualPrepaymentAmount;
  final double? lumpSumAmount;
  final double? newEmiAmount;
  final DateTime? desiredClosureDate;
  final double? scenarioInterestRate;
  final double? scenarioProcessingFee;
  final double? scenarioPrepaymentPenalty;

  const WhatIfScenarioParams({
    this.extraMonthlyAmount,
    this.annualPrepaymentAmount,
    this.lumpSumAmount,
    this.newEmiAmount,
    this.desiredClosureDate,
    this.scenarioInterestRate,
    this.scenarioProcessingFee,
    this.scenarioPrepaymentPenalty,
  });
}

class WhatIfScenarioResult {
  final WhatIfType scenarioType;
  final String scenarioName;
  final WhatIfScenarioParams scenarioParams;
  final LoanForecastResult baselineForecast;
  final LoanForecastResult scenarioForecast;
  final int estimatedTimeSavedMonths;
  final double estimatedInterestSaved;
  final double? requiredAdditionalMonthlyPayment;
  final double? netRefinanceSavings;
  final int? breakEvenMonths;
  final String disclaimer;

  const WhatIfScenarioResult({
    required this.scenarioType,
    required this.scenarioName,
    required this.scenarioParams,
    required this.baselineForecast,
    required this.scenarioForecast,
    required this.estimatedTimeSavedMonths,
    required this.estimatedInterestSaved,
    this.requiredAdditionalMonthlyPayment,
    this.netRefinanceSavings,
    this.breakEvenMonths,
    this.disclaimer = 'Illustrative estimate assuming the entered rate/parameters remain unchanged. Actual lender treatment may differ.',
  });
}
