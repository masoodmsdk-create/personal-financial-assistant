import 'dart:math' as math;

import 'package:personal_financial_assistant/features/loans/domain/models/loan_forecast.dart';
import 'package:personal_financial_assistant/features/loans/domain/models/what_if_scenario.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';

class LoanForecastService {
  /// Calculate PMT EMI given Principal, Annual Interest Rate %, and Tenure in Months
  static double calculateEmi({
    required double principal,
    required double annualInterestRate,
    required int tenureMonths,
  }) {
    if (principal <= 0 || tenureMonths <= 0) return 0.0;
    if (annualInterestRate <= 0) return principal / tenureMonths;

    final r = annualInterestRate / 1200.0;
    final powTerm = math.pow(1.0 + r, tenureMonths).toDouble();
    if (powTerm == 1.0) return principal / tenureMonths;

    final emi = principal * (r * powTerm) / (powTerm - 1.0);
    return double.parse(emi.toStringAsFixed(2));
  }

  /// Evaluates high-value missing fields for progressive loan entry
  static List<LoanMissingFieldInfo> identifyMissingFields(Loan loan) {
    final List<LoanMissingFieldInfo> missing = [];

    if (!loan.hasOutstandingPrincipal) {
      missing.add(
        const LoanMissingFieldInfo(
          fieldKey: 'outstandingPrincipal',
          title: 'Outstanding Principal',
          reason:
              'Helps estimate your remaining repayment and interest precisely.',
          suggestedAction: 'Enter current balance',
        ),
      );
    }

    if (!loan.hasInterestRate) {
      missing.add(
        const LoanMissingFieldInfo(
          fieldKey: 'interestRate',
          title: 'Interest Rate',
          reason: 'Helps calculate monthly interest cost and amortization.',
          suggestedAction: 'Enter interest rate',
        ),
      );
    }

    if (!loan.hasEmiAmount) {
      missing.add(
        const LoanMissingFieldInfo(
          fieldKey: 'emiAmount',
          title: 'EMI Amount',
          reason:
              'Helps determine monthly cash commitment and payoff timeline.',
          suggestedAction: 'Enter EMI amount',
        ),
      );
    }

    if (!loan.hasRemainingTenure &&
        loan.hasEmiAmount &&
        loan.hasOutstandingPrincipal) {
      missing.add(
        const LoanMissingFieldInfo(
          fieldKey: 'remainingTenureMonths',
          title: 'Remaining Tenure',
          reason: 'Helps compare your entered schedule with the calculated estimate.',
          suggestedAction: 'Enter remaining months',
        ),
      );
    }

    if (loan.nextEmiDate == null) {
      missing.add(
        const LoanMissingFieldInfo(
          fieldKey: 'nextEmiDate',
          title: 'Next EMI Date',
          reason: 'Helps pinpoint your expected payment and payoff timeline.',
          suggestedAction: 'Select next EMI date',
        ),
      );
    }

    return missing;
  }

