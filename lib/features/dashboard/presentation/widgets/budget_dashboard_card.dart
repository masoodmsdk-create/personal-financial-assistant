import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_financial_assistant/features/budgets/presentation/providers/budget_providers.dart';

class BudgetDashboardCard extends ConsumerWidget {
  const BudgetDashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final budgetSummary = ref.watch(monthlyBudgetSummaryProvider);
    final cashFlowPlan = ref.watch(monthlyCashFlowPlanProvider);

    final progress = budgetSummary.totalPlanned > 0
        ? (budgetSummary.totalActual / budgetSummary.totalPlanned).clamp(
            0.0,
            1.0,
          )
        : (budgetSummary.totalActual > 0 ? 1.0 : 0.0);

    Color progressColor;
    if (budgetSummary.overallUtilization > 100) {
      progressColor = colorScheme.error;
    } else if (budgetSummary.overallUtilization >= 85) {
      progressColor = Colors.orange.shade700;
    } else {
      progressColor = colorScheme.primary;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.savings_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Budget & Cash-Flow',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          budgetSummary.totalPlanned > 0
                              ? '${budgetSummary.budgetedCategoriesCount} Categories Budgeted'
                              : 'Monthly spending plan',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                FilledButton.tonalIcon(
                  onPressed: () => context.push('/budgets'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('View Budget'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 12),

            // Quick Stats Wrap
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent / Budget',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '₹${budgetSummary.totalActual.toStringAsFixed(0)} / ₹${budgetSummary.totalPlanned.toStringAsFixed(0)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available to Spend',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '₹${cashFlowPlan.availableToSpend.toStringAsFixed(0)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cashFlowPlan.availableToSpend < 0
                            ? colorScheme.error
                            : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
