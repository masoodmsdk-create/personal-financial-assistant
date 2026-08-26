import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/forecast/presentation/providers/forecast_providers.dart';

class ForecastBreakdownDialog extends ConsumerWidget {
  const ForecastBreakdownDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final forecast = ref.watch(multiHorizonForecastResultProvider);
    final scenarios = ref.watch(forecastScenarioComparisonsProvider);

    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.auto_graph_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comprehensive Financial Forecast',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Deterministic future cash flow & net worth projections',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Monthly Flow Equation
                      Card(
                        elevation: 0,
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Authoritative Monthly Cash Flow Math',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 16,
                                runSpacing: 10,
                                children: [
                                  _FlowChip(
                                    label: 'Expected Income',
                                    value: currency.format(
                                      forecast.monthlyRecurringIncome,
                                    ),
                                    color: Colors.green.shade800,
                                    sign: '+',
                                  ),
                                  _FlowChip(
                                    label: 'Living & Budget',
                                    value: currency.format(
                                      forecast.monthlyRecurringExpenses,
                                    ),
                                    color: Colors.orange.shade800,
                                    sign: '-',
                                  ),
                                  _FlowChip(
                                    label: 'Loan EMIs',
                                    value: currency.format(
                                      forecast.monthlyLoanEmis,
                                    ),
                                    color: Colors.purple.shade800,
                                    sign: '-',
                                  ),
                                  _FlowChip(
                                    label: 'Net Monthly Cash Flow',
                                    value: currency.format(
                                      forecast.monthlyNetCashFlow,
                                    ),
                                    color: forecast.monthlyNetCashFlow >= 0
                                        ? Colors.teal.shade800
                                        : Colors.red.shade800,
                                    sign: '=',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. Multi-Horizon Projections Table
                      Text(
                        'Future Horizons (1M, 4M, 6M, 12M)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 18,
                          headingRowColor: WidgetStateProperty.all(
                            colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Horizon',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Net Flow',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Savings',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Debt',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Net Worth',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Status',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows:
                              [
                                forecast.month1,
                                forecast.month4,
                                forecast.month6,
                                forecast.month12,
                              ].map((h) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        h.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        currency.format(
                                          h.cumulativeNetCashFlow,
                                        ),
                                        style: TextStyle(
                                          color: h.cumulativeNetCashFlow >= 0
                                              ? Colors.green.shade800
                                              : Colors.red.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(currency.format(h.projectedSavings)),
                                    ),
                                    DataCell(
                                      Text(
                                        currency.format(
                                          h.projectedLoanPrincipal,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        currency.format(h.projectedNetWorth),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: h.projectedNetWorth >= 0
                                              ? colorScheme.primary
                                              : Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Chip(
                                        label: Text(
                                          h.status.name.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor:
                                            h.status.name == 'healthy'
                                            ? Colors.green.shade100
                                            : (h.status.name == 'tight'
                                                  ? Colors.amber.shade100
                                                  : Colors.red.shade100),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. What-If Scenario Comparisons
                      Text(
                        'What-If Scenario Comparisons (12-Month Horizon)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...scenarios.map((s) {
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.tips_and_updates_outlined,
                                      color: colorScheme.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        s.scenarioName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '+${currency.format(s.netImprovement)} Net Gain',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Colors.green.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  s.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  s.outcomeExplanation,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Action Buttons
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlowChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String sign;

  const _FlowChip({
    required this.label,
    required this.value,
    required this.color,
    required this.sign,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$sign ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
