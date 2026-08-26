import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/trade_off/domain/models/trade_off_models.dart';
import 'package:personal_financial_assistant/features/trade_off/domain/services/trade_off_intelligence_service.dart';
import 'package:personal_financial_assistant/features/workspaces/presentation/providers/workspace_providers.dart';

/// Pure Service Provider
final tradeOffIntelligenceServiceProvider =
    Provider<TradeOffIntelligenceService>((ref) {
      return const TradeOffIntelligenceService();
    });

/// Extra cash flow amount (e.g. ₹25,000 extra this month)
final extraCashFlowAmountProvider = StateProvider<double>((ref) => 25000.0);

/// Allocation type: monthly recurring vs one-time lump sum
final tradeOffAllocationTypeProvider = StateProvider<TradeOffAllocationType>(
  (ref) => TradeOffAllocationType.monthlyRecurring,
);

/// User-selected Loan ID (or null for auto-selection of highest rate loan)
final selectedTradeOffLoanIdProvider = StateProvider<String?>((ref) => null);

/// User-selected Goal ID (or null for auto-selection of emergency fund / active goal)
final selectedTradeOffGoalIdProvider = StateProvider<String?>((ref) => null);

/// Custom Split percentage allocated to loan (0% to 100%, default 50%)
final customSplitLoanPercentageProvider = StateProvider<double>((ref) => 50.0);

/// Selected Strategy Tab in the UI
final selectedTradeOffStrategyProvider = StateProvider<TradeOffStrategy>(
  (ref) => TradeOffStrategy.loanFirst,
);

/// Computed Trade-Off Comparison Result
final tradeOffComparisonProvider = Provider<TradeOffComparisonResult>((ref) {
  final service = ref.watch(tradeOffIntelligenceServiceProvider);
  final extraAmount = ref.watch(extraCashFlowAmountProvider);
  final allocationType = ref.watch(tradeOffAllocationTypeProvider);
  final selectedLoanId = ref.watch(selectedTradeOffLoanIdProvider);
  final selectedGoalId = ref.watch(selectedTradeOffGoalIdProvider);
  final customSplitPercent = ref.watch(customSplitLoanPercentageProvider);

  final loansAsync = ref.watch(loansStreamProvider);
  final goalsAsync = ref.watch(goalsStreamProvider);
  final activeWorkspace = ref.watch(activeWorkspaceProvider);

  final allLoans = loansAsync.value ?? [];
  final allGoals = goalsAsync.value ?? [];

  final selectedLoan = selectedLoanId != null
      ? allLoans.where((l) => l.id == selectedLoanId).firstOrNull
      : null;

  final selectedGoal = selectedGoalId != null
      ? allGoals.where((g) => g.id == selectedGoalId).firstOrNull
      : null;

  return service.compareStrategies(
    extraAmount: extraAmount,
    allocationType: allocationType,
    loan: selectedLoan,
    goal: selectedGoal,
    availableLoans: allLoans,
    availableGoals: allGoals,
    customSplitLoanPercentage: customSplitPercent,
    workspacePriorities: activeWorkspace.priorities,
    workspacePurpose: activeWorkspace.purpose,
  );
});
