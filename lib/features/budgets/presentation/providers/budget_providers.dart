import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/budgets/data/repositories/firestore_budget_repository.dart';
import 'package:personal_financial_assistant/features/budgets/domain/models/budget.dart';
import 'package:personal_financial_assistant/features/budgets/domain/repositories/budget_repository.dart';
import 'package:personal_financial_assistant/features/budgets/domain/services/budget_calculation_service.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return FirestoreBudgetRepository();
});

final budgetCalculationServiceProvider = Provider<BudgetCalculationService>((
  ref,
) {
  return const BudgetCalculationService();
});

final selectedBudgetMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final budgetsStreamProvider = StreamProvider<List<Budget>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.watchBudgets(user.uid);
});

final monthlyBudgetSummaryProvider = Provider<MonthlyBudgetSummary>((ref) {
  final selectedMonth = ref.watch(selectedBudgetMonthProvider);
  final budgets = ref.watch(budgetsStreamProvider).value ?? [];
  final transactions = ref.watch(transactionsStreamProvider).value ?? [];
  final categories = ref.watch(categoriesStreamProvider).value ?? [];
  final service = ref.watch(budgetCalculationServiceProvider);

  return service.calculateBudgetVsActual(
    year: selectedMonth.year,
    month: selectedMonth.month,
    budgets: budgets,
    transactions: transactions,
    categories: categories,
  );
});

final monthlyCashFlowPlanProvider = Provider<MonthlyCashFlowPlan>((ref) {
  final selectedMonth = ref.watch(selectedBudgetMonthProvider);
  final budgets = ref.watch(budgetsStreamProvider).value ?? [];
  final transactions = ref.watch(transactionsStreamProvider).value ?? [];
  final recurringRules =
      ref.watch(recurringTransactionsStreamProvider).value ?? [];
  final plannedExpenses = ref.watch(plannedExpensesStreamProvider).value ?? [];
  final overrides = ref.watch(monthlyOverridesStreamProvider).value ?? [];
  final loans = ref.watch(loansStreamProvider).value ?? [];
  final service = ref.watch(budgetCalculationServiceProvider);

  return service.calculateCashFlowPlan(
    year: selectedMonth.year,
    month: selectedMonth.month,
    budgets: budgets,
    transactions: transactions,
    recurringRules: recurringRules,
    plannedExpenses: plannedExpenses,
    overrides: overrides,
    loans: loans,
  );
});

class BudgetController extends StateNotifier<AsyncValue<void>> {
  final BudgetRepository _repository;
  final Ref _ref;

  BudgetController(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  Future<bool> addBudget(Budget budget) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');
      final payload = budget.copyWith(userId: user.uid);
      await _repository.createBudget(payload);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateBudget(Budget budget) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');
      final payload = budget.copyWith(userId: user.uid);
      await _repository.updateBudget(payload);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteBudget(String budgetId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');
      await _repository.deleteBudget(user.uid, budgetId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final budgetControllerProvider =
    StateNotifierProvider<BudgetController, AsyncValue<void>>((ref) {
      return BudgetController(ref.watch(budgetRepositoryProvider), ref);
    });
