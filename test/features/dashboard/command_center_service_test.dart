import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/domain/models/account_type_definition.dart';
import 'package:personal_financial_assistant/features/dashboard/domain/models/command_center_models.dart';
import 'package:personal_financial_assistant/features/dashboard/domain/services/command_center_service.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/domain/services/loan_forecast_service.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';

void main() {
  late CommandCenterService service;
  final now = DateTime(2026, 8, 23);

  setUp(() {
    service = const CommandCenterService();
  });

  group('CommandCenterService — Assistant Suggestions Tests', () {
    test(
      'Behind-target loan generates warning suggestion with direct route',
      () {
        final baseLoan = Loan(
          id: 'loan_home',
          userId: 'u1',
          name: 'Home Loan',
          type: LoanType.homeLoan,
          originalPrincipal: 5000000.0,
          outstandingPrincipal: 4000000.0,
          interestRate: 8.5,
          remainingTenureMonths: 147,
          emiAmount: 52000.0,
          startDate: DateTime(2026, 8, 1),
          createdAt: now,
          updatedAt: now,
        );

        final forecast = LoanForecastService.calculateForecast(
          baseLoan,
          asOfDate: now,
        );
        final projectedDate = forecast.estimatedClosureDate!;
        final targetDate = DateTime(
          projectedDate.year,
          projectedDate.month - 4,
          1,
        );
        final loan = baseLoan.copyWith(targetClosureDate: targetDate);

        final suggestions = service.generateAssistantSuggestions(
          loans: [loan],
          goals: [],
          accounts: [],
          transactions: [],
          plans: [],
          overrides: [],
          categories: [],
          monthlySummary: const MonthlySummaryData(
            year: 2026,
            month: 8,
            totalIncome: 100000.0,
            totalExpense: 40000.0,
            netCashFlow: 60000.0,
          ),
          asOfDate: now,
        );

        expect(
          suggestions.any((s) => s.id == 'sug_loan_behind_loan_home'),
          isTrue,
        );
        final loanSug = suggestions.firstWhere(
          (s) => s.id == 'sug_loan_behind_loan_home',
        );
        expect(loanSug.severity, SuggestionSeverity.warning);
        expect(loanSug.actionRoute, '/loans/loan_home');
        expect(loanSug.actionLabel, 'View Loan');
      },
    );

    test('Goal reached target generates success suggestion', () {
      final goal = Goal(
        id: 'goal_car',
        userId: 'u1',
        name: 'Car Down Payment',
        type: GoalType.customGoal,
        targetAmount: 200000.0,
        currentAmount: 200000.0,
        targetDate: DateTime(2026, 12, 1),
        createdAt: DateTime(2025, 1, 1),
        updatedAt: now,
      );

      final suggestions = service.generateAssistantSuggestions(
        loans: [],
        goals: [goal],
        accounts: [],
        transactions: [],
        plans: [],
        overrides: [],
        categories: [],
        monthlySummary: const MonthlySummaryData(
          year: 2026,
          month: 8,
          totalIncome: 100000.0,
          totalExpense: 40000.0,
          netCashFlow: 60000.0,
        ),
        asOfDate: now,
      );

      expect(
        suggestions.any((s) => s.id == 'sug_goal_achieved_goal_car'),
        isTrue,
      );
      final goalSug = suggestions.firstWhere(
        (s) => s.id == 'sug_goal_achieved_goal_car',
      );
      expect(goalSug.severity, SuggestionSeverity.success);
      expect(goalSug.actionRoute, '/goals');
    });

    test('Negative cash flow generates warning suggestion with monthly-review route', () {
      final suggestions = service.generateAssistantSuggestions(
        loans: [],
        goals: [],
        accounts: [],
        transactions: [],
        plans: [],
        overrides: [],
        categories: [],
        monthlySummary: const MonthlySummaryData(
          year: 2026,
          month: 8,
          totalIncome: 50000.0,
          totalExpense: 80000.0,
          netCashFlow: -30000.0,
        ),
        asOfDate: now,
      );

      expect(suggestions.any((s) => s.id == 'sug_cashflow_negative'), isTrue);
      final cashSug = suggestions.firstWhere(
        (s) => s.id == 'sug_cashflow_negative',
      );
      expect(cashSug.severity, SuggestionSeverity.warning);
      expect(cashSug.actionRoute, '/monthly-review');
    });
  });

  group('CommandCenterService — Upcoming Reminders Tests', () {
    test('Extracts upcoming loan EMI due within 30 days', () {
      final loan = Loan(
        id: 'loan_1',
        userId: 'u1',
        name: 'Car Loan',
        type: LoanType.carLoan,
        originalPrincipal: 800000.0,
        interestRate: 9.0,
        remainingTenureMonths: 60,
        emiAmount: 18000.0,
        nextEmiDate: DateTime(2026, 9, 5),
        createdAt: now,
        updatedAt: now,
      );

      final reminders = service.getUpcomingReminders(
        loans: [loan],
        plans: [],
        asOfDate: now,
      );

      expect(reminders.length, 1);
      expect(reminders.first.id, 'rem_emi_loan_1');
      expect(reminders.first.amount, 18000.0);
      expect(reminders.first.isEmi, isTrue);
      expect(reminders.first.actionRoute, '/loans/loan_1');
    });

    test('Extracts upcoming planned expense scheduled within 30 days', () {
      final plan = PlannedExpense(
        id: 'plan_rent',
        userId: 'u1',
        categoryId: 'cat_rent',
        name: 'House Rent',
        defaultAmount: 25000.0,
        startDate: DateTime(2026, 1, 1),
        frequency: RecurrenceFrequency.monthly,
        createdAt: now,
        updatedAt: now,
        active: true,
      );

      final reminders = service.getUpcomingReminders(
        loans: [],
        plans: [plan],
        asOfDate: now,
      );

      expect(reminders.length, 1);
      expect(reminders.first.id, 'rem_plan_plan_rent');
      expect(reminders.first.amount, 25000.0);
      expect(reminders.first.actionRoute, '/planned-expenses');
    });
  });

  group('CommandCenterService — Accounts Summary Tests', () {
    test('Calculates total assets, liabilities, and net balance correctly', () {
      final accounts = [
        Account(
          id: 'acc_bank',
          userId: 'u1',
          name: 'HDFC Savings',
          type: AccountType.bank,
          nature: AccountNature.asset,
          openingBalance: 150000.0,
          currency: 'INR',
          createdAt: now,
          updatedAt: now,
          active: true,
        ),
        Account(
          id: 'acc_cc',
          userId: 'u1',
          name: 'ICICI Credit Card',
          type: AccountType.creditCard,
          nature: AccountNature.liability,
          openingBalance: -30000.0,
          currency: 'INR',
          createdAt: now,
          updatedAt: now,
          active: true,
        ),
      ];

      final balances = {'acc_bank': 150000.0, 'acc_cc': -30000.0};

      final summary = service.getAccountsSummary(
        accounts: accounts,
        dynamicBalances: balances,
      );

      expect(summary.activeAccountsCount, 2);
      expect(summary.totalAssets, 150000.0);
      expect(summary.totalLiabilities, 30000.0);
      expect(summary.netBalance, 120000.0);
    });
  });
}
