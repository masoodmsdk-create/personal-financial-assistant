import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/budgets/presentation/providers/budget_providers.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/review/domain/models/monthly_review_data.dart';
import 'package:personal_financial_assistant/features/review/domain/services/financial_review_service.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';

final selectedReviewDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final monthlyReviewDataProvider = Provider<AsyncValue<MonthlyReviewData>>((
  ref,
) {
  final targetDate = ref.watch(selectedReviewDateProvider);

  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final plansAsync = ref.watch(plannedExpensesStreamProvider);
  final overridesAsync = ref.watch(monthlyOverridesStreamProvider);
  final categoriesAsync = ref.watch(categoriesStreamProvider);
  final loansAsync = ref.watch(loansStreamProvider);
  final goalsAsync = ref.watch(goalsStreamProvider);
  final recurringAsync = ref.watch(recurringTransactionsStreamProvider);
  final budgetsAsync = ref.watch(budgetsStreamProvider);

  if (transactionsAsync.isLoading ||
      plansAsync.isLoading ||
      overridesAsync.isLoading ||
      categoriesAsync.isLoading ||
      loansAsync.isLoading ||
      goalsAsync.isLoading ||
      recurringAsync.isLoading ||
      budgetsAsync.isLoading) {
    return const AsyncLoading();
  }

  if (transactionsAsync.hasError) {
    return AsyncError(transactionsAsync.error!, transactionsAsync.stackTrace!);
  }

  final transactions = transactionsAsync.value ?? [];
  final plans = plansAsync.value ?? [];
  final overrides = overridesAsync.value ?? [];
  final categories = categoriesAsync.value ?? [];
  final loans = loansAsync.value ?? [];
  final goals = goalsAsync.value ?? [];
  final recurringRules = recurringAsync.value ?? [];
  final budgets = budgetsAsync.value ?? [];

  final reviewData = FinancialReviewService.buildMonthlyReview(
    targetDate: targetDate,
    transactions: transactions,
    plans: plans,
    overrides: overrides,
    categories: categories,
    loans: loans,
    goals: goals,
    recurringRules: recurringRules,
    budgets: budgets,
  );

  return AsyncData(reviewData);
});