  /// Calculates loan forecast based on available progressive information
  static LoanForecastResult calculateForecast(Loan loan, {DateTime? asOfDate}) {
    final now = asOfDate ?? DateTime.now();
    final missingFields = identifyMissingFields(loan);
    final startDate = loan.nextEmiDate ?? loan.startDate ?? now;

    final P = loan.outstandingPrincipal ?? loan.originalPrincipal;
    final rAnnual = loan.interestRate ?? 0.0;
    final r = rAnnual / 1200.0;
    var E = loan.emiAmount;
    final nInput = loan.remainingTenureMonths;

    // Case 1: Insufficient data for financial amortization (Missing Principal or zero principal)
    if (P == null || P <= 0) {
      return LoanForecastResult(
        loan: loan,
        calculatedAt: now,
        missingFields: missingFields,
        note: 'Forecast based on the information currently provided. Add your outstanding principal to estimate remaining repayment.',
      );
    }

    // Case 2: EMI is missing, but Principal, Rate, and Tenure are available -> Calculate PMT EMI
    if ((E == null || E <= 0) && rAnnual > 0 && nInput != null && nInput > 0) {
      E = calculateEmi(
        principal: P,
        annualInterestRate: rAnnual,
        tenureMonths: nInput,
      );
    }

    // Case 3: Principal & Rate available, but no EMI & no Tenure
    if ((E == null || E <= 0) && (nInput == null || nInput <= 0)) {
      return LoanForecastResult(
        loan: loan,
        calculatedAt: now,
        outstandingPrincipal: P,
        missingFields: missingFields,
        note: 'Forecast based on the information currently provided. Add your EMI amount or remaining tenure to calculate payoff timeline.',
      );
    }

    // Case 4: Zero interest loan (e.g. 0% interest promo or loan without interest rate provided)
    if (rAnnual <= 0) {
      final effectiveEmi =
          E ?? (nInput != null && nInput > 0 ? P / nInput : 0.0);
      if (effectiveEmi <= 0) {
        return LoanForecastResult(
          loan: loan,
          calculatedAt: now,
          outstandingPrincipal: P,
          missingFields: missingFields,
          note: 'Forecast based on the information currently provided. Add your EMI or interest rate.',
        );
      }

      final tenureMonths = (P / effectiveEmi).ceil();
      final schedule = <AmortizationScheduleRow>[];
      var balance = P;
      for (var m = 1; m <= tenureMonths; m++) {
        final payment = balance < effectiveEmi ? balance : effectiveEmi;
        balance -= payment;
        schedule.add(
          AmortizationScheduleRow(
            monthNumber: m,
            date: DateTime(
              startDate.year,
              startDate.month + (m - 1),
              startDate.day,
            ),
            payment: double.parse(payment.toStringAsFixed(2)),
            principalComponent: double.parse(payment.toStringAsFixed(2)),
            interestComponent: 0.0,
            remainingBalance: double.parse(balance.toStringAsFixed(2)),
          ),
        );
      }

      final closureDate = DateTime(
        startDate.year,
        startDate.month + tenureMonths,
        startDate.day,
      );

      return LoanForecastResult(
        loan: loan,
        calculatedAt: now,
        estimatedRemainingTenureMonths: tenureMonths,
        estimatedClosureDate: closureDate,
        estimatedRemainingInterest: 0.0,
        outstandingPrincipal: P,
        totalRemainingRepayment: P,
        effectiveEmi: effectiveEmi,
        schedule: schedule,
        missingFields: missingFields,
        note: 'Forecast based on the information currently provided.',
      );
    }

    // Case 5: Full Amortization Simulation (Principal P > 0, Rate r > 0, EMI E > 0)
    final effectiveEmi = E!;
    final firstMonthInterest = P * r;

    // Safety Check: EMI is smaller than monthly interest -> Loan balance would grow indefinitely
    if (effectiveEmi <= firstMonthInterest) {
      return LoanForecastResult(
        loan: loan,
        calculatedAt: now,
        outstandingPrincipal: P,
        effectiveEmi: effectiveEmi,
        missingFields: missingFields,
        note:
            'Caution: Current EMI (₹${effectiveEmi.toStringAsFixed(2)}) is less than monthly interest (₹${firstMonthInterest.toStringAsFixed(2)}). Loan balance will grow. Consider increasing EMI.',
      );
    }

    final schedule = <AmortizationScheduleRow>[];
    var balance = P;
    var totalInterest = 0.0;
    var totalRepayment = 0.0;
    var month = 0;
    const maxMonthsLimit = 600; // 50 years max cap

    while (balance > 0.01 && month < maxMonthsLimit) {
      month++;
      final interestComp = balance * r;
      var principalComp = effectiveEmi - interestComp;

      if (principalComp > balance) {
        principalComp = balance;
      }

      final payment = principalComp + interestComp;
      balance -= principalComp;
      if (balance < 0.01) balance = 0.0;

      totalInterest += interestComp;
      totalRepayment += payment;

      schedule.add(
        AmortizationScheduleRow(
          monthNumber: month,
          date: DateTime(
            startDate.year,
            startDate.month + (month - 1),
            startDate.day,
          ),
          payment: double.parse(payment.toStringAsFixed(2)),
          principalComponent: double.parse(principalComp.toStringAsFixed(2)),
          interestComponent: double.parse(interestComp.toStringAsFixed(2)),
          remainingBalance: double.parse(balance.toStringAsFixed(2)),
        ),
      );
    }

    final closureDate = DateTime(
      startDate.year,
      startDate.month + month,
      startDate.day,
    );

    return LoanForecastResult(
      loan: loan,
      calculatedAt: now,
      estimatedRemainingTenureMonths: month,
      estimatedClosureDate: closureDate,
      estimatedRemainingInterest: double.parse(
        totalInterest.toStringAsFixed(2),
      ),
      outstandingPrincipal: P,
      totalRemainingRepayment: double.parse(totalRepayment.toStringAsFixed(2)),
      effectiveEmi: effectiveEmi,
      schedule: schedule,
      missingFields: missingFields,
      note: 'Forecast based on the information currently provided.',
    );
  }

