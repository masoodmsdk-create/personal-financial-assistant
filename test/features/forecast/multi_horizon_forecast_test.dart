import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/forecast/domain/models/multi_horizon_forecast.dart';
import 'package:personal_financial_assistant/features/forecast/domain/services/multi_horizon_forecast_service.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

void main() {
  const service = MultiHorizonForecastService();

  group('MultiHorizonForecastService Deterministic Tests', () {
    final now = DateTime(2026, 1, 1);

    final List<Account> testAccounts = [
      Account(
        id: 'acc_bank',
        userId: 'user_1',
        name: 'HDFC Salary Account',
        type: AccountType.bank,
        openingBalance: 100000.0, // ₹1,00,000
        currency: 'INR',
        active: true,
        createdAt: now,
        updatedAt: now,
      ),
      Account(
        id: 'acc_cc',
        userId: 'user_1',
        name: 'Infinia Credit Card',
        type: AccountType.creditCard,
        openingBalance: 20000.0, // ₹20,000 debt
        currency: 'INR',
        active: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final List<RecurringTransactionRule> testRecurring = [
      RecurringTransactionRule(
        id: 'rec_sal',
        userId: 'user_1',
        name: 'Salary Income',
        amount: 80000.0, // ₹80,000 / mo
        type: TransactionType.income,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        categoryId: 'cat_salary',
        startDate: now,
        nextOccurrence: now.add(const Duration(days: 30)),
        accountId: 'acc_bank',
        active: true,
        createdAt: now,
        updatedAt: now,
      ),
      RecurringTransactionRule(
        id: 'rec_rent',
        userId: 'user_1',
        name: 'Apartment Rent',
        amount: 25000.0, // ₹25,000 / mo
        type: TransactionType.expense,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        categoryId: 'cat_rent',
        startDate: now,
        nextOccurrence: now.add(const Duration(days: 5)),
        accountId: 'acc_bank',
        active: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final List<Loan> testLoans = [
      Loan(
        id: 'loan_car',
        userId: 'user_1',
        name: 'Car Loan',
        type: LoanType.carLoan,
        originalPrincipal: 400000.0,
        outstandingPrincipal: 100000.0, // ₹1,00,000 remaining
        interestRate: 8.5, // 8.5%
        emiAmount: 10000.0, // ₹10,000 / mo
        startDate: now,
        nextEmiDate: now.add(const Duration(days: 10)),
        active: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final List<Goal> testGoals = [
      Goal(
        id: 'goal_emergency',
        userId: 'user_1',
        name: 'Emergency Fund',
        type: GoalType.emergencyFund,
        targetAmount: 200000.0,
        currentAmount: 80000.0,
        targetDate: now.add(const Duration(days: 365)),
        active: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final List<PlannedExpense> testPlannedExpenses = [
      PlannedExpense(
        id: 'plan_groceries',
        userId: 'user_1',
        categoryId: 'cat_groceries',
        name: 'Groceries & Household',
        defaultAmount: 15000.0, // ₹15,000 / mo
        frequency: RecurrenceFrequency.monthly,
        startDate: now,
        active: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    test('calculates correct starting baseline and monthly flows', () {
      final result = service.calculateMultiHorizonForecast(
        accounts: testAccounts,
        recurringRules: testRecurring,
        loans: testLoans,
        goals: testGoals,
        plannedExpenses: testPlannedExpenses,
        asOfDate: now,
      );

      // Starting liquid savings = 100,000 (HDFC)
      expect(result.currentLiquidSavings, 100000.0);
      // Starting debt = 20,000 (CC) + 100,000 (Car Loan) = 120,000
      expect(result.currentTotalDebt, 120000.0);
      // Net worth = 100,000 - 120,000 = -20,000
      expect(result.currentNetWorth, -20000.0);

      // Monthly recurring income = 80,000
      expect(result.monthlyRecurringIncome, 80000.0);
      // Monthly living expenses = 25,000 (rent) + 15,000 (groceries) = 40,000
      expect(result.monthlyRecurringExpenses, 40000.0);
      // Monthly loan EMIs = 10,000
      expect(result.monthlyLoanEmis, 10000.0);
      // Monthly Net Cash Flow = 80,000 - 40,000 - 10,000 = 30,000 surplus/month
      expect(result.monthlyNetCashFlow, 30000.0);
    });

    test('calculates 1M, 4M, 6M, 12M multi-horizon projections accurately', () {
      final result = service.calculateMultiHorizonForecast(
        accounts: testAccounts,
        recurringRules: testRecurring,
        loans: testLoans,
        goals: testGoals,
        plannedExpenses: testPlannedExpenses,
        asOfDate: now,
      );

      // 1 Month Horizon
      final m1 = result.month1;
      expect(m1.months, 1);
      expect(m1.cumulativeIncome, 80000.0);
      expect(m1.cumulativeCommitments, 50000.0);
      expect(m1.cumulativeNetCashFlow, 30000.0);
      expect(m1.projectedSavings, 130000.0); // 100k + 30k
      expect(m1.status, ForecastHealthStatus.healthy);

      // 4 Months Horizon
      final m4 = result.month4;
      expect(m4.months, 4);
      expect(m4.cumulativeIncome, 320000.0); // 80k * 4
      expect(m4.cumulativeNetCashFlow, 120000.0); // 30k * 4
      expect(m4.projectedSavings, 220000.0); // 100k + 120k

      // 6 Months Horizon
      final m6 = result.month6;
      expect(m6.months, 6);
      expect(m6.cumulativeIncome, 480000.0);
      expect(m6.cumulativeNetCashFlow, 180000.0);
      expect(m6.projectedSavings, 280000.0);

      // 12 Months Horizon
      final m12 = result.month12;
      expect(m12.months, 12);
      expect(m12.cumulativeIncome, 960000.0); // 80k * 12
      expect(m12.cumulativeNetCashFlow, 360000.0); // 30k * 12
      expect(m12.projectedSavings, 460000.0); // 100k + 360k
      // Car loan with 10k EMI on 100k principal at 8.5% closes within 11 months!
      expect(m12.loansClosed.contains('Car Loan'), isTrue);
      // Emergency fund (target 200k, starting 80k) with 50% surplus (180k) reached!
      expect(m12.goalsAchieved.contains('Emergency Fund'), isTrue);
    });

    test('generates What-If scenario comparisons vs Baseline', () {
      final result = service.calculateMultiHorizonForecast(
        accounts: testAccounts,
        recurringRules: testRecurring,
        loans: testLoans,
        goals: testGoals,
        plannedExpenses: testPlannedExpenses,
        asOfDate: now,
      );

      final scenarios = service.calculateScenarioComparisons(result);
      expect(scenarios.length, greaterThanOrEqualTo(2));

      final extra5k = scenarios.firstWhere(
        (s) => s.scenarioName.contains('+₹5,000'),
      );
      expect(extra5k.netImprovement, 60000.0);
      expect(
        extra5k.scenario12mSavings,
        result.month12.projectedSavings + 60000.0,
      );

      final extra10k = scenarios.firstWhere(
        (s) => s.scenarioName.contains('+₹10,000'),
      );
      expect(extra10k.netImprovement, 120000.0);
      expect(
        extra10k.scenario12mSavings,
        result.month12.projectedSavings + 120000.0,
      );
    });
  });
}
