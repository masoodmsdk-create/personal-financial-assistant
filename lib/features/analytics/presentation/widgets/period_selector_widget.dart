import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/analytics/presentation/providers/analytics_providers.dart';

class PeriodSelectorWidget extends ConsumerWidget {
  const PeriodSelectorWidget({super.key});

  void _navigateDate(WidgetRef ref, int delta) {
    final mode = ref.read(selectedAnalyticsPeriodModeProvider);
    final currentDate = ref.read(selectedAnalyticsDateProvider);

    DateTime newDate;
    switch (mode) {
      case AnalyticsPeriodMode.weekly:
        newDate = currentDate.add(Duration(days: 7 * delta));
        break;
      case AnalyticsPeriodMode.monthly:
        newDate = DateTime(
          currentDate.year,
          currentDate.month + delta,
          currentDate.day > 28 ? 28 : currentDate.day,
        );
        break;
      case AnalyticsPeriodMode.yearly:
        newDate = DateTime(
          currentDate.year + delta,
          currentDate.month,
          currentDate.day,
        );
        break;
    }
    ref.read(selectedAnalyticsDateProvider.notifier).state = newDate;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mode = ref.watch(selectedAnalyticsPeriodModeProvider);
    final range = ref.watch(periodDateRangeProvider);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            SegmentedButton<AnalyticsPeriodMode>(
              segments: AnalyticsPeriodMode.values.map((m) {
                return ButtonSegment<AnalyticsPeriodMode>(
                  value: m,
                  label: Text(m.displayName),
                );
              }).toList(),
              selected: {mode},
              onSelectionChanged: (newSelection) {
                if (newSelection.isNotEmpty) {
                  ref.read(selectedAnalyticsPeriodModeProvider.notifier).state =
                      newSelection.first;
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.outlined(
                  onPressed: () => _navigateDate(ref, -1),
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Previous Period',
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Text(
                    range.label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                IconButton.outlined(
                  onPressed: () => _navigateDate(ref, 1),
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Next Period',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
