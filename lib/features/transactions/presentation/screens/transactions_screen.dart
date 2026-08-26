import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';

import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/core/widgets/responsive_center.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';

import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/widgets/due_occurrences_banner.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/widgets/add_edit_transaction_dialog.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final DateFormat _dateFormat = DateFormat('EEE, MMM dd, yyyy');

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddEditTransactionDialog(),
    );
  }

  void _showEditTransactionDialog(Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AddEditTransactionDialog(transaction: transaction),
    );
  }

  Future<void> _confirmDeleteTransaction(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete this ${transaction.type.displayName} transaction of ₹${transaction.amount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final errorColor = Theme.of(context).colorScheme.error;

      final success = await ref
          .read(transactionControllerProvider.notifier)
          .deleteTransaction(transaction.id);

      if (mounted) {
        if (success) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Transaction deleted'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final state = ref.read(transactionControllerProvider);
          final error = state.error;
          final errorMessage = error is AppException
              ? error.message
              : 'Failed to delete transaction';
          messenger.showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final filter = ref.watch(transactionFilterProvider);
    final summary = ref.watch(monthlyFinancialSummaryProvider);

    final accountsAsync = ref.watch(accountsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    final theme = Theme.of(context);

    final accountMap = <String, String>{};
    if (accountsAsync.hasValue) {
      for (final a in accountsAsync.value!) {
        accountMap[a.id] = a.name;
      }
    }

    final categoryMap = <String, String>{};
    if (categoriesAsync.hasValue) {
      for (final c in categoriesAsync.value!) {
        categoryMap[c.id] = c.name;
      }
    }

    return Scaffold(
      body: ResponsiveCenter(
        maxWidth: 1000,
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: 80.0,
        ),
        child: Column(
          children: [
            PageHeader(
              title: 'Transactions',
              subtitle: 'Track all income, expense, and transfer records.',
              action: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => context.push('/recurring-transactions'),
                    icon: const Icon(Icons.repeat_rounded, size: 18),
                    label: const Text('Recurring'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => context.push('/smart-entry'),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: const Text('Smart Entry'),
                  ),
                  FilledButton.icon(
                    onPressed: _showAddTransactionDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Transaction'),
                  ),
                ],
              ),
            ),

            // Due Recurring Occurrences Banner
            const DueOccurrencesBanner(),

            // Monthly Summary Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _SummaryMetric(
                      label: 'Month Income',
                      amount: summary.totalIncome,
                      color: Colors.green,
                      prefix: '+ ₹ ',
                    ),
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: _SummaryMetric(
                      label: 'Month Expense',
                      amount: summary.totalExpense,
                      color: Colors.red,
                      prefix: '- ₹ ',
                    ),
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: _SummaryMetric(
                      label: 'Net Cash Flow',
                      amount: summary.netCashFlow,
                      color: summary.netCashFlow >= 0
                          ? Colors.green
                          : Colors.red,
                      prefix: '₹ ',
                    ),
                  ),
                ],
              ),
            ),

            // Filter Header Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: filter.type == null,
                    onSelected: (_) {
                      ref.read(transactionFilterProvider.notifier).state =
                          filter.copyWith(type: () => null);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Income'),
                    selected: filter.type == TransactionType.income,
                    onSelected: (selected) {
                      ref
                          .read(transactionFilterProvider.notifier)
                          .state = filter.copyWith(
                        type: () => selected ? TransactionType.income : null,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Expense'),
                    selected: filter.type == TransactionType.expense,
                    onSelected: (selected) {
                      ref
                          .read(transactionFilterProvider.notifier)
                          .state = filter.copyWith(
                        type: () => selected ? TransactionType.expense : null,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Transfer'),
                    selected: filter.type == TransactionType.transfer,
                    onSelected: (selected) {
                      ref
                          .read(transactionFilterProvider.notifier)
                          .state = filter.copyWith(
                        type: () => selected ? TransactionType.transfer : null,
                      );
                    },
                  ),
                ],
              ),
            ),

            // Transactions List
            Expanded(
              child: transactionsAsync.when(
                skipLoadingOnReload: true,
                skipLoadingOnRefresh: true,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('Error loading transactions: $err'),
                  ),
                ),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Transactions Found',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              filter.type != null
                                  ? 'No transactions match the selected filter.'
                                  : 'Tap the button below to record your first transaction.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _showAddTransactionDialog,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Record Transaction'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                      bottom: 88,
                    ),
                    itemCount: transactions.length,

                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      final isIncome = t.type == TransactionType.income;
                      final isExpense = t.type == TransactionType.expense;
                      final isTransfer = t.type == TransactionType.transfer;

                      String subtitleText;
                      if (isTransfer) {
                        final fromName =
                            accountMap[t.fromAccountId] ?? 'Unknown';
                        final toName = accountMap[t.toAccountId] ?? 'Unknown';
                        subtitleText = '$fromName ➔ $toName';
                      } else {
                        final categoryName =
                            categoryMap[t.categoryId] ?? 'General';
                        final accountName =
                            accountMap[t.accountId] ?? 'Unknown Account';
                        subtitleText = '$categoryName • $accountName';
                      }

                      if (t.note != null && t.note!.isNotEmpty) {
                        subtitleText += '\n"${t.note}"';
                      }

                      final amountPrefix = isIncome
                          ? '+ ₹ '
                          : (isExpense ? '- ₹ ' : '₹ ');

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: t.type.color.withValues(
                              alpha: 0.1,
                            ),
                            child: Icon(t.type.icon, color: t.type.color),
                          ),
                          title: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 2,
                            children: [
                              Text(
                                t.type.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _dateFormat.format(t.date),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(subtitleText),
                          isThreeLine: t.note != null && t.note!.isNotEmpty,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$amountPrefix${t.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: t.type.color,
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded),
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _showEditTransactionDialog(t);
                                  } else if (val == 'delete') {
                                    _confirmDeleteTransaction(t);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 20),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
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
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Transaction'),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String prefix;

  const _SummaryMetric({
    required this.label,
    required this.amount,
    required this.color,
    required this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          '$prefix${amount.abs().toStringAsFixed(2)}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
