import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/core/widgets/responsive_center.dart';
import 'package:personal_financial_assistant/features/forecast/presentation/providers/forecast_providers.dart';
import 'package:personal_financial_assistant/features/forecast/presentation/widgets/multi_horizon_forecast_card.dart';

class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

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

    return Scaffold(
      body: SingleChildScrollView(
        child: ResponsiveCenter(
          maxWidth: 1000,
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Financial Forecast',
                subtitle: 'Multi-horizon deterministic projections across 1M, 4M, 6M, and 12M',
                action: OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back'),
                ),
              ),
              const SizedBox(height: 16),

              // Interactive Horizon Forecast Card
              const MultiHorizonForecastCard(),
              const SizedBox(height: 24),

              // Monthly Flow Mathematical Breakdown Card
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Authoritative Monthly Cash Flow Foundation',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'How your future surplus and savings accumulation are calculated',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 20,
                        runSpacing: 12,
                        children: [
                          _MetricSummary(
                            label: 'Recurring Monthly Income',
                            value: currency.format(
                              forecast.monthlyRecurringIncome,
                            ),
                            color: Colors.green.shade800,
                          ),
                          _MetricSummary(
                            label: 'Committed Living Expenses',
                            value: currency.format(
                              forecast.monthlyRecurringExpenses,
                            ),
                            color: Colors.orange.shade800,
                          ),
                          _MetricSummary(
                            label: 'Monthly Loan EMIs',
                            value: currency.format(forecast.monthlyLoanEmis),
                            color: Colors.purple.shade800,
                          ),
                          _MetricSummary(
                            label: 'Net Monthly Surplus',
                            value: currency.format(forecast.monthlyNetCashFlow),
                            color: forecast.monthlyNetCashFlow >= 0
                                ? Colors.teal.shade800
                                : Colors.red.shade800,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // What-If Scenario Comparisons Section
              Text(
                'What-If Scenario Comparisons (1-Year Horizon)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              ...scenarios.map((s) {
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
                              Icons.insights_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s.scenarioName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade300,
                                ),
                              ),
                              child: Text(
                                '+${currency.format(s.netImprovement)} Net Gain',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.outcomeExplanation,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600,
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
    );
  }
}

class _MetricSummary extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricSummary({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
