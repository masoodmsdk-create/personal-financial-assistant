import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/trade_off/domain/models/trade_off_models.dart';
import 'package:personal_financial_assistant/features/trade_off/domain/services/trade_off_intelligence_service.dart';

void main() {
  late TradeOffIntelligenceService service;
  final now = DateTime(2026, 8, 26);

  // Standard Test Loan: ₹40L Home loan at 8.5%, EMI ₹52,000, 147 remaining months
  final testLoan = Loan(
    id: 'loan_home_1',
    userId: 'u1',
    name: 'Home Loan',
    type: LoanType.homeLoan,
    originalPrincipal: 5000000.0,
    outstandingPrincipal: 4000000.0,
    interestRate: 8.5,
    remainingTenureMonths: 147,
    emiAmount: 52000.0,
    startDate: DateTime(2022, 1, 1),
    nextEmiDate: DateTime(2026, 9, 5),
    createdAt: now,
    updatedAt: now,
  );

  // High Interest Personal Loan: ₹5L at 13.5%, EMI ₹14,000
  final testPersonalLoan = Loan(
    id: 'loan_personal_1',
    userId: 'u1',
    name: 'Personal Loan',
    type: LoanType.personalLoan,
    originalPrincipal: 600000.0,
    outstandingPrincipal: 500000.0,
    interestRate: 13.5,
    remainingTenureMonths: 48,
    emiAmount: 14000.0,
    startDate: DateTime(2025, 1, 1),
    nextEmiDate: DateTime(2026, 9, 5),
    createdAt: now,
    updatedAt: now,
  );

  // Standard Test Goal: Emergency Fund target ₹5L, current ₹1.5L (30%)
  final testEmergencyGoal = Goal(
    id: 'goal_emergency_1',
    userId: 'u1',
    name: 'Emergency Fund',
    type: GoalType.emergencyFund,
    targetAmount: 500000.0,
    currentAmount: 150000.0,
    targetDate: DateTime(2027, 12, 1),
    createdAt: now,
    updatedAt: now,
  );

  // Vacation Goal: target ₹2L, current ₹1L
  final testVacationGoal = Goal(
    id: 'goal_vacation_1',
    userId: 'u1',
    name: 'Family Vacation',
    type: GoalType.savingsGoal,
    targetAmount: 200000.0,
    currentAmount: 100000.0,
    targetDate: DateTime(2027, 6, 1),
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    service = const TradeOffIntelligenceService();
  });

  group('TradeOffIntelligenceService — Core Allocation Scenarios', () {
    test('1. Loan-first allocation (100% to loan) maximizes interest and months saved', () {
      final result = service.compareStrategies(
        extraAmount: 30000.0,
        loan: testLoan,
        goal: testEmergencyGoal,
        asOfDate: now,
      );

      expect(result.hasSufficientData, isTrue);
      final loanFirst = result.getStrategyResult(TradeOffStrategy.loanFirst)!;
      expect(loanFirst.allocatedToLoan, 30000.0);
      expect(loanFirst.allocatedToGoal, 0.0);
      expect(loanFirst.interestSaved, greaterThan(0.0));
      expect(loanFirst.monthsSaved, greaterThan(0));
      expect(
        loanFirst.opportunityCost,
        0.0,
      ); // 0 foregone interest in loan-first
      expect(loanFirst.newLoanClosureDate, isNotNull);
    });

    test('2. Goal-first allocation (100% to goal) accelerates goal and computes opportunity cost', () {
      final result = service.compareStrategies(
        extraAmount: 30000.0,
        loan: testLoan,
        goal: testEmergencyGoal,
        asOfDate: now,
      );

      final goalFirst = result.getStrategyResult(TradeOffStrategy.goalFirst)!;
      final loanFirst = result.getStrategyResult(TradeOffStrategy.loanFirst)!;

      expect(goalFirst.allocatedToGoal, 30000.0);
      expect(goalFirst.allocatedToLoan, 0.0);
      expect(goalFirst.interestSaved, 0.0);
      expect(goalFirst.monthsSaved, 0);
      expect(goalFirst.goalMonthsSaved, greaterThan(0));
      expect(goalFirst.liquidityImpact, 30000.0);
      expect(goalFirst.opportunityCost, loanFirst.interestSaved);
    });

    test('3. Balanced allocation (50/50) achieves dual progress with split metrics', () {
      final result = service.compareStrategies(
        extraAmount: 30000.0,
        loan: testLoan,
        goal: testEmergencyGoal,
        asOfDate: now,
      );

      final balanced = result.getStrategyResult(TradeOffStrategy.balanced)!;
      final loanFirst = result.getStrategyResult(TradeOffStrategy.loanFirst)!;

      expect(balanced.allocatedToLoan, 15000.0);
      expect(balanced.allocatedToGoal, 15000.0);
      expect(balanced.interestSaved, greaterThan(0.0));
      expect(balanced.interestSaved, lessThan(loanFirst.interestSaved));
      expect(balanced.liquidityImpact, 15000.0);
      expect(
        balanced.opportunityCost,
        closeTo(loanFirst.interestSaved - balanced.interestSaved, 0.01),
      );
    });

    test(
      '4. Custom 25/75 split allocates correctly to loan (25%) and goal (75%)',
      () {
        final result = service.compareStrategies(
          extraAmount: 40000.0,
          loan: testLoan,
          goal: testEmergencyGoal,
          customSplitLoanPercentage: 25.0,
          asOfDate: now,
        );

        final custom = result.getStrategyResult(TradeOffStrategy.custom)!;
        expect(custom.allocatedToLoan, 10000.0);
        expect(custom.allocatedToGoal, 30000.0);
        expect(custom.loanPercentage, 25.0);
        expect(custom.goalPercentage, 75.0);
        expect(custom.liquidityImpact, 30000.0);
      },
    );

    test(
      '5. Custom 75/25 split allocates correctly to loan (75%) and goal (25%)',
      () {
        final result = service.compareStrategies(
          extraAmount: 40000.0,
          loan: testLoan,
          goal: testEmergencyGoal,
          customSplitLoanPercentage: 75.0,
          asOfDate: now,
        );

        final custom = result.getStrategyResult(TradeOffStrategy.custom)!;
        expect(custom.allocatedToLoan, 30000.0);
        expect(custom.allocatedToGoal, 10000.0);
        expect(custom.loanPercentage, 75.0);
        expect(custom.goalPercentage, 25.0);
        expect(custom.liquidityImpact, 10000.0);
      },
    );
  });

  group('TradeOffIntelligenceService — Edge Cases & Financial Semantics', () {
    test('6. Zero or negative extra cash returns insufficient data without crashing', () {
      final resultZero = service.compareStrategies(
        extraAmount: 0.0,
        loan: testLoan,
        goal: testEmergencyGoal,
        asOfDate: now,
      );

      expect(resultZero.hasSufficientData, isFalse);
      expect(resultZero.strategies, isEmpty);

      final resultNeg = service.compareStrategies(
        extraAmount: -5000.0,
        loan: testLoan,
        goal: testEmergencyGoal,
        asOfDate: now,
      );

      expect(resultNeg.hasSufficientData, isFalse);
    });

    test('7. Excess prepayment above loan principal is flagged with a warning message', () {
      final smallLoan = testLoan.copyWith(outstandingPrincipal: 20000.0);
      final result = service.compareStrategies(
        extraAmount: 50000.0,
        allocationType: TradeOffAllocationType.oneTimeLumpSum,
        loan: smallLoan,
        goal: testEmergencyGoal,
        asOfDate: now,
      );

      final loanFirst = result.getStrategyResult(TradeOffStrategy.loanFirst)!;
      expect(
        loanFirst.warningMessage,
        contains('exceeds outstanding principal'),
      );
    });

    test('8. No loan present: Goal-First is the sole viable option and recommended', () {
      final result = service.compareStrategies(
        extraAmount: 20000.0,
        loan: null,
        goal: testEmergencyGoal,
        asOfDate: now,
      );

      expect(result.hasSufficientData, isTrue);
      expect(result.recommendedStrategy?.strategy, TradeOffStrategy.goalFirst);
      final loanFirst = result.getStrategyResult(TradeOffStrategy.loanFirst)!;
      expect(loanFirst.isViable, isFalse);
    });

    test('9. No goal present: Loan-First is the sole viable option and recommended', () {
      final result = service.compareStrategies(
        extraAmount: 20000.0,
        loan: testLoan,
        goal: null,
        asOfDate: now,
      );

      expect(result.hasSufficientData, isTrue);
      expect(result.recommendedStrategy?.strategy, TradeOffStrategy.loanFirst);
      final goalFirst = result.getStrategyResult(TradeOffStrategy.goalFirst)!;
      expect(goalFirst.isViable, isFalse);
    });

    test('10. Completed goal (100%) recommends Loan-First for maximum financial efficiency', () {
      final completedGoal = testEmergencyGoal.copyWith(currentAmount: 500000.0);
      final result = service.compareStrategies(
        extraAmount: 20000.0,
        loan: testLoan,
        goal: completedGoal,
        asOfDate: now,
      );

      expect(result.recommendedStrategy?.strategy, TradeOffStrategy.loanFirst);
      expect(
        result.recommendedStrategy?.recommendationBadge,
        contains('Goal Completed'),
      );
    });

    test('15. Invalid custom split (< 0% or > 100%) is clamped safely', () {
      final resultUnder = service.compareStrategies(
        extraAmount: 20000.0,
        loan: testLoan,
        goal: testEmergencyGoal,
        customSplitLoanPercentage: -15.0,
        asOfDate: now,
      );

      final customUnder = resultUnder.getStrategyResult(
        TradeOffStrategy.custom,
      )!;
      expect(customUnder.loanPercentage, 0.0);
      expect(customUnder.goalPercentage, 100.0);

      final resultOver = service.compareStrategies(
        extraAmount: 20000.0,
        loan: testLoan,
        goal: testEmergencyGoal,
        customSplitLoanPercentage: 140.0,
        asOfDate: now,
      );

      final customOver = resultOver.getStrategyResult(TradeOffStrategy.custom)!;
      expect(customOver.loanPercentage, 100.0);
      expect(customOver.goalPercentage, 0.0);
    });

    test('16. Mathematical consistency: Loan-First interest >= Balanced >= Goal-First == 0', () {
      final result = service.compareStrategies(
        extraAmount: 30000.0,
        loan: testLoan,
        goal: testEmergencyGoal,
        asOfDate: now,
      );

      final loanFirst = result.getStrategyResult(TradeOffStrategy.loanFirst)!;
      final balanced = result.getStrategyResult(TradeOffStrategy.balanced)!;
      final goalFirst = result.getStrategyResult(TradeOffStrategy.goalFirst)!;

      expect(
        loanFirst.interestSaved,
        greaterThanOrEqualTo(balanced.interestSaved),
      );
      expect(
        balanced.interestSaved,
        greaterThanOrEqualTo(goalFirst.interestSaved),
      );
      expect(goalFirst.interestSaved, 0.0);
      expect(loanFirst.opportunityCost, 0.0);
      expect(goalFirst.opportunityCost, loanFirst.interestSaved);
    });
  });

  group('TradeOffIntelligenceService — Priority-Aware Recommendations', () {
    test('11. Priority = "Reduce debt" recommends Loan-First with explicit explanation', () {
      final result = service.compareStrategies(
        extraAmount: 30000.0,
        loan: testLoan,
        goal: testVacationGoal,
        workspacePriorities: ['Reduce debt', 'Control spending'],
        asOfDate: now,
      );

      expect(result.recommendedStrategy?.strategy, TradeOffStrategy.loanFirst);
      expect(
        result.recommendedStrategy?.recommendationBadge,
        contains('Reduce Debt'),
      );
      expect(
        result.recommendationRationale,
        contains('debt reduction priority'),
      );
    });

    test('12. Priority = "Save for a goal" recommends Goal-First with explicit explanation', () {
      final result = service.compareStrategies(
        extraAmount: 30000.0,
        loan: testLoan,
        goal: testVacationGoal,
        workspacePriorities: ['Save for a goal'],
        asOfDate: now,
      );

      expect(result.recommendedStrategy?.strategy, TradeOffStrategy.goalFirst);
      expect(
        result.recommendedStrategy?.recommendationBadge,
        contains('Save for Goal'),
      );
      expect(result.recommendationRationale, contains('savings priority'));
    });

    test('13. Priority = "Build emergency savings" with under-50% emergency fund recommends Goal-First for liquidity', () {
      final underfundedEmergencyGoal = testEmergencyGoal.copyWith(
        currentAmount: 100000.0,
      ); // 20%
      final result = service.compareStrategies(
        extraAmount: 30000.0,
        loan: testLoan,
        goal: underfundedEmergencyGoal,
        workspacePriorities: ['Build emergency savings'],
        asOfDate: now,
      );

      expect(result.recommendedStrategy?.strategy, TradeOffStrategy.goalFirst);
      expect(
        result.recommendedStrategy?.recommendationBadge,
        contains('Emergency Liquidity Priority'),
      );
      expect(result.recommendationRationale, contains('safety cushion'));
    });

    test('14. Multiple loans selection: automatically resolves to highest interest rate loan', () {
      final result = service.compareStrategies(
        extraAmount: 30000.0,
        availableLoans: [testLoan, testPersonalLoan], // 8.5% vs 13.5%
        availableGoals: [testVacationGoal],
        asOfDate: now,
      );

      expect(result.selectedLoan?.id, testPersonalLoan.id);
      expect(result.selectedLoan?.interestRate, 13.5);
    });
  });
}
