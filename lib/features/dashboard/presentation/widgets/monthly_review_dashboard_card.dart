import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/review/presentation/providers/monthly_review_providers.dart';

class MonthlyReviewDashboardCard extends ConsumerWidget {
  const MonthlyReviewDashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    final reviewAsync = ref.watch(monthlyReviewDataProvider);

    return reviewAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
      data: (data) {

        final now = DateTime.now();
        final monthName = DateFormat('MMMM yyyy').format(now);

        final diffText = data.isAbovePlan
            ? '${currencyFormat.format(data.plannedVsActualDiff)} above plan'
            : '${currencyFormat.format(data.plannedVsActualDiff)} below plan';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
          ),
          color: colorScheme.primaryContainer.withValues(alpha: 0.2),
          child: InkWell(
            onTap: () => context.push('/monthly-review'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fact_check_outlined,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Financial Review',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$monthName • Actual vs Planned: $diffText',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: colorScheme.primary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
