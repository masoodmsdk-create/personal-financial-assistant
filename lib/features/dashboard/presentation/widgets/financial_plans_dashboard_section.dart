import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/plans_progress/domain/models/plan_progress_models.dart';
import 'package:personal_financial_assistant/features/plans_progress/presentation/providers/plans_progress_providers.dart';

class FinancialPlansDashboardSection extends ConsumerWidget {
  const FinancialPlansDashboardSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(financialPlansSummaryProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Plans',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "How you're progressing toward your targets",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (summary.attentionItemsCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
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
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${summary.attentionItemsCount} need attention',
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
        const SizedBox(height: 12),

        // Compact Summary Pill Card
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Wrap(
              spacing: 20,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _SummaryPill(
                  icon: Icons.account_balance_outlined,
                  color: Colors.purple.shade700,
                  label: 'Loans Portfolio',
                  value: summary.hasLoans
                      ? '${currency.format(summary.totalLoanOutstanding)} • ${currency.format(summary.totalMonthlyEmi)}/mo'
                      : 'No active loans',
                ),
                _SummaryPill(
                  icon: Icons.flag_outlined,
                  color: Colors.teal.shade700,
                  label: 'Goals Progress',
                  value: summary.hasGoals
                      ? '${currency.format(summary.totalGoalCurrent)} / ${currency.format(summary.totalGoalTarget)} (${summary.overallGoalProgressPercentage.toStringAsFixed(0)}%)'
                      : 'No active goals',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // If no plans exist at all
        if (!summary.hasPlans) ...[
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.track_changes_outlined,
                      size: 36,
                      color: colorScheme.primary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No Financial Plans Configured',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add a loan or savings goal with a target date to track your plan vs projection progress.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => context.push('/loans'),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Loan'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => context.push('/goals'),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Goal'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // Loan Progress Cards
        if (summary.hasLoans) ...[
          ...summary.prioritizedLoanItems.map(
            (item) => _LoanProgressCard(item: item),
          ),
        ],

        // Goal Progress Cards
        if (summary.hasGoals) ...[
          ...summary.prioritizedGoalItems.map(
            (item) => _GoalProgressCard(item: item),
          ),
        ],

        // Section Footer Navigation
        if (summary.hasPlans) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => context.push('/trade-off'),
                icon: const Icon(Icons.balance_rounded, size: 16),
                label: const Text('Trade-Offs'),
              ),
              if (summary.hasLoans)
                TextButton.icon(
                  onPressed: () => context.push('/loans'),
                  icon: const Icon(Icons.account_balance_outlined, size: 16),
                  label: const Text('View All Loans'),
                ),
              if (summary.hasGoals)
                TextButton.icon(
                  onPressed: () => context.push('/goals'),
                  icon: const Icon(Icons.flag_outlined, size: 16),
                  label: const Text('View All Goals'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _SummaryPill({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoanProgressCard extends StatelessWidget {
  final LoanProgressItem item;

  const _LoanProgressCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('MMM yyyy');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: item.status.needsAttention
              ? item.status.color.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Status Badge
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: item.loan.type.color.withValues(alpha: 0.12),
                  child: Icon(
                    item.loan.type.icon,
                    size: 18,
                    color: item.loan.type.color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.loan.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.loan.type.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: item.status, headline: item.headline),
              ],
            ),
            const Divider(height: 18),

            // Metrics Row
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _MetricTile(
                  label: 'Outstanding',
                  value: currency.format(item.outstandingPrincipal),
                ),
                _MetricTile(
                  label: 'Monthly EMI',
                  value: '${currency.format(item.emi)}/mo',
                ),
                if (item.remainingEmis != null)
                  _MetricTile(
                    label: 'EMIs Remaining',
                    value: '${item.remainingEmis}',
                  ),
                _MetricTile(
                  label: 'Target Closure',
                  value: item.targetClosureDate != null
                      ? dateFmt.format(item.targetClosureDate!)
                      : 'Not Set',
                  highlightColor: item.targetClosureDate == null
                      ? Colors.blueGrey
                      : null,
                ),
                _MetricTile(
                  label: 'Projected Closure',
                  value: item.projectedClosureDate != null
                      ? dateFmt.format(item.projectedClosureDate!)
                      : 'Unknown',
                ),
              ],
            ),

            // Neutral Factual Explanation
            if (item.explanation.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: item.status.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.status.color.withValues(alpha: 0.2),
                  ),
                ),

                child: Text(
                  item.explanation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: item.status.needsAttention
                        ? item.status.color
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push('/loans/${item.loan.id}'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text(
                  'View Loan Details',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  final GoalProgressItem item;

  const _GoalProgressCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('MMM yyyy');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: item.status.needsAttention
              ? item.status.color.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Status
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: item.goal.type.color.withValues(alpha: 0.12),
                  child: Icon(
                    item.goal.type.icon,
                    size: 18,
                    color: item.goal.type.color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.goal.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.goal.type.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: item.status, headline: item.headline),
              ],
            ),
            const SizedBox(height: 10),

            // Amount Progress & Percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${currency.format(item.currentAmount)} / ${currency.format(item.targetAmount)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item.isAchieved ? Colors.green : colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            PercentageIndicator(
              percentage: item.percentage / 100.0,
              color: item.isAchieved ? Colors.green : colorScheme.primary,
              height: 6,
            ),
            const SizedBox(height: 10),

            // Target vs Projected
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _MetricTile(
                  label: 'Target Date',
                  value: item.targetDate != null
                      ? dateFmt.format(item.targetDate!)
                      : 'Not Set',
                ),
                _MetricTile(
                  label: 'Projected Completion',
                  value: item.projectedCompletionDate != null
                      ? dateFmt.format(item.projectedCompletionDate!)
                      : 'Unknown',
                ),
                if (item.actualMonthlyAverage != null &&
                    item.actualMonthlyAverage! > 0)
                  _MetricTile(
                    label: 'Current Pace',
                    value: '${currency.format(item.actualMonthlyAverage)}/mo',
                  ),
              ],
            ),

            // Factual Explanation
            if (item.explanation.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: item.status.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.status.color.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  item.explanation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: item.status.needsAttention
                        ? item.status.color
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push('/goals'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text(
                  'View Goal Details',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final PlanProgressStatus status;
  final String headline;

  const _StatusChip({required this.status, required this.headline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: status.color.withValues(alpha: 0.4)),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 4),
          Text(
            headline,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? highlightColor;

  const _MetricTile({
    required this.label,
    required this.value,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: highlightColor,
          ),
        ),
      ],
    );
  }
}
