import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/domain/models/debt_intelligence.dart';
import 'package:personal_financial_assistant/features/loans/domain/services/debt_intelligence_service.dart';
import 'package:personal_financial_assistant/features/loans/domain/services/loan_forecast_service.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';

void main() {
  final now = DateTime(2026, 8, 1);

  group('DebtIntelligenceService Unit Tests', () {
    late Loan homeLoan;
    late Loan personalLoan;
    late Loan carLoan;
    late List<Loan> mockLoans;

    setUp(() {
      homeLoan = Loan(
        id: 'loan_home',
        userId: 'user_1',
        name: 'Home Loan',
        type: LoanType.homeLoan,
        outstandingPrincipal: 5000000.0,
        interestRate: 8.5,
        emiAmount: 43391.0,
        remainingTenureMonths: 240,
        lenderName: 'HDFC Bank',
        nextEmiDate: DateTime(2026, 9, 1),
        createdAt: now,
        updatedAt: now,
      );

      personalLoan = Loan(
        id: 'loan_personal',
        userId: 'user_1',
        name: 'Personal Loan',
        type: LoanType.personalLoan,
        outstandingPrincipal: 200000.0,
        interestRate: 14.5,
        emiAmount: 9650.0,
        remainingTenureMonths: 24,
        lenderName: 'ICICI Bank',
        nextEmiDate: DateTime(2026, 9, 1),
        createdAt: now,
        updatedAt: now,
      );

      carLoan = Loan(
        id: 'loan_car',
        userId: 'user_1',
        name: 'Car Loan',
        type: LoanType.carLoan,
        outstandingPrincipal: 600000.0,
        interestRate: 9.0,
        emiAmount: 12450.0,
        remainingTenureMonths: 60,
        lenderName: 'SBI',
        nextEmiDate: DateTime(2026, 9, 1),
        createdAt: now,
        updatedAt: now,
      );

      mockLoans = [homeLoan, personalLoan, carLoan];
    });

    test('analyzeLoanInterest computes principal vs interest proportion and 12-month preview', () {
      final forecast = LoanForecastService.calculateForecast(
        homeLoan,
        asOfDate: now,
      );
      final analysis = DebtIntelligenceService.analyzeLoanInterest(
        homeLoan,
        forecast,
      );

      expect(analysis.totalRemainingPrincipal, 5000000.0);
      expect(analysis.estimatedRemainingInterest, greaterThan(1000000.0));
      expect(analysis.interestPercentageOfRepayment, greaterThan(30.0));
      expect(analysis.next12MonthsTotalPayment, greaterThan(0.0));
      expect(
        analysis.next12MonthsInterest,
        greaterThan(analysis.next12MonthsPrincipal),
      ); // Early in mortgage, interest is higher
    });

    test('analyzePortfolio calculates portfolio totals, weighted rate, and distinguishes rate vs cost', () {
      final portfolio = DebtIntelligenceService.analyzePortfolio(
        loans: mockLoans,
        recordedMonthlyIncome: 150000.0,
      );

      expect(portfolio.totalOutstandingDebt, 5800000.0);
      expect(portfolio.totalMonthlyEmi, closeTo(65491.0, 1.0));
      expect(portfolio.activeLoansCount, 3);
      expect(portfolio.weightedAverageInterestRate, closeTo(8.77, 0.2));

      // Nuance: Highest Rate is Personal Loan (14.5%), but Highest Absolute Cost is Home Loan
      expect(portfolio.highestInterestRateLoan?.id, 'loan_personal');
      expect(portfolio.highestInterestCostLoan?.id, 'loan_home');

      // Debt-to-income ratio: 65491 / 150000 = ~43.7%
      expect(portfolio.debtToIncomeRatio, closeTo(43.7, 0.5));
    });

    test(
      'calculatePrioritization Avalanche sorts by highest interest rate first',
      () {
        final plan = DebtIntelligenceService.calculatePrioritization(
          loans: mockLoans,
          strategy: DebtStrategyType.avalanche,
        );

        expect(plan.prioritizedLoans.length, 3);
        expect(plan.prioritizedLoans[0].loan.id, 'loan_personal'); // 14.5%
        expect(plan.prioritizedLoans[1].loan.id, 'loan_car'); // 9.0%
        expect(plan.prioritizedLoans[2].loan.id, 'loan_home'); // 8.5%
        expect(
          plan.prioritizedLoans[0].rationale,
          contains('Highest interest rate'),
        );
      },
    );

    test('calculatePrioritization Snowball sorts by smallest outstanding principal first', () {
      final plan = DebtIntelligenceService.calculatePrioritization(
        loans: mockLoans,
        strategy: DebtStrategyType.snowball,
      );

      expect(plan.prioritizedLoans.length, 3);
      expect(plan.prioritizedLoans[0].loan.id, 'loan_personal'); // ₹2L
      expect(plan.prioritizedLoans[1].loan.id, 'loan_car'); // ₹6L
      expect(plan.prioritizedLoans[2].loan.id, 'loan_home'); // ₹50L
      expect(plan.prioritizedLoans[0].rationale, contains('Small balance'));
    });

    test('calculatePrioritization Max Interest Savings sorts by total rupee interest drain', () {
      final plan = DebtIntelligenceService.calculatePrioritization(
        loans: mockLoans,
        strategy: DebtStrategyType.highestInterestSavings,
      );

      expect(plan.prioritizedLoans.length, 3);
      expect(
        plan.prioritizedLoans[0].loan.id,
        'loan_home',
      ); // Highest rupee interest
      expect(
        plan.prioritizedLoans[0].rationale,
        contains('Largest total interest cost'),
      );
    });

    test('calculateRefinanceComparison calculates gross savings, fee deduction, and net savings', () {
      final result = DebtIntelligenceService.calculateRefinanceComparison(
        loan: homeLoan,
        scenarioRate: 7.75, // 0.75% rate drop
        scenarioProcessingFee: 10000.0,
        scenarioPrepaymentPenalty: 0.0,
      );

      expect(result.grossInterestSaved, greaterThan(100000.0));
      expect(result.estimatedRefinanceCost, 10000.0);
      expect(result.netSavings, result.grossInterestSaved - 10000.0);
      expect(result.isFinanciallyBeneficial, true);
      expect(
        result.recommendationSummary,
        contains('Potential net interest savings'),
      );
    });

    test('generateLoanInsights detects high rate warnings, rate vs cost nuances, and DTI alerts', () {
      final mockGoals = [
        Goal(
          id: 'goal_ef',
          userId: 'user_1',
          name: 'Emergency Fund',
          type: GoalType.emergencyFund,
          targetAmount: 500000.0,
          currentAmount: 150000.0,
          active: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final insights = DebtIntelligenceService.generateLoanInsights(
        loans: mockLoans,
        recordedMonthlyIncome: 120000.0,
        goals: mockGoals,
      );

      expect(
        insights.any((i) => i.id.contains('high_rate_loan_personal')),
        true,
      );
      expect(insights.any((i) => i.id == 'rate_vs_cost_distinction'), true);
      expect(
        insights.any((i) => i.id == 'high_dti_warning'),
        true,
      ); // 65.4k on 120k income is > 40%
      expect(insights.any((i) => i.id == 'loan_vs_emergency_goal'), true);
    });
  });
}
