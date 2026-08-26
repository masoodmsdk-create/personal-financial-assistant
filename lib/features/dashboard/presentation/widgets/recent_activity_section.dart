import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class RecentActivitySection extends ConsumerWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);

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
        // Header
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Latest recorded transactions',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => context.push('/transactions'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('View Transactions'),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: transactionsAsync.when(
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
            loading: () => const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Could not load recent activity: $err'),
            ),
            data: (transactions) {
              if (transactions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 32,
                          color: colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No recent activity',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Record your daily expenses and income to see them here.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final categoryMap = {
                for (final c in categoriesAsync.value ?? []) c.id: c.name,
              };
              final accountMap = {
                for (final a in accountsAsync.value ?? []) a.id: a.name,
              };

              final recent = transactions.take(5).toList();

              return ListView.separated(
                itemCount: recent.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final tx = recent[index];
                  final isIncome = tx.type == TransactionType.income;
                  final isExpense = tx.type == TransactionType.expense;
                  final isTransfer = tx.type == TransactionType.transfer;

                  String title = 'Transaction';
                  if (isTransfer) {
                    final fromName = accountMap[tx.fromAccountId] ?? 'Account';
                    final toName = accountMap[tx.toAccountId] ?? 'Account';
                    title = '$fromName → $toName';
                  } else if (tx.categoryId != null) {
                    title =
                        categoryMap[tx.categoryId] ??
                        (isIncome ? 'Income' : 'Expense');
                  } else if (tx.note != null && tx.note!.isNotEmpty) {
                    title = tx.note!;
                  }

                  final dateStr = DateFormat('d MMM').format(tx.date);

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.push('/transactions'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: isIncome
                                ? Colors.teal.withValues(alpha: 0.12)
                                : isExpense
                                ? Colors.redAccent.withValues(alpha: 0.12)
                                : Colors.blue.withValues(alpha: 0.12),
                            child: Icon(
                              isIncome
                                  ? Icons.arrow_downward_rounded
                                  : isExpense
                                  ? Icons.arrow_upward_rounded
                                  : Icons.swap_horiz_rounded,
                              size: 16,
                              color: isIncome
                                  ? Colors.teal
                                  : isExpense
                                  ? Colors.redAccent
                                  : Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (tx.note != null &&
                                    tx.note!.isNotEmpty &&
                                    title != tx.note) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    tx.note!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isIncome
                                    ? '+'
                                    : isExpense
                                    ? '-'
                                    : ''}${currency.format(tx.amount)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isIncome
                                      ? Colors.teal
                                      : isExpense
                                      ? Colors.redAccent
                                      : colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
