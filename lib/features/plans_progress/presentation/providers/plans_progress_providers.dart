import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/plans_progress/domain/models/plan_progress_models.dart';
import 'package:personal_financial_assistant/features/plans_progress/domain/services/plan_progress_service.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/workspaces/presentation/providers/workspace_providers.dart';

final planProgressServiceProvider = Provider<PlanProgressService>((ref) {
  return const PlanProgressService();
});

final financialPlansSummaryProvider = Provider<FinancialPlansSummary>((ref) {
  final service = ref.watch(planProgressServiceProvider);
  final loansAsync = ref.watch(loansStreamProvider);
  final goalsAsync = ref.watch(goalsStreamProvider);
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final activeWorkspace = ref.watch(activeWorkspaceProvider);

  final loans = loansAsync.value ?? [];
  final goals = goalsAsync.value ?? [];
  final transactions = transactionsAsync.value ?? [];

  return service.generateSummary(
    loans: loans,
    goals: goals,
    transactions: transactions,
    workspaceContext: activeWorkspace.purpose,
    workspacePriorities: activeWorkspace.priorities,
  );
});
