import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/analytics/domain/models/financial_insight.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense_override.dart';
import 'package:personal_financial_assistant/features/transactions/domain/services/financial_aggregation_service.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class FinancialInsightsService {
  static List<FinancialInsight> generateInsights({
    required List<Transaction> transactions,
    required List<PlannedExpense> plans,
    required List<PlannedExpenseOverride> overrides,
    required List<Category> categories,
    required DateTime periodDate,
  }) {
    final List<FinancialInsight> insights = [];
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final categoryMap = {for (final c in categories) c.id: c};

    final year = periodDate.year;
    final month = periodDate.month;
    final now = DateTime.now();

    // 1. Calculate Planned vs Actual for the target month
    final plannedVsActual =
        FinancialAggregationService.calculatePlannedVsActual(
          plans: plans,
          overrides: overrides,
          transactions: transactions,
          year: year,
          month: month,
        );

    // 2. Identify Category-level actual spending vs planned
    final categoryActuals = <String, double>{};
    for (final t in transactions) {
      if (t.type == TransactionType.expense &&
          t.date.year == year &&
          t.date.month == month &&
          t.categoryId != null) {
        categoryActuals[t.categoryId!] =
            (categoryActuals[t.categoryId!] ?? 0.0) + t.amount;
      }
    }

    final overridesByPlanId = <String, PlannedExpenseOverride>{};
    for (final o in overrides) {
      if (o.year == year && o.month == month) {
        overridesByPlanId[o.planId] = o;
      }
    }

    // 3. Inspect each active planned expense
    final activePlans = plans.where((p) => p.active).toList();

    for (final plan in activePlans) {
      // Check if plan applies to this period
      if (plan.startDate.isAfter(DateTime(year, month, 31))) continue;
      if (plan.endDate != null &&
          plan.endDate!.isBefore(DateTime(year, month, 1))) {
        continue;
      }

      final override = overridesByPlanId[plan.id];
      final effectivePlannedAmount = override?.amount ?? plan.defaultAmount;
      final category = categoryMap[plan.categoryId];
      final categoryName = category?.name ?? plan.name;
      final actualSpent = categoryActuals[plan.categoryId] ?? 0.0;

      // Insight: Missing planned expense / Upcoming planned expense
      if (actualSpent == 0.0) {
        // If the period month is current or past, flag possible unrecorded expense
        final isCurrentOrPastMonth =
            (year < now.year) || (year == now.year && month <= now.month);

        if (isCurrentOrPastMonth) {
          insights.add(
            FinancialInsight(
              id: 'missing_${plan.id}_${year}_$month',
              type: InsightType.missingPlannedExpense,
              title: 'Unrecorded Expense Review',
              description:
                  'You may not have recorded your planned expense for "$categoryName" (${currencyFormat.format(effectivePlannedAmount)}) for this month.',
              severity: InsightSeverity.warning,
              categoryId: plan.categoryId,
              amount: effectivePlannedAmount,
              createdAt: now,
            ),
          );
        } else {
          insights.add(
            FinancialInsight(
              id: 'upcoming_${plan.id}_${year}_$month',
              type: InsightType.upcomingPlannedExpense,
              title: 'Upcoming Planned Expense',
              description:
                  'Your planned expense of ${currencyFormat.format(effectivePlannedAmount)} for "$categoryName" is scheduled for this month.',
              severity: InsightSeverity.info,
              categoryId: plan.categoryId,
              amount: effectivePlannedAmount,
              createdAt: now,
            ),
          );
        }
      } else if (actualSpent > effectivePlannedAmount) {
        final diff = actualSpent - effectivePlannedAmount;
        insights.add(
          FinancialInsight(
            id: 'above_${plan.id}_${year}_$month',
            type: InsightType.abovePlan,
            title: 'Spending Above Plan',
            description:
                '"$categoryName" is ${currencyFormat.format(diff)} above your planned amount of ${currencyFormat.format(effectivePlannedAmount)} this month.',
            severity: InsightSeverity.warning,
            categoryId: plan.categoryId,
            amount: diff,
            createdAt: now,
          ),
        );
      }
    }

    // 4. Overall Planned vs Actual summary insight
    if (plannedVsActual.totalPlannedAmount > 0) {
      if (plannedVsActual.totalActualExpense >
          plannedVsActual.totalPlannedAmount) {
        final excess =
            plannedVsActual.totalActualExpense -
            plannedVsActual.totalPlannedAmount;
        insights.add(
          FinancialInsight(
            id: 'overall_above_${year}_$month',
            type: InsightType.abovePlan,
            title: 'Monthly Spending Review',
            description:
                'Total actual expenses are ${currencyFormat.format(excess)} above your overall monthly planned budget of ${currencyFormat.format(plannedVsActual.totalPlannedAmount)}.',
            severity: InsightSeverity.warning,
            amount: excess,
            createdAt: now,
          ),
        );
      } else if (plannedVsActual.totalActualExpense > 0) {
        final remaining =
            plannedVsActual.totalPlannedAmount -
            plannedVsActual.totalActualExpense;
        insights.add(
          FinancialInsight(
            id: 'overall_below_${year}_$month',
            type: InsightType.belowPlan,
            title: 'Monthly Spending Status',
            description:
                'Your actual expenses are ${currencyFormat.format(remaining)} below your monthly plan so far.',
            severity: InsightSeverity.success,
            amount: remaining,
            createdAt: now,
          ),
        );
      }
    }

    return insights;
  }
}
