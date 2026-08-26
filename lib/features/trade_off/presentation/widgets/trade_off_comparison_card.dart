import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/trade_off/domain/models/trade_off_models.dart';
import 'package:personal_financial_assistant/features/trade_off/presentation/providers/trade_off_providers.dart';

class TradeOffComparisonCard extends ConsumerStatefulWidget {
  const TradeOffComparisonCard({super.key});

  @override
  ConsumerState<TradeOffComparisonCard> createState() =>
      _TradeOffComparisonCardState();
}

class _TradeOffComparisonCardState
    extends ConsumerState<TradeOffComparisonCard> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    final amount = ref.read(extraCashFlowAmountProvider);
    _amountController = TextEditingController(text: amount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final comparison = ref.watch(tradeOffComparisonProvider);
    final allocationType = ref.watch(tradeOffAllocationTypeProvider);
    final selectedStrategy = ref.watch(selectedTradeOffStrategyProvider);
    final customLoanPercent = ref.watch(customSplitLoanPercentageProvider);

    final loansAsync = ref.watch(loansStreamProvider);
    final goalsAsync = ref.watch(goalsStreamProvider);

    final activeLoans = (loansAsync.value ?? [])
        .where((l) => l.active)
        .toList();
    final activeGoals = (goalsAsync.value ?? [])
        .where((g) => g.active)
        .toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.balance_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Loan Prepayment vs Goal Savings',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Compare interest savings vs liquid savings growth',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount Input & Type Selector
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 500;
                final amountField = TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Extra Cash Amount',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null && parsed >= 0) {
                      ref.read(extraCashFlowAmountProvider.notifier).state =
                          parsed;
                    }
                  },
                );

                final selector = SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<TradeOffAllocationType>(
                    segments: const [
                      ButtonSegment(
                        value: TradeOffAllocationType.monthlyRecurring,
                        label: Text('Monthly', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: TradeOffAllocationType.oneTimeLumpSum,
                        label: Text('Lump Sum', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    selected: {allocationType},
                    onSelectionChanged: (set) {
                      ref.read(tradeOffAllocationTypeProvider.notifier).state =
                          set.first;
                    },
                  ),
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      amountField,
                      const SizedBox(height: 12),
                      selector,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: amountField),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: selector),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Select Target Loan & Goal Dropdowns
            if (activeLoans.isNotEmpty || activeGoals.isNotEmpty) ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 500;

                  Widget? loanDropdown;
                  if (activeLoans.isNotEmpty) {
                    loanDropdown = DropdownButtonFormField<String?>(
                      initialValue: comparison.selectedLoan?.id,
                      decoration: InputDecoration(
                        labelText: 'Target Loan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      isExpanded: true,
                      items: activeLoans.map((l) {
                        return DropdownMenuItem<String?>(
                          value: l.id,
                          child: Text(
                            '${l.name} (${l.interestRate ?? 0}%)',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        ref
                                .read(selectedTradeOffLoanIdProvider.notifier)
                                .state =
                            val;
                      },
                    );
                  }

                  Widget? goalDropdown;
                  if (activeGoals.isNotEmpty) {
                    goalDropdown = DropdownButtonFormField<String?>(
                      initialValue: comparison.selectedGoal?.id,
                      decoration: InputDecoration(
                        labelText: 'Target Goal',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      isExpanded: true,
                      items: activeGoals.map((g) {
                        return DropdownMenuItem<String?>(
                          value: g.id,
                          child: Text(
                            '${g.name} (${currency.format(g.targetAmount)})',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        ref
                                .read(selectedTradeOffGoalIdProvider.notifier)
                                .state =
                            val;
                      },
                    );
                  }

                  if (isNarrow) {
                    return Column(
                      children: [
                        ?loanDropdown,
                        if (loanDropdown != null && goalDropdown != null)
                          const SizedBox(height: 12),
                        ?goalDropdown,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      if (loanDropdown != null) Expanded(child: loanDropdown),
                      if (loanDropdown != null && goalDropdown != null)
                        const SizedBox(width: 12),
                      if (goalDropdown != null) Expanded(child: goalDropdown),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            // Insufficient Data State
            if (!comparison.hasSufficientData) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        comparison.missingDataExplanation ?? 'Enter valid cash flow, loan, and goal details to simulate.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Strategy Selection Segment
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: TradeOffStrategy.values.map((strat) {
                    final isSelected = selectedStrategy == strat;
                    final stratResult = comparison.getStrategyResult(strat);
                    final isRec = stratResult?.isRecommended ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        selected: isSelected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isRec) ...[
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(strat.displayName),
                          ],
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            ref
                                    .read(
                                      selectedTradeOffStrategyProvider.notifier,
                                    )
                                    .state =
                                strat;
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Active Strategy Metric Card
              _StrategyDetailView(
                result:
                    comparison.getStrategyResult(selectedStrategy) ??
                    comparison.strategies.first,
                currency: currency,
                colorScheme: colorScheme,
                theme: theme,
                onSliderChanged: selectedStrategy == TradeOffStrategy.custom
                    ? (val) =>
                          ref
                                  .read(
                                    customSplitLoanPercentageProvider.notifier,
                                  )
                                  .state =
                              val
                    : null,
                customLoanPercent: customLoanPercent,
              ),
              const SizedBox(height: 16),

              // Priority-Aware "Why FINAURA Recommends This" Banner
              if (comparison.recommendedStrategy != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'Recommendation: ${comparison.recommendedStrategy!.strategy.displayName}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                if (comparison
                                        .recommendedStrategy!
                                        .recommendationBadge !=
                                    null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      comparison
                                          .recommendedStrategy!
                                          .recommendationBadge!,
                                      style: TextStyle(
                                        color: colorScheme.onSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              comparison.recommendationRationale,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSecondaryContainer
                                    .withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _StrategyDetailView extends StatelessWidget {
  final TradeOffStrategyResult result;
  final NumberFormat currency;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final ValueChanged<double>? onSliderChanged;
  final double customLoanPercent;

  const _StrategyDetailView({
    required this.result,
    required this.currency,
    required this.colorScheme,
    required this.theme,
    this.onSliderChanged,
    this.customLoanPercent = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result.isRecommended
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.2),
          width: result.isRecommended ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headline
          Row(
            children: [
              Expanded(
                child: Text(
                  result.headline,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              if (result.isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Colors.amber.shade900,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Recommended',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Rationale Text
          Text(
            result.rationale,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Custom Split Slider (if active)
          if (onSliderChanged != null) ...[
            Text(
              'Custom Split: ${customLoanPercent.toStringAsFixed(0)}% Loan / ${(100 - customLoanPercent).toStringAsFixed(0)}% Goal',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            Slider(
              value: customLoanPercent,
              min: 0.0,
              max: 100.0,
              divisions: 20,
              label: '${customLoanPercent.toStringAsFixed(0)}% Loan',
              onChanged: onSliderChanged,
            ),
            const SizedBox(height: 8),
          ],

          // 4-Column / 2-Column Metrics Comparison Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              final tileWidth = isNarrow
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricTile(
                    width: tileWidth,
                    title: 'Loan Prepayment',
                    value: currency.format(result.allocatedToLoan),
                    subtitle: result.interestSaved > 0
                        ? 'Saves ${currency.format(result.interestSaved)} interest'
                        : '0% allocated',
                    icon: Icons.savings_outlined,
                    color: const Color(0xFF2E7D32),
                    theme: theme,
                  ),
                  _MetricTile(
                    width: tileWidth,
                    title: 'Tenure Cut',
                    value: '${result.monthsSaved} Months',
                    subtitle: result.newLoanClosureDate != null
                        ? 'Closes ${DateFormat('MMM yyyy').format(result.newLoanClosureDate!)}'
                        : 'No change',
                    icon: Icons.speed_rounded,
                    color: Colors.blue.shade700,
                    theme: theme,
                  ),
                  _MetricTile(
                    width: tileWidth,
                    title: 'Goal Contribution',
                    value: currency.format(result.allocatedToGoal),
                    subtitle: result.goalMonthsSaved > 0
                        ? '${result.goalMonthsSaved}m accelerated'
                        : '+${currency.format(result.liquidityImpact)} liquidity',
                    icon: Icons.flag_outlined,
                    color: Colors.orange.shade700,
                    theme: theme,
                  ),
                  _MetricTile(
                    width: tileWidth,
                    title: 'Opportunity Cost',
                    value: currency.format(result.opportunityCost),
                    subtitle: 'Foregone interest savings',
                    icon: Icons.swap_horiz_rounded,
                    color: result.opportunityCost > 0
                        ? colorScheme.error
                        : colorScheme.outline,
                    theme: theme,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final double? width;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  const _MetricTile({
    this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
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
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
