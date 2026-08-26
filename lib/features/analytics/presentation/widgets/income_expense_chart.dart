import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:personal_financial_assistant/features/transactions/domain/services/financial_aggregation_service.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class IncomeExpenseChartCard extends ConsumerWidget {
  const IncomeExpenseChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mode = ref.watch(selectedAnalyticsPeriodModeProvider);
    final range = ref.watch(periodDateRangeProvider);
    final txs = ref.watch(periodTransactionsProvider);

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    if (txs.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 48,
                color: colorScheme.outline.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Income vs Expense Trend',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No transactions recorded for ${range.label}. Add income or expense transactions to view trends.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final buckets = _generateChartBuckets(txs, mode, range);

    double maxVal = 0.0;
    for (final b in buckets) {
      if (b.income > maxVal) maxVal = b.income;
      if (b.expense > maxVal) maxVal = b.expense;
    }
    if (maxVal == 0.0) maxVal = 1.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
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
              runSpacing: 4,
              children: [
                Text(
                  'Income vs Expense',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  range.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                const _LegendItem(color: Color(0xFF2E7D32), label: 'Income'),
                const _LegendItem(color: Color(0xFFD32F2F), label: 'Expense'),
                _LegendItem(color: colorScheme.primary, label: 'Net Cash Flow'),
              ],
            ),
            const SizedBox(height: 20),

            // Bar Chart Visualization
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: buckets.map((b) {
                  final incomeRatio = (b.income / maxVal).clamp(0.0, 1.0);
                  final expenseRatio = (b.expense / maxVal).clamp(0.0, 1.0);

                  return Expanded(
                    child: Tooltip(
                      message:
                          '${b.label}\nIncome: ${currencyFormat.format(b.income)}\nExpense: ${currencyFormat.format(b.expense)}\nNet: ${currencyFormat.format(b.net)}',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Income bar
                                Container(
                                  width: 8,
                                  height: 140 * incomeRatio,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                // Expense bar
                                Container(
                                  width: 8,
                                  height: 140 * expenseRatio,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD32F2F),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            b.shortLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ChartBucket> _generateChartBuckets(
    List<Transaction> txs,
    AnalyticsPeriodMode mode,
    PeriodDateRange range,
  ) {
    final List<_ChartBucket> buckets = [];

    switch (mode) {
      case AnalyticsPeriodMode.weekly:
        // 7 days (Mon..Sun)
        final monday = range.start;
        for (int i = 0; i < 7; i++) {
          final day = monday.add(Duration(days: i));
          final dayTxs = txs.where((t) {
            return t.date.year == day.year &&
                t.date.month == day.month &&
                t.date.day == day.day;
          }).toList();
          final inc = FinancialAggregationService.calculateTotalIncome(dayTxs);
          final exp = FinancialAggregationService.calculateTotalExpense(dayTxs);
          buckets.add(
            _ChartBucket(
              label: DateFormat('EEEE, MMM dd').format(day),
              shortLabel: DateFormat('E').format(day),
              income: inc,
              expense: exp,
              net: inc - exp,
            ),
          );
        }
        break;

      case AnalyticsPeriodMode.monthly:
        // 4 Weeks / intervals in the month
        final start = range.start;
        final daysInMonth = DateTime(start.year, start.month + 1, 0).day;
        final weekSize = (daysInMonth / 4).ceil();

        for (int i = 0; i < 4; i++) {
          final wStartDay = (i * weekSize) + 1;
          var wEndDay = (i + 1) * weekSize;
          if (wEndDay > daysInMonth) wEndDay = daysInMonth;

          final weekTxs = txs.where((t) {
            return t.date.year == start.year &&
                t.date.month == start.month &&
                t.date.day >= wStartDay &&
                t.date.day <= wEndDay;
          }).toList();

          final inc = FinancialAggregationService.calculateTotalIncome(weekTxs);
          final exp = FinancialAggregationService.calculateTotalExpense(
            weekTxs,
          );
          buckets.add(
            _ChartBucket(
              label: 'Days $wStartDay - $wEndDay',
              shortLabel: 'W${i + 1}',
              income: inc,
              expense: exp,
              net: inc - exp,
            ),
          );
        }
        break;

      case AnalyticsPeriodMode.yearly:
        // 12 Months
        final year = range.start.year;
        for (int m = 1; m <= 12; m++) {
          final monthTxs = txs.where((t) {
            return t.date.year == year && t.date.month == m;
          }).toList();
          final inc = FinancialAggregationService.calculateTotalIncome(
            monthTxs,
          );
          final exp = FinancialAggregationService.calculateTotalExpense(
            monthTxs,
          );
          final date = DateTime(year, m, 1);
          buckets.add(
            _ChartBucket(
              label: DateFormat('MMMM yyyy').format(date),
              shortLabel: DateFormat('MMM').format(date),
              income: inc,
              expense: exp,
              net: inc - exp,
            ),
          );
        }
        break;
    }

    return buckets;
  }
}

class _ChartBucket {
  final String label;
  final String shortLabel;
  final double income;
  final double expense;
  final double net;

  _ChartBucket({
    required this.label,
    required this.shortLabel,
    required this.income,
    required this.expense,
    required this.net,
  });
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
