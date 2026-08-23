import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/domain/services/loan_forecast_service.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';

import 'package:personal_financial_assistant/features/plans_progress/domain/models/plan_progress_models.dart';
import 'package:personal_financial_assistant/features/plans_progress/domain/services/plan_progress_service.dart';

void main() {
  late PlanProgressService service;
  final asOfDate = DateTime(2026, 8, 23);

  setUp(() {
    service = const PlanProgressService();
  });

  group('PlanProgressService — Loans Tests', () {
    test('Critical Acceptance Test — Loan: 4 months behind with neutral factual explanation', () {
      final baseLoan = Loan(
        id: 'loan_home_1',
        userId: 'user_1',
        name: 'Home Loan',
        type: LoanType.homeLoan,
        outstandingPrincipal: 4000000, // ₹40L
        interestRate: 8.5,
        emiAmount: 52000,
        remainingTenureMonths: 147,
        startDate: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 8, 23),
      );

      // Pre-calculate forecast to get exact projection date and set target 4 months earlier (e.g. July 2034 vs March 2034)
      final forecast = LoanForecastService.calculateForecast(
        baseLoan,
        asOfDate: asOfDate,
      );
      final projectedDate = forecast.estimatedClosureDate!;
      final targetDate = DateTime(
        projectedDate.year,
        projectedDate.month - 4,
        1,
      );

      final loan = baseLoan.copyWith(targetClosureDate: targetDate);
      final result = service.evaluateLoanProgress(loan, asOfDate: asOfDate);

      expect(result.outstandingPrincipal, 4000000);
      expect(result.emi, 52000);
      expect(result.hasTarget, isTrue);
      expect(result.hasProjection, isTrue);
      expect(result.varianceMonths, 4);
      expect(result.status, PlanProgressStatus.slightlyBehind);
      expect(result.headline, '4 months behind');
      expect(
        result.explanation,
        'Your recorded extra prepayment is below the current plan.',
      );
    });

    test('Critical Acceptance Test — Dynamic Recovery: Additional prepayment updates status to Ahead', () {
      // 1. Initial State: Behind
      final initialLoan = Loan(
        id: 'loan_1',
        userId: 'user_1',
        name: 'Personal Loan',
        type: LoanType.personalLoan,
        outstandingPrincipal: 500000,
        interestRate: 12.0,
        emiAmount: 15000,
        remainingTenureMonths: 48,
        targetClosureDate: DateTime(2028, 6, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 8, 23),
      );

      final initialResult = service.evaluateLoanProgress(
        initialLoan,
        asOfDate: asOfDate,
      );
      expect(initialResult.status.needsAttention, isTrue);

      // 2. User makes a large prepayment reducing outstanding principal
      final recoveredLoan = initialLoan.copyWith(
        outstandingPrincipal: 200000, // Principal reduced significantly
        remainingTenureMonths: 15,
        updatedAt: DateTime(2026, 8, 24),
      );

      final recoveredResult = service.evaluateLoanProgress(
        recoveredLoan,
        asOfDate: asOfDate,
      );
      expect(recoveredResult.status, PlanProgressStatus.ahead);
      expect(recoveredResult.headline, contains('ahead'));
      expect(recoveredResult.explanation, contains('before your target'));
    });

    test('Critical Acceptance Test — No Target: Loan without targetClosureDate returns NO_TARGET', () {
      final loan = Loan(
        id: 'loan_no_target',
        userId: 'user_1',
        name: 'Car Loan',
        type: LoanType.carLoan,
        outstandingPrincipal: 600000,
        interestRate: 9.0,
        emiAmount: 18000,
        remainingTenureMonths: 36,
        targetClosureDate: null, // No target set
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 8, 23),
      );

      final result = service.evaluateLoanProgress(loan, asOfDate: asOfDate);

      expect(result.status, PlanProgressStatus.noTarget);
      expect(result.headline, 'Set Target Date');
      expect(result.explanation, contains('Set a target closure date'));
      // Invariant: Must not mark as behind or ahead
      expect(result.status.needsAttention, isFalse);
    });

    test('Loan with insufficient data returns INSUFFICIENT_DATA', () {
      final incompleteLoan = Loan(
        id: 'loan_incomplete',
        userId: 'user_1',
        name: 'Unknown Debt',
        type: LoanType.otherLoan,
        outstandingPrincipal: 0,
        emiAmount: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 8, 23),
      );

      final result = service.evaluateLoanProgress(
        incompleteLoan,
        asOfDate: asOfDate,
      );
      expect(result.status, PlanProgressStatus.insufficientData);
      expect(result.headline, 'Incomplete Details');
    });

    test('Loan with target date passed returns AT_RISK', () {
      final overdueLoan = Loan(
        id: 'loan_overdue',
        userId: 'user_1',
        name: 'Overdue Loan',
        type: LoanType.personalLoan,
        outstandingPrincipal: 100000,
        interestRate: 10.0,
        emiAmount: 5000,
        remainingTenureMonths: 24,
        targetClosureDate: DateTime(2025, 12, 1), // Target was in the past
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2026, 8, 23),
      );

      final result = service.evaluateLoanProgress(
        overdueLoan,
        asOfDate: asOfDate,
      );
      expect(result.status, PlanProgressStatus.atRisk);
      expect(result.headline, 'Target Date Passed');
      expect(
        result.explanation,
        contains('target closure date was December 2025'),
      );
    });
  });

  group('PlanProgressService — Goals Tests', () {
    test('Critical Acceptance Test — Goal: 2 months behind with neutral factual explanation', () {
      // Created 8 months ago, saved 2L (pace = 25k/mo). Target 5L by Dec 2027 (remaining 3L requires ~19k/mo).
      // If current pace projects completion 2 months after target:
      final goal = Goal(
        id: 'goal_emergency_1',
        userId: 'user_1',
        name: 'Emergency Fund',
        type: GoalType.emergencyFund,
        targetAmount: 500000, // ₹5L
        currentAmount: 200000, // ₹2L
        targetDate: DateTime(2027, 2, 1), // Target
        createdAt: DateTime(2025, 1, 1), // Created 20 months ago -> 200k / 20 = 10k/mo -> 300k remaining takes 30 months -> Feb 2029 (behind)
        updatedAt: DateTime(2026, 8, 23),
      );

      final result = service.evaluateGoalProgress(goal, asOfDate: asOfDate);

      expect(result.currentAmount, 200000);
      expect(result.targetAmount, 500000);
      expect(result.percentage, 40.0);
      expect(result.status, PlanProgressStatus.behind);
      expect(result.headline, contains('behind'));
      expect(
        result.explanation,
        contains('current contribution pace projects completion'),
      );
    });

    test('Goal with target met returns AHEAD with Goal Achieved', () {
      final completedGoal = Goal(
        id: 'goal_done',
        userId: 'user_1',
        name: 'Vacation Goal',
        type: GoalType.savingsGoal,
        targetAmount: 50000,
        currentAmount: 50000,
        targetDate: DateTime(2026, 12, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 8, 23),
      );

      final result = service.evaluateGoalProgress(
        completedGoal,
        asOfDate: asOfDate,
      );
      expect(result.status, PlanProgressStatus.ahead);
      expect(result.headline, 'Goal Achieved');
      expect(result.percentage, 100.0);
    });

    test('Goal without targetDate returns NO_TARGET', () {
      final goalNoTarget = Goal(
        id: 'goal_no_target',
        userId: 'user_1',
        name: 'Car Down Payment',
        type: GoalType.savingsGoal,
        targetAmount: 200000,
        currentAmount: 50000,
        targetDate: null,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 8, 23),
      );

      final result = service.evaluateGoalProgress(
        goalNoTarget,
        asOfDate: asOfDate,
      );
      expect(result.status, PlanProgressStatus.noTarget);
      expect(result.headline, 'Set Target Date');
    });

    test('Goal with no contributions returns INSUFFICIENT_DATA', () {
      final newGoal = Goal(
        id: 'goal_zero',
        userId: 'user_1',
        name: 'New Goal',
        type: GoalType.customGoal,
        targetAmount: 100000,
        currentAmount: 0.0,
        targetDate: DateTime(2027, 1, 1),
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 23),
      );

      final result = service.evaluateGoalProgress(newGoal, asOfDate: asOfDate);
      expect(result.status, PlanProgressStatus.insufficientData);
      expect(result.headline, 'No Contributions Yet');
    });
  });

  group('PlanProgressService — Consolidated Summary Tests', () {
    test('generateSummary aggregates totals, attention counts, and prioritizes items', () {
      final loans = [
        Loan(
          id: 'l1',
          userId: 'u1',
          name: 'Home Loan',
          type: LoanType.homeLoan,
          outstandingPrincipal: 3840000,
          interestRate: 8.5,
          emiAmount: 52000,
          remainingTenureMonths: 147,
          targetClosureDate: DateTime(2034, 3, 1),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 8, 23),
        ),
        Loan(
          id: 'l2',
          userId: 'u1',
          name: 'Car Loan',
          type: LoanType.carLoan,
          outstandingPrincipal: 400000,
          interestRate: 9.0,
          emiAmount: 15000,
          remainingTenureMonths: 30,
          targetClosureDate: null, // No target
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 8, 23),
        ),
      ];

      final goals = [
        Goal(
          id: 'g1',
          userId: 'u1',
          name: 'Emergency Fund',
          type: GoalType.emergencyFund,
          targetAmount: 500000,
          currentAmount: 200000,
          targetDate: DateTime(2027, 12, 1),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 8, 23),
        ),
      ];

      final summary = service.generateSummary(
        loans: loans,
        goals: goals,
        workspacePriorities: ['Build emergency fund', 'Reduce debt'],
        asOfDate: asOfDate,
      );

      expect(summary.totalLoanOutstanding, 4240000);
      expect(summary.totalMonthlyEmi, 67000);
      expect(summary.activeLoansCount, 2);
      expect(summary.totalGoalTarget, 500000);
      expect(summary.totalGoalCurrent, 200000);
      expect(summary.activeGoalsCount, 1);
      expect(summary.prioritizedLoanItems.length, 2);
      expect(summary.prioritizedGoalItems.length, 1);
      // Emergency fund is prioritized first due to workspace priorities
      expect(summary.prioritizedGoalItems.first.goal.name, 'Emergency Fund');
    });
  });
}
