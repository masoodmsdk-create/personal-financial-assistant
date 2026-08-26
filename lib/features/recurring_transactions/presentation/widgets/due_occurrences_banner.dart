import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';

class DueOccurrencesBanner extends ConsumerStatefulWidget {
  const DueOccurrencesBanner({super.key});

  @override
  ConsumerState<DueOccurrencesBanner> createState() =>
      _DueOccurrencesBannerState();
}

class _DueOccurrencesBannerState extends ConsumerState<DueOccurrencesBanner> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final dueRules = ref.watch(dueRecurringTransactionsProvider);
    if (dueRules.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    final totalDueAmount = dueRules.fold<double>(
      0.0,
      (sum, r) => sum + (r.isIncome ? r.amount : -r.amount),
    );

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: colorScheme.primaryContainer.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_mode_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${dueRules.length} Recurring ${dueRules.length == 1 ? 'Transaction' : 'Transactions'} Due',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currencyFormat.format(totalDueAmount.abs()),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: totalDueAmount >= 0
                        ? Colors.green[700]
                        : colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Recurring occurrences are ready to be recorded into your transaction history.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _isProcessing = true);
                          final count = await ref
                              .read(
                                recurringTransactionControllerProvider.notifier,
                              )
                              .processAllDueRules();
                          if (mounted) {
                            setState(() => _isProcessing = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  count > 0
                                      ? 'Successfully generated $count recurring ${count == 1 ? 'transaction' : 'transactions'}!'
                                      : 'No transactions needed processing.',
                                ),
                                backgroundColor: Colors.green[700],
                              ),
                            );
                          }
                        },
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    _isProcessing
                        ? 'Processing...'
                        : 'Process Due (${dueRules.length})',
                  ),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
