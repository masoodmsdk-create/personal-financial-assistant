import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/review/domain/models/monthly_review_data.dart';

class GoalsLoanProgressCard extends StatelessWidget {
  final List<GoalProgressSummary> goalSummaries;
  final List<LoanProgressSummary> loanSummaries;

  const GoalsLoanProgressCard({
    super.key,
    required this.goalSummaries,
    required this.loanSummaries,
  });

  @override
  Widget build(BuildContext context) {
    if (goalSummaries.isEmpty && loanSummaries.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

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
                  Icons.track_changes_outlined,
                  color: colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Goals & Loan Payoff Progress',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Active Goals Progress
            if (goalSummaries.isNotEmpty) ...[
              Text(
                'ACTIVE SAVINGS & FINANCIAL GOALS',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...goalSummaries.map((g) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                g.goal.type.icon,
                                size: 18,
                                color: g.goal.type.color,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  g.goal.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${currencyFormat.format(g.currentAmount)} / ${currencyFormat.format(g.targetAmount)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: g.progressPercentage / 100.0,
                          minHeight: 8,
                          backgroundColor: colorScheme.outlineVariant
                              .withValues(alpha: 0.3),
                          color: g.goal.type.color,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],

            if (goalSummaries.isNotEmpty && loanSummaries.isNotEmpty)
              const Divider(height: 24),

            // Active Loans Progress
            if (loanSummaries.isNotEmpty) ...[
              Text(
                'ACTIVE LOAN OBLIGATIONS & PAYOFF FORECASTS',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...loanSummaries.map((l) {
                final f = l.forecast;
                final closureText = f.estimatedClosureDate != null
                    ? DateFormat('MMM yyyy').format(f.estimatedClosureDate!)
                    : 'N/A';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          l.loan.type.icon,
                          size: 22,
                          color: l.loan.type.color,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.loan.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'EMI: ${currencyFormat.format(l.currentEmi ?? 0.0)} • Est. Closure: $closureText',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
