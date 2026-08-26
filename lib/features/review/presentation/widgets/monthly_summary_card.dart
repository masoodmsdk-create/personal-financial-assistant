import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/review/domain/models/monthly_review_data.dart';

class MonthlySummaryCard extends StatelessWidget {
  final MonthlyReviewData reviewData;

  const MonthlySummaryCard({super.key, required this.reviewData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    final diffText = reviewData.isAbovePlan
        ? '${currencyFormat.format(reviewData.plannedVsActualDiff)} above plan'
        : '${currencyFormat.format(reviewData.plannedVsActualDiff)} below plan';

    final diffColor = reviewData.isAbovePlan ? Colors.orange : Colors.green;

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
            Row(
              children: [
                Icon(
                  Icons.insert_chart_outlined,
                  color: colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Monthly Financial Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ACTUAL vs PLANNED',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Top Row: Income, Expenses, Net Cash Flow
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 460;
                final incomeTile = _SummaryTile(
                  label: 'Total Income (ACTUAL)',
                  value: currencyFormat.format(reviewData.totalIncome),
                  color: Colors.green,
                );
                final expenseTile = _SummaryTile(
                  label: 'Total Expense (ACTUAL)',
                  value: currencyFormat.format(reviewData.totalExpense),
                  color: Colors.red,
                );
                final netTile = _SummaryTile(
                  label: 'Net Cash Flow',
                  value: currencyFormat.format(reviewData.netCashFlow),
                  color: reviewData.netCashFlow >= 0
                      ? Colors.green
                      : Colors.red,
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: incomeTile),
                          const SizedBox(width: 8),
                          Expanded(child: expenseTile),
                        ],
                      ),
                      const SizedBox(height: 12),
                      netTile,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: incomeTile),
                    const SizedBox(width: 8),
                    Expanded(child: expenseTile),
                    const SizedBox(width: 8),
                    Expanded(child: netTile),
                  ],
                );
              },
            ),

            const Divider(height: 24),

            // Bottom Row: Planned vs Actual Comparison
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;
                final columnWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Planned Expenses',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(reviewData.totalPlannedExpense),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );

                final badgeWidget = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: diffColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: diffColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        reviewData.isAbovePlan
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 16,
                        color: diffColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          diffText,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: diffColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      columnWidget,
                      const SizedBox(height: 8),
                      badgeWidget,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [columnWidget, badgeWidget],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