  /// Calculates What-If Prepayment & Rate Scenarios without altering actual Loan data
  static WhatIfScenarioResult calculateWhatIfScenario({
    required Loan loan,
    required WhatIfScenarioParams params,
    required WhatIfType scenarioType,
    DateTime? asOfDate,
  }) {
    final now = asOfDate ?? DateTime.now();
    final baseline = calculateForecast(loan, asOfDate: now);

    Loan scenarioLoan = loan;
    String scenarioName = scenarioType.displayName;
    double? requiredAdditionalPayment;
    LoanForecastResult scenarioForecast;

    switch (scenarioType) {
      case WhatIfType.extraMonthly:
        final extra = params.extraMonthlyAmount ?? 0.0;
        final baseEmi = loan.emiAmount ?? baseline.effectiveEmi ?? 0.0;
        scenarioLoan = loan.copyWith(emiAmount: baseEmi + extra);
        scenarioName =
            'Extra Monthly Payment (+₹${extra.toStringAsFixed(0)}/mo)';
        scenarioForecast = calculateForecast(scenarioLoan, asOfDate: now);
        break;

      case WhatIfType.increasedEmi:
        final newEmi = params.newEmiAmount ?? loan.emiAmount ?? 0.0;
        scenarioLoan = loan.copyWith(emiAmount: newEmi);
        scenarioName = 'Increased EMI (₹${newEmi.toStringAsFixed(0)}/mo)';
        scenarioForecast = calculateForecast(scenarioLoan, asOfDate: now);
        break;

      case WhatIfType.lumpSumPrepayment:
        final lumpSum = params.lumpSumAmount ?? 0.0;
        final baseP =
            loan.outstandingPrincipal ?? loan.originalPrincipal ?? 0.0;
        final newP = math.max(0.0, baseP - lumpSum);
        scenarioLoan = loan.copyWith(outstandingPrincipal: newP);
        scenarioName =
            'One-time Prepayment (₹${lumpSum.toStringAsFixed(0)} now)';
        scenarioForecast = calculateForecast(scenarioLoan, asOfDate: now);
        break;

      case WhatIfType.interestRateChange:
        final newRate = params.scenarioInterestRate ?? loan.interestRate ?? 0.0;
        scenarioLoan = loan.copyWith(interestRate: newRate);
        scenarioName =
            'Interest Rate Scenario (${newRate.toStringAsFixed(1)}%)';
        scenarioForecast = calculateForecast(scenarioLoan, asOfDate: now);
        break;

      case WhatIfType.annualPrepayment:
        final annualExtra = params.annualPrepaymentAmount ?? 0.0;
        scenarioName =
            'Annual Prepayment (+₹${annualExtra.toStringAsFixed(0)}/yr)';
        scenarioForecast = _simulateAnnualPrepayment(
          loan: loan,
          annualPrepayment: annualExtra,
          asOfDate: now,
        );
        break;

      case WhatIfType.refinanceComparison:
        final newRate =
            params.scenarioInterestRate ?? ((loan.interestRate ?? 8.5) - 0.5);
        scenarioLoan = loan.copyWith(interestRate: newRate);
        scenarioName = 'Refinance to ${newRate.toStringAsFixed(1)}%';
        scenarioForecast = calculateForecast(scenarioLoan, asOfDate: now);
        break;

      case WhatIfType.targetClosureDate:
        final desiredDate =
            params.desiredClosureDate ??
            DateTime.now().add(const Duration(days: 365));
        scenarioName =
            'Target Closure Date (${desiredDate.year}-${desiredDate.month.toString().padLeft(2, '0')})';

        final startDate = loan.nextEmiDate ?? loan.startDate ?? now;
        var monthsDiff =
            (desiredDate.year - startDate.year) * 12 +
            (desiredDate.month - startDate.month);
        if (monthsDiff <= 0) monthsDiff = 1;

        final P = loan.outstandingPrincipal ?? loan.originalPrincipal ?? 0.0;
        final rAnnual = loan.interestRate ?? 0.0;

        if (P > 0 && monthsDiff > 0) {
          final requiredEmi = calculateEmi(
            principal: P,
            annualInterestRate: rAnnual,
            tenureMonths: monthsDiff,
          );
          final currentEmi = loan.emiAmount ?? baseline.effectiveEmi ?? 0.0;
          requiredAdditionalPayment = math.max(0.0, requiredEmi - currentEmi);
          scenarioLoan = loan.copyWith(
            emiAmount: requiredEmi,
            remainingTenureMonths: monthsDiff,
          );
          scenarioForecast = calculateForecast(scenarioLoan, asOfDate: now);
        } else {
          scenarioForecast = baseline;
        }
        break;
    }

    final timeSavedMonths = math.max(
      0,
      (baseline.estimatedRemainingTenureMonths ?? 0) -
          (scenarioForecast.estimatedRemainingTenureMonths ?? 0),
    );

    final interestSaved = math.max(
      0.0,
      (baseline.estimatedRemainingInterest ?? 0.0) -
          (scenarioForecast.estimatedRemainingInterest ?? 0.0),
    );

    double? netRefinance;
    int? breakEven;
    if (scenarioType == WhatIfType.refinanceComparison) {
      final switchingCost =
          (params.scenarioProcessingFee ?? loan.processingFee ?? 0.0) +
          (params.scenarioPrepaymentPenalty ?? loan.prepaymentCharges ?? 0.0);
      netRefinance = interestSaved - switchingCost;
      final p = loan.outstandingPrincipal ?? loan.originalPrincipal ?? 0.0;
      final monthlyCurrentI = p * ((loan.interestRate ?? 0.0) / 1200.0);
      final monthlyScenarioI =
          p *
          ((params.scenarioInterestRate ?? (loan.interestRate ?? 0.0)) /
              1200.0);
      final monthlyDiff = monthlyCurrentI - monthlyScenarioI;
      if (switchingCost > 0 && monthlyDiff > 0) {
        breakEven = (switchingCost / monthlyDiff).ceil();
      }
    }

    return WhatIfScenarioResult(
      scenarioType: scenarioType,
      scenarioName: scenarioName,
      scenarioParams: params,
      baselineForecast: baseline,
      scenarioForecast: scenarioForecast,
      estimatedTimeSavedMonths: timeSavedMonths,
      estimatedInterestSaved: double.parse(interestSaved.toStringAsFixed(2)),
      requiredAdditionalMonthlyPayment: requiredAdditionalPayment != null
          ? double.parse(requiredAdditionalPayment.toStringAsFixed(2))
          : null,
      netRefinanceSavings: netRefinance != null
          ? double.parse(netRefinance.toStringAsFixed(2))
          : null,
      breakEvenMonths: breakEven,
      disclaimer: 'Illustrative estimate assuming the entered rate/parameters remain unchanged. Actual lender treatment may differ.',
    );
  }

