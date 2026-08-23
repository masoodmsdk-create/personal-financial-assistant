import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/analytics/domain/models/financial_insight.dart';
import 'package:personal_financial_assistant/features/analytics/domain/services/financial_insights_service.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense_override.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/transactions/domain/services/financial_aggregation_service.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

enum AnalyticsPeriodMode { weekly, monthly, yearly }

extension AnalyticsPeriodModeX on AnalyticsPeriodMode {
  String get displayName {
    switch (this) {
      case AnalyticsPeriodMode.weekly:
        return 'Weekly';
      case AnalyticsPeriodMode.monthly:
        return 'Monthly';
      case AnalyticsPeriodMode.yearly:
        return 'Yearly';
    }
  }
}

final selectedAnalyticsPeriodModeProvider = StateProvider<AnalyticsPeriodMode>(
  (ref) => AnalyticsPeriodMode.monthly,
);

final selectedAnalyticsDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

class PeriodDateRange {
  final DateTime start;
  final DateTime end;
  final String label;

  const PeriodDateRange({
    required this.start,
    required this.end,
    required this.label,
  });
}

final periodDateRangeProvider = Provider<PeriodDateRange>((ref) {
  final mode = ref.watch(selectedAnalyticsPeriodModeProvider);
  final date = ref.watch(selectedAnalyticsDateProvider);

  switch (mode) {
    case AnalyticsPeriodMode.weekly:
      final monday = DateTime(
        date.year,
        date.month,
        date.day,
      ).subtract(Duration(days: date.weekday - 1));
      final sunday = DateTime(
        monday.year,
        monday.month,
        monday.day,
      ).add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      final label =
          '${DateFormat('MMM dd').format(monday)} - ${DateFormat('MMM dd, yyyy').format(sunday)}';
      return PeriodDateRange(start: monday, end: sunday, label: label);

    case AnalyticsPeriodMode.monthly:
      final start = DateTime(date.year, date.month, 1);
      final nextMonth = date.month == 12
          ? DateTime(date.year + 1, 1, 1)
          : DateTime(date.year, date.month + 1, 1);
      final end = nextMonth.subtract(const Duration(milliseconds: 1));
      final label = DateFormat('MMMM yyyy').format(date);
      return PeriodDateRange(start: start, end: end, label: label);

    case AnalyticsPeriodMode.yearly:
      final start = DateTime(date.year, 1, 1);
      final end = DateTime(date.year, 12, 31, 23, 59, 59);
      final label = DateFormat('yyyy').format(date);
      return PeriodDateRange(start: start, end: end, label: label);
  }
});

final periodTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final range = ref.watch(periodDateRangeProvider);

  return transactionsAsync.when(
    data: (txs) {
      return txs.where((t) {
        return (t.date.isAfter(range.start) ||
                t.date.isAtSameMomentAs(range.start)) &&
            (t.date.isBefore(range.end) || t.date.isAtSameMomentAs(range.end));
      }).toList();
    },
    loading: () => const [],
    error: (_, _) => const [],
  );
});

class PeriodFinancialSummary {
  final double totalIncome;
  final double totalExpense;
  final double netCashFlow;
  final double totalTransfers;

  const PeriodFinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashFlow,
    required this.totalTransfers,
  });
}

final periodSummaryProvider = Provider<PeriodFinancialSummary>((ref) {
  final txs = ref.watch(periodTransactionsProvider);
  final income = FinancialAggregationService.calculateTotalIncome(txs);
  final expense = FinancialAggregationService.calculateTotalExpense(txs);
  final net = FinancialAggregationService.calculateNetCashFlow(txs);
  final transfers = FinancialAggregationService.calculateTotalTransfers(txs);

  return PeriodFinancialSummary(
    totalIncome: income,
    totalExpense: expense,
    netCashFlow: net,
    totalTransfers: transfers,
  );
});

final expenseCategoryBreakdownProvider = Provider<List<CategoryBreakdownItem>>((
  ref,
) {
  final txs = ref.watch(periodTransactionsProvider);
  final categoriesAsync = ref.watch(categoriesStreamProvider);

  final categories = categoriesAsync.maybeWhen(
    data: (cats) => cats,
    orElse: () => const <Category>[],
  );

  return FinancialAggregationService.calculateCategoryBreakdown(
    transactions: txs,
    categories: categories,
    categoryType: CategoryType.expense,
  );
});

final incomeCategoryBreakdownProvider = Provider<List<CategoryBreakdownItem>>((
  ref,
) {
  final txs = ref.watch(periodTransactionsProvider);
  final categoriesAsync = ref.watch(categoriesStreamProvider);

  final categories = categoriesAsync.maybeWhen(
    data: (cats) => cats,
    orElse: () => const <Category>[],
  );

  return FinancialAggregationService.calculateCategoryBreakdown(
    transactions: txs,
    categories: categories,
    categoryType: CategoryType.income,
  );
});

final periodPlannedVsActualProvider = Provider<PlannedVsActualData>((ref) {
  final plansAsync = ref.watch(plannedExpensesStreamProvider);
  final overridesAsync = ref.watch(monthlyOverridesStreamProvider);
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final date = ref.watch(selectedAnalyticsDateProvider);

  final plans = plansAsync.maybeWhen(
    data: (p) => p,
    orElse: () => const <PlannedExpense>[],
  );
  final overrides = overridesAsync.maybeWhen(
    data: (o) => o,
    orElse: () => const <PlannedExpenseOverride>[],
  );
  final transactions = transactionsAsync.maybeWhen(
    data: (t) => t,
    orElse: () => const <Transaction>[],
  );

  return FinancialAggregationService.calculatePlannedVsActual(
    plans: plans,
    overrides: overrides,
    transactions: transactions,
    year: date.year,
    month: date.month,
  );
});

final financialInsightsProvider = Provider<List<FinancialInsight>>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final plansAsync = ref.watch(plannedExpensesStreamProvider);
  final overridesAsync = ref.watch(monthlyOverridesStreamProvider);
  final categoriesAsync = ref.watch(categoriesStreamProvider);
  final date = ref.watch(selectedAnalyticsDateProvider);

  final txs = transactionsAsync.maybeWhen(
    data: (t) => t,
    orElse: () => const <Transaction>[],
  );
  final plans = plansAsync.maybeWhen(
    data: (p) => p,
    orElse: () => const <PlannedExpense>[],
  );
  final overrides = overridesAsync.maybeWhen(
    data: (o) => o,
    orElse: () => const <PlannedExpenseOverride>[],
  );
  final categories = categoriesAsync.maybeWhen(
    data: (c) => c,
    orElse: () => const <Category>[],
  );

  return FinancialInsightsService.generateInsights(
    transactions: txs,
    plans: plans,
    overrides: overrides,
    categories: categories,
    periodDate: date,
  );
});
