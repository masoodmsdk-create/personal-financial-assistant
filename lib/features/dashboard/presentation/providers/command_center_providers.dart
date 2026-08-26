import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/dashboard/domain/models/command_center_models.dart';
import 'package:personal_financial_assistant/features/dashboard/domain/services/command_center_service.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/workspaces/presentation/providers/workspace_providers.dart';

final commandCenterServiceProvider = Provider<CommandCenterService>((ref) {
  return const CommandCenterService();
});

final assistantSuggestionsProvider = Provider<List<HomeAssistantSuggestion>>((
  ref,
) {
  final service = ref.watch(commandCenterServiceProvider);
  final loans = ref.watch(loansStreamProvider).value ?? [];
  final goals = ref.watch(goalsStreamProvider).value ?? [];
  final accounts = ref.watch(accountsStreamProvider).value ?? [];
  final transactions = ref.watch(transactionsStreamProvider).value ?? [];
  final plans = ref.watch(plannedExpensesStreamProvider).value ?? [];
  final overrides = ref.watch(monthlyOverridesStreamProvider).value ?? [];
  final categories = ref.watch(categoriesStreamProvider).value ?? [];
  final monthlySummary = ref.watch(monthlyFinancialSummaryProvider);
  final activeWorkspace = ref.watch(activeWorkspaceProvider);

  final now = DateTime.now();
  final currentSummary = monthlySummary;

  return service.generateAssistantSuggestions(
    loans: loans,
    goals: goals,
    accounts: accounts,
    transactions: transactions,
    plans: plans,
    overrides: overrides,
    categories: categories,
    monthlySummary: currentSummary,
    workspaceContext: activeWorkspace.purpose,
    workspacePriorities: activeWorkspace.priorities,
    asOfDate: now,
  );
});

final upcomingRemindersProvider = Provider<List<UpcomingPaymentReminder>>((
  ref,
) {
  final service = ref.watch(commandCenterServiceProvider);
  final loans = ref.watch(loansStreamProvider).value ?? [];
  final plans = ref.watch(plannedExpensesStreamProvider).value ?? [];

  return service.getUpcomingReminders(loans: loans, plans: plans);
});

final accountsSummaryDataProvider = Provider<AccountsSummaryData>((ref) {
  final service = ref.watch(commandCenterServiceProvider);
  final accounts = ref.watch(accountsStreamProvider).value ?? [];
  final balances = ref.watch(calculatedAccountBalancesProvider);

  return service.getAccountsSummary(
    accounts: accounts,
    dynamicBalances: balances,
  );
});
