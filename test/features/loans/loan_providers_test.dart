import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/loans/domain/models/what_if_scenario.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';

void main() {
  final now = DateTime(2026, 8, 1);
  final testLoans = [
    Loan(
      id: 'loan_1',
      userId: 'user_1',
      name: 'HDFC Home Loan',
      type: LoanType.homeLoan,
      outstandingPrincipal: 3500000.0,
      interestRate: 8.5,
      emiAmount: 38000.0,
      createdAt: now,
      updatedAt: now,
    ),
    Loan(
      id: 'loan_2',
      userId: 'user_1',
      name: 'SBI Car Loan',
      type: LoanType.carLoan,
      outstandingPrincipal: 600000.0,
      interestRate: 9.0,
      emiAmount: 14000.0,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  group('Loan Providers Tests', () {
    test('selectedLoanProvider selects first loan by default or matching selected ID', () async {
      final container = ProviderContainer(
        overrides: [
          loansStreamProvider.overrideWith((ref) => Stream.value(testLoans)),
        ],
      );

      container.listen(loansStreamProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final firstSelected = container.read(selectedLoanProvider);
      expect(firstSelected?.id, 'loan_1');

      container.read(selectedLoanIdProvider.notifier).state = 'loan_2';
      final secondSelected = container.read(selectedLoanProvider);
      expect(secondSelected?.id, 'loan_2');
    });


    test('loanForecastProvider computes forecast for selected loan', () async {
      final container = ProviderContainer(
        overrides: [
          loansStreamProvider.overrideWith((ref) => Stream.value(testLoans)),
        ],
      );

      container.listen(loansStreamProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final forecast = container.read(loanForecastProvider);
      expect(forecast, isNotNull);
      expect(forecast?.outstandingPrincipal, 3500000.0);
      expect(forecast?.estimatedRemainingTenureMonths, greaterThan(0));
    });

    test(
      'whatIfScenarioResultProvider calculates scenario result dynamically',
      () async {
        final container = ProviderContainer(
          overrides: [
            loansStreamProvider.overrideWith((ref) => Stream.value(testLoans)),
            activeWhatIfTypeProvider.overrideWith(
              (ref) => WhatIfType.extraMonthly,
            ),
            activeWhatIfParamsProvider.overrideWith(
              (ref) => const WhatIfScenarioParams(extraMonthlyAmount: 10000.0),
            ),
          ],
        );

        container.listen(loansStreamProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);

        final scenarioResult = container.read(whatIfScenarioResultProvider);
        expect(scenarioResult, isNotNull);
        expect(scenarioResult?.estimatedTimeSavedMonths, greaterThan(0));
        expect(scenarioResult?.estimatedInterestSaved, greaterThan(0));
      },
    );
  });
}
