import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/loans/domain/models/what_if_scenario.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';

class WhatIfScenarioCard extends ConsumerStatefulWidget {
  const WhatIfScenarioCard({super.key});

  @override
  ConsumerState<WhatIfScenarioCard> createState() => _WhatIfScenarioCardState();
}

class _WhatIfScenarioCardState extends ConsumerState<WhatIfScenarioCard> {
  late TextEditingController _extraMonthlyController;
  late TextEditingController _annualController;
  late TextEditingController _lumpSumController;
  late TextEditingController _newEmiController;
  late TextEditingController _customRateController;
  late TextEditingController _refinanceRateController;
  late TextEditingController _refinanceFeeController;

  @override
  void initState() {
    super.initState();
    _extraMonthlyController = TextEditingController(text: '5000');
    _annualController = TextEditingController(text: '50000');
    _lumpSumController = TextEditingController(text: '100000');
    _newEmiController = TextEditingController(text: '60000');
    _customRateController = TextEditingController(text: '8.0');
    _refinanceRateController = TextEditingController(text: '7.5');
    _refinanceFeeController = TextEditingController(text: '2500');
  }

  @override
  void dispose() {
    _extraMonthlyController.dispose();
    _annualController.dispose();
    _lumpSumController.dispose();
    _newEmiController.dispose();
    _customRateController.dispose();
    _refinanceRateController.dispose();
    _refinanceFeeController.dispose();
    super.dispose();
  }

