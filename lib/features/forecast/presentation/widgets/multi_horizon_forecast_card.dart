import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/forecast/presentation/providers/forecast_providers.dart';
import 'package:personal_financial_assistant/features/forecast/presentation/widgets/forecast_breakdown_dialog.dart';

class MultiHorizonForecastCard extends ConsumerStatefulWidget {
  const MultiHorizonForecastCard({super.key});

  @override
  ConsumerState<MultiHorizonForecastCard> createState() =>
      _MultiHorizonForecastCardState();
}

class _MultiHorizonForecastCardState
    extends ConsumerState<MultiHorizonForecastCard> {
  int _selectedHorizon = 1; // 1, 4, 6, 12

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final forecast = ref.watch(multiHorizonForecastResultProvider);
    final projection = forecast.getProjection(_selectedHorizon);

    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_graph_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Forecast',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Text(
                    'PROJECTED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Deterministic future projection based on recurring income, living expenses, loans, and goals.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),

            // Horizon Selector Segmented Buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1 Month')),
                  ButtonSegment(value: 4, label: Text('4 Months')),
                  ButtonSegment(value: 6, label: Text('6 Months')),
                  ButtonSegment(value: 12, label: Text('1 Year')),
                ],
                selected: {_selectedHorizon},
                onSelectionChanged: (set) {
                  setState(() => _selectedHorizon = set.first);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Metrics Grid
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ForecastMetric(
                          label: 'Projected Net Cash Flow',
                          value: currency.format(
                            projection.cumulativeNetCashFlow,
                          ),
                          color: projection.cumulativeNetCashFlow >= 0
                              ? Colors.teal.shade800
                              : Colors.red.shade800,
                          subtitle: 'Over ${_selectedHorizon}mo',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ForecastMetric(
                          label: 'Projected Savings',
                          value: currency.format(projection.projectedSavings),
                          color: Colors.green.shade800,
                          subtitle: 'Liquid Reserve',
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _ForecastMetric(
                          label: 'Remaining Loan Principal',
                          value: currency.format(
                            projection.projectedLoanPrincipal,
                          ),
                          color: Colors.purple.shade800,
                          subtitle: 'Outstanding Debt',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ForecastMetric(
                          label: 'Projected Net Worth',
                          value: currency.format(projection.projectedNetWorth),
                          color: projection.projectedNetWorth >= 0
                              ? colorScheme.primary
                              : Colors.red.shade700,
                          subtitle: 'Assets - Liabilities',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Milestone Alerts (Loans closed / Goals achieved)
            if (projection.loansClosed.isNotEmpty ||
                projection.goalsAchieved.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.celebration_rounded,
                      color: Colors.green.shade800,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        [
                          if (projection.loansClosed.isNotEmpty)
                            '${projection.loansClosed.join(", ")} will be completely paid off!',
                          if (projection.goalsAchieved.isNotEmpty)
                            '${projection.goalsAchieved.join(", ")} goal target reached!',
                        ].join(' • '),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'Target horizon: ${DateFormat.yMMMd().format(projection.targetDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const ForecastBreakdownDialog(),
                    );
                  },
                  icon: const Icon(Icons.insights_rounded, size: 16),
                  label: const Text('View Forecast & Scenarios'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String subtitle;

  const _ForecastMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          subtitle,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