  /// Custom simulation for Annual Prepayment (every 12th month extra principal reduction)
  static LoanForecastResult _simulateAnnualPrepayment({
    required Loan loan,
    required double annualPrepayment,
    required DateTime asOfDate,
  }) {
    final P = loan.outstandingPrincipal ?? loan.originalPrincipal ?? 0.0;
    final rAnnual = loan.interestRate ?? 0.0;
    final r = rAnnual / 1200.0;
    final E = loan.emiAmount ?? 0.0;
    final startDate = loan.nextEmiDate ?? loan.startDate ?? asOfDate;

    if (P <= 0 || E <= 0) {
      return calculateForecast(loan, asOfDate: asOfDate);
    }

    final schedule = <AmortizationScheduleRow>[];
    var balance = P;
    var totalInterest = 0.0;
    var totalRepayment = 0.0;
    var month = 0;

    while (balance > 0.01 && month < 600) {
      month++;
      final interestComp = balance * r;
      var principalComp = E - interestComp;

      // Add annual prepayment every 12th month
      if (month % 12 == 0) {
        principalComp += annualPrepayment;
      }

      if (principalComp > balance) {
        principalComp = balance;
      }

      final payment = principalComp + interestComp;
      balance -= principalComp;
      if (balance < 0.01) balance = 0.0;

      totalInterest += interestComp;
      totalRepayment += payment;

      schedule.add(
        AmortizationScheduleRow(
          monthNumber: month,
          date: DateTime(
            startDate.year,
            startDate.month + (month - 1),
            startDate.day,
          ),
          payment: double.parse(payment.toStringAsFixed(2)),
          principalComponent: double.parse(principalComp.toStringAsFixed(2)),
          interestComponent: double.parse(interestComp.toStringAsFixed(2)),
          remainingBalance: double.parse(balance.toStringAsFixed(2)),
        ),
      );
    }

    final closureDate = DateTime(
      startDate.year,
      startDate.month + month,
      startDate.day,
    );

    return LoanForecastResult(
      loan: loan,
      calculatedAt: asOfDate,
      estimatedRemainingTenureMonths: month,
      estimatedClosureDate: closureDate,
      estimatedRemainingInterest: double.parse(
        totalInterest.toStringAsFixed(2),
      ),
      outstandingPrincipal: P,
      totalRemainingRepayment: double.parse(totalRepayment.toStringAsFixed(2)),
      effectiveEmi: E,
      schedule: schedule,
      missingFields: identifyMissingFields(loan),
      note: 'Forecast based on annual prepayment simulation.',
    );
  }
}