  void _updateParams(WhatIfType type) {
    ref.read(activeWhatIfTypeProvider.notifier).state = type;
    switch (type) {
      case WhatIfType.extraMonthly:
        final val = double.tryParse(_extraMonthlyController.text) ?? 5000.0;
        ref.read(activeWhatIfParamsProvider.notifier).state =
            WhatIfScenarioParams(extraMonthlyAmount: val);
        break;
      case WhatIfType.annualPrepayment:
        final val = double.tryParse(_annualController.text) ?? 50000.0;
        ref.read(activeWhatIfParamsProvider.notifier).state =
            WhatIfScenarioParams(annualPrepaymentAmount: val);
        break;
      case WhatIfType.lumpSumPrepayment:
        final val = double.tryParse(_lumpSumController.text) ?? 100000.0;
        ref.read(activeWhatIfParamsProvider.notifier).state =
            WhatIfScenarioParams(lumpSumAmount: val);
        break;
      case WhatIfType.increasedEmi:
        final val = double.tryParse(_newEmiController.text) ?? 60000.0;
        ref.read(activeWhatIfParamsProvider.notifier).state =
            WhatIfScenarioParams(newEmiAmount: val);
        break;
      case WhatIfType.interestRateChange:
        final val = double.tryParse(_customRateController.text) ?? 8.0;
        ref.read(activeWhatIfParamsProvider.notifier).state =
            WhatIfScenarioParams(scenarioInterestRate: val);
        break;
      case WhatIfType.refinanceComparison:
        final rate = double.tryParse(_refinanceRateController.text) ?? 7.5;
        final fee = double.tryParse(_refinanceFeeController.text) ?? 2500.0;
        ref
            .read(activeWhatIfParamsProvider.notifier)
            .state = WhatIfScenarioParams(
          scenarioInterestRate: rate,
          scenarioProcessingFee: fee,
        );
        break;
      case WhatIfType.targetClosureDate:
        final targetDate = DateTime.now().add(const Duration(days: 365 * 5));
        ref.read(activeWhatIfParamsProvider.notifier).state =
            WhatIfScenarioParams(desiredClosureDate: targetDate);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    final activeType = ref.watch(activeWhatIfTypeProvider);
    final result = ref.watch(whatIfScenarioResultProvider);

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
                  Icons.psychology_alt_outlined,
                  color: colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'What-If Scenario Simulator',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Simulate prepayment strategies, tenure reduction, or refinancing without modifying actual loan data.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Scenario Type Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: WhatIfType.values.map((type) {
                  final isSelected = activeType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(type.displayName),
                      selected: isSelected,
                      onSelected: (_) => _updateParams(type),
                      selectedColor: colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Input Control depending on scenario type
            _buildScenarioInputControl(context, activeType),
            const SizedBox(height: 16),

            if (result != null) ...[
              // Savings Summary Badges
              Row(
                children: [
                  Expanded(
                    child: _SavingsBadge(
                      label: 'Estimated Time Saved',
                      value: '${result.estimatedTimeSavedMonths} months',
                      icon: Icons.access_time_filled_outlined,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SavingsBadge(
                      label: activeType == WhatIfType.refinanceComparison
                          ? 'Net Refinance Savings'
                          : 'Estimated Interest Saved',
                      value: currencyFormat.format(
                        result.netRefinanceSavings ??
                            result.estimatedInterestSaved,
                      ),
                      icon: Icons.savings_outlined,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Side by Side Comparison (Current vs Scenario)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'CURRENT PLAN',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'SCENARIO',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _ComparisonRow(
                      label: 'Monthly EMI',
                      currentVal: currencyFormat.format(
                        result.baselineForecast.effectiveEmi ?? 0.0,
                      ),
                      scenarioVal: currencyFormat.format(
                        result.scenarioForecast.effectiveEmi ?? 0.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ComparisonRow(
                      label: 'Estimated Closure',
                      currentVal:
                          result.baselineForecast.estimatedClosureDate != null
                          ? DateFormat('MMM yyyy').format(
                              result.baselineForecast.estimatedClosureDate!,
                            )
                          : 'N/A',
                      scenarioVal:
                          result.scenarioForecast.estimatedClosureDate != null
                          ? DateFormat('MMM yyyy').format(
                              result.scenarioForecast.estimatedClosureDate!,
                            )
                          : 'N/A',
                    ),
                    const SizedBox(height: 8),
                    _ComparisonRow(
                      label: 'Remaining Interest',
                      currentVal: currencyFormat.format(
                        result.baselineForecast.estimatedRemainingInterest ??
                            0.0,
                      ),
                      scenarioVal: currencyFormat.format(
                        result.scenarioForecast.estimatedRemainingInterest ??
                            0.0,
                      ),
                    ),
                    if (result.breakEvenMonths != null &&
                        result.breakEvenMonths! > 0) ...[
                      const Divider(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Break-even tenure: ~${result.breakEvenMonths} months to recover estimated switching fees.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (result.requiredAdditionalMonthlyPayment != null &&
                        result.requiredAdditionalMonthlyPayment! > 0) ...[
                      const Divider(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Required extra payment: ${currencyFormat.format(result.requiredAdditionalMonthlyPayment)}/month',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                result.disclaimer,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioInputControl(BuildContext context, WhatIfType type) {
    switch (type) {
      case WhatIfType.extraMonthly:
        return TextField(
          controller: _extraMonthlyController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Extra Monthly Amount (₹)',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _updateParams(type),
        );
      case WhatIfType.annualPrepayment:
        return TextField(
          controller: _annualController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Annual Prepayment Amount (₹)',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _updateParams(type),
        );
      case WhatIfType.lumpSumPrepayment:
        return TextField(
          controller: _lumpSumController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'One-time Lump Sum Amount (₹)',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _updateParams(type),
        );
      case WhatIfType.increasedEmi:
        return TextField(
          controller: _newEmiController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'New Target EMI Amount (₹)',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _updateParams(type),
        );
      case WhatIfType.interestRateChange:
        return TextField(
          controller: _customRateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Simulated Interest Rate (%)',
            suffixText: '%',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _updateParams(type),
        );
      case WhatIfType.refinanceComparison:
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: _refinanceRateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'New Rate (%)',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _updateParams(type),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _refinanceFeeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Switching Fees (₹)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _updateParams(type),
              ),
            ),
          ],
        );
      case WhatIfType.targetClosureDate:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Simulated target closure: In 5 Years'),
              ),
              ElevatedButton(
                onPressed: () => _updateParams(type),
                child: const Text('Recalculate'),
              ),
            ],
          ),
        );
    }
  }
}

class _SavingsBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SavingsBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String currentVal;
  final String scenarioVal;

  const _ComparisonRow({
    required this.label,
    required this.currentVal,
    required this.scenarioVal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            currentVal,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            scenarioVal,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
