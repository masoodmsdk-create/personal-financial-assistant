import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/budgets/presentation/providers/budget_providers.dart';
import 'package:personal_financial_assistant/features/forecast/domain/models/multi_horizon_forecast.dart';
import 'package:personal_financial_assistant/features/forecast/domain/services/multi_horizon_forecast_service.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';

final multiHorizonForecastServiceProvider =
    Provider<MultiHorizonForecastService>((ref) {
      return const MultiHorizonForecastService();
    });

final multiHorizonForecastResultProvider = Provider<MultiHorizonForecastResult>(
  (ref) {
    final service = ref.watch(multiHorizonForecastServiceProvider);
    final accounts = ref.watch(accountsStreamProvider).value ?? [];
    final recurringRules =
        ref.watch(recurringTransactionsStreamProvider).value ?? [];
    final loans = ref.watch(loansStreamProvider).value ?? [];
    final goals = ref.watch(goalsStreamProvider).value ?? [];
    final plannedExpenses =
        ref.watch(plannedExpensesStreamProvider).value ?? [];
    final budgets = ref.watch(budgetsStreamProvider).value ?? [];
    final dynamicBalances = ref.watch(calculatedAccountBalancesProvider);

    return service.calculateMultiHorizonForecast(
      accounts: accounts,
      recurringRules: recurringRules,
      loans: loans,
      goals: goals,
      plannedExpenses: plannedExpenses,
      budgets: budgets,
      dynamicBalances: dynamicBalances,
    );
  },
);

final forecastScenarioComparisonsProvider = Provider<List<ScenarioComparison>>((
  ref,
) {
  final service = ref.watch(multiHorizonForecastServiceProvider);
  final forecast = ref.watch(multiHorizonForecastResultProvider);
  return service.calculateScenarioComparisons(forecast);
});
