import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/loans/domain/models/what_if_scenario.dart';
import 'package:personal_financial_assistant/features/loans/domain/services/loan_forecast_service.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';


void main() {
  final now = DateTime(2026, 8, 1);

  group('LoanForecastService PMT & Basic Amortization Tests', () {
    test('calculateEmi calculates correct PMT for standard home loan', () {
      // ₹50,00,000 at 8.5% for 240 months (20 years)
      final emi = LoanForecastService.calculateEmi(
        principal: 5000000.0,
        annualInterestRate: 8.5,
        tenureMonths: 240,
      );

      // Expected PMT formula ~ 43391.14
      expect(emi, closeTo(43391.14, 1.0));
    });

    test('calculateEmi returns principal / tenure if interest rate is 0%', () {
      final emi = LoanForecastService.calculateEmi(
        principal: 120000.0,
        annualInterestRate: 0.0,
        tenureMonths: 12,
      );
      expect(emi, 10000.0);
    });

    test(
      'calculateForecast computes full amortization schedule and closure date',
      () {
        final loan = Loan(
          id: 'loan_1',
          userId: 'user_1',
          name: 'Home Loan',
          type: LoanType.homeLoan,
          outstandingPrincipal: 1000000.0,
          interestRate: 8.0,
          emiAmount: 20000.0,
          nextEmiDate: DateTime(2026, 9, 1),
          createdAt: now,
          updatedAt: now,
        );

        final forecast = LoanForecastService.calculateForecast(
          loan,
          asOfDate: now,
        );

        expect(forecast.outstandingPrincipal, 1000000.0);
        expect(forecast.estimatedRemainingTenureMonths, greaterThan(0));
        expect(forecast.estimatedRemainingInterest, greaterThan(0));
        expect(forecast.estimatedClosureDate, isNotNull);
        expect(forecast.schedule.isNotEmpty, true);
        expect(forecast.note, contains('Forecast based on'));
      },
    );
  });

  group('Progressive Information & Partial Data Tests', () {
    test('identifyMissingFields correctly flags missing high-value fields', () {
      final incompleteLoan = Loan(
        id: 'loan_2',
        userId: 'user_1',
        name: 'Partial Loan',
        type: LoanType.personalLoan,
        emiAmount: 15000.0,
        createdAt: now,
        updatedAt: now,
      );

      final missing = LoanForecastService.identifyMissingFields(incompleteLoan);

      expect(missing.any((m) => m.fieldKey == 'outstandingPrincipal'), true);
      expect(missing.any((m) => m.fieldKey == 'interestRate'), true);
    });

    test('calculateForecast handles missing principal safely without crashing or fabricating numbers', () {
      final loan = Loan(
        id: 'loan_3',
        userId: 'user_1',
        name: 'No Balance Loan',
        type: LoanType.carLoan,
        emiAmount: 12000.0,
        createdAt: now,
        updatedAt: now,
      );

      final forecast = LoanForecastService.calculateForecast(
        loan,
        asOfDate: now,
      );

      expect(forecast.outstandingPrincipal, isNull);
      expect(forecast.estimatedRemainingTenureMonths, isNull);
      expect(forecast.schedule.isEmpty, true);
      expect(forecast.note, contains('Add your outstanding principal'));
    });
  });

  group('What-If Scenario Simulation Tests', () {
    final baseLoan = Loan(
      id: 'loan_base',
      userId: 'user_1',
      name: 'Base Loan',
      type: LoanType.homeLoan,
      outstandingPrincipal: 2000000.0,
      interestRate: 8.5,
      emiAmount: 25000.0,
      nextEmiDate: DateTime(2026, 9, 1),
      createdAt: now,
      updatedAt: now,
    );

    test(
      'Extra monthly payment scenario reduces tenure and saves interest',
      () {
        final result = LoanForecastService.calculateWhatIfScenario(
          loan: baseLoan,
          params: const WhatIfScenarioParams(extraMonthlyAmount: 5000.0),
          scenarioType: WhatIfType.extraMonthly,
          asOfDate: now,
        );

        expect(result.estimatedTimeSavedMonths, greaterThan(0));
        expect(result.estimatedInterestSaved, greaterThan(0));
        expect(result.disclaimer, contains('Illustrative estimate'));
      },
    );

    test(
      'One-time lump sum prepayment scenario reduces tenure and interest',
      () {
        final result = LoanForecastService.calculateWhatIfScenario(
          loan: baseLoan,
          params: const WhatIfScenarioParams(lumpSumAmount: 300000.0),
          scenarioType: WhatIfType.lumpSumPrepayment,
          asOfDate: now,
        );

        expect(result.estimatedTimeSavedMonths, greaterThan(0));
        expect(result.estimatedInterestSaved, greaterThan(0));
        expect(result.scenarioForecast.outstandingPrincipal, 1700000.0);
      },
    );

    test('Annual prepayment scenario reduces tenure', () {
      final result = LoanForecastService.calculateWhatIfScenario(
        loan: baseLoan,
        params: const WhatIfScenarioParams(annualPrepaymentAmount: 50000.0),
        scenarioType: WhatIfType.annualPrepayment,
        asOfDate: now,
      );

      expect(result.estimatedTimeSavedMonths, greaterThan(0));
      expect(result.estimatedInterestSaved, greaterThan(0));
    });

    test('Increased EMI scenario reduces tenure', () {
      final result = LoanForecastService.calculateWhatIfScenario(
        loan: baseLoan,
        params: const WhatIfScenarioParams(newEmiAmount: 35000.0),
        scenarioType: WhatIfType.increasedEmi,
        asOfDate: now,
      );

      expect(result.estimatedTimeSavedMonths, greaterThan(0));
      expect(result.estimatedInterestSaved, greaterThan(0));
      expect(result.scenarioForecast.effectiveEmi, 35000.0);
    });

    test(
      'Target closure date scenario calculates required additional payment',
      () {
        final targetDate = DateTime(2031, 8, 1); // 5 years target
        final result = LoanForecastService.calculateWhatIfScenario(
          loan: baseLoan,
          params: WhatIfScenarioParams(desiredClosureDate: targetDate),
          scenarioType: WhatIfType.targetClosureDate,
          asOfDate: now,
        );

        expect(result.requiredAdditionalMonthlyPayment, isNotNull);
        expect(result.requiredAdditionalMonthlyPayment!, greaterThan(0));
      },
    );

    test('Interest rate scenario evaluates custom interest rate change', () {
      final result = LoanForecastService.calculateWhatIfScenario(
        loan: baseLoan,
        params: const WhatIfScenarioParams(scenarioInterestRate: 7.0),
        scenarioType: WhatIfType.interestRateChange,
        asOfDate: now,
      );

      expect(result.estimatedInterestSaved, greaterThan(0));
    });
  });

  group('Credit Card Debt & Zero Safety Edge Cases', () {
    test('Credit Card debt scenario calculates payoff schedule', () {
      final ccLoan = Loan(
        id: 'cc_1',
        userId: 'user_1',
        name: 'HDFC Credit Card',
        type: LoanType.creditCardDebt,
        outstandingPrincipal: 150000.0,
        interestRate: 42.0, // 3.5% per month = 42% per year
        emiAmount: 10000.0,
        createdAt: now,
        updatedAt: now,
      );

      final forecast = LoanForecastService.calculateForecast(
        ccLoan,
        asOfDate: now,
      );

      expect(forecast.outstandingPrincipal, 150000.0);
      expect(forecast.estimatedRemainingTenureMonths, greaterThan(0));
      expect(forecast.schedule.isNotEmpty, true);
    });

    test('Warns when EMI is insufficient to cover monthly interest', () {
      final badLoan = Loan(
        id: 'bad_1',
        userId: 'user_1',
        name: 'Underpaying Loan',
        type: LoanType.personalLoan,
        outstandingPrincipal: 1000000.0,
        interestRate: 24.0, // Monthly interest = 20000
        emiAmount: 5000.0, // EMI 5000 < 20000 interest
        createdAt: now,
        updatedAt: now,
      );

      final forecast = LoanForecastService.calculateForecast(
        badLoan,
        asOfDate: now,
      );

      expect(forecast.note, contains('Caution: Current EMI'));
      expect(forecast.estimatedRemainingTenureMonths, isNull);
    });
  });
}
