import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/domain/models/account_type_definition.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/widgets/add_edit_account_dialog.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class AccountBreakdownDialog extends ConsumerWidget {
  final Account account;
  final AccountTypeDefinition? typeDef;

  const AccountBreakdownDialog({
    super.key,
    required this.account,
    this.typeDef,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transactions = ref.watch(transactionsStreamProvider).value ?? [];
    final calculatedBalances = ref.watch(calculatedAccountBalancesProvider);

    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final currentBalance =
        calculatedBalances[account.id] ?? account.openingBalance;

    // Filter transactions associated with this account
    final accountTxns = transactions.where((t) {
      return t.accountId == account.id ||
          t.fromAccountId == account.id ||
          t.toAccountId == account.id;
    }).toList();

    double totalInflow = 0.0;
    double totalOutflow = 0.0;
    double totalTransfers = 0.0;

    for (final t in accountTxns) {
      if (t.type == TransactionType.income && t.accountId == account.id) {
        totalInflow += t.amount;
      } else if (t.type == TransactionType.expense &&
          t.accountId == account.id) {
        totalOutflow += t.amount;
      } else if (t.type == TransactionType.transfer) {
        if (t.toAccountId == account.id) totalTransfers += t.amount;
        if (t.fromAccountId == account.id) totalTransfers -= t.amount;
      }
    }

    final icon = typeDef?.icon ?? account.type.icon;
    final color = typeDef?.color ?? account.type.color;
    final typeName = typeDef?.name ?? account.type.displayName;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$typeName • ${account.currency}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Breakdown Numbers Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _BreakdownRow(
                      label: 'Opening Balance',
                      value: currency.format(account.openingBalance),
                      color: Colors.black87,
                    ),
                    const SizedBox(height: 8),
                    _BreakdownRow(
                      label: 'Income Inflows',
                      value: '+${currency.format(totalInflow)}',
                      color: Colors.green.shade800,
                    ),
                    const SizedBox(height: 8),
                    _BreakdownRow(
                      label: 'Expenses Outflows',
                      value: '-${currency.format(totalOutflow)}',
                      color: Colors.red.shade800,
                    ),
                    const SizedBox(height: 8),
                    _BreakdownRow(
                      label: 'Net Transfers',
                      value: totalTransfers >= 0
                          ? '+${currency.format(totalTransfers)}'
                          : currency.format(totalTransfers),
                      color: Colors.blue.shade800,
                    ),
                    const Divider(height: 20),
                    _BreakdownRow(
                      label: 'Current Dynamic Balance',
                      value: currency.format(currentBalance),
                      color: account.isLiabilityAccount
                          ? Colors.red.shade800
                          : colorScheme.primary,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Recent Transactions Under This Account
              Text(
                'Recent Account Transactions (${accountTxns.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: accountTxns.isEmpty
                    ? Center(
                        child: Text(
                          'No transactions recorded for this account yet.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: accountTxns.take(10).length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final t = accountTxns[index];
                          final isIncome = t.type == TransactionType.income;
                          final isTransfer = t.type == TransactionType.transfer;
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              isIncome
                                  ? Icons.arrow_downward_rounded
                                  : (isTransfer
                                        ? Icons.swap_horiz_rounded
                                        : Icons.arrow_upward_rounded),
                              color: isIncome
                                  ? Colors.green
                                  : (isTransfer ? Colors.blue : Colors.red),
                              size: 18,
                            ),
                            title: Text(
                              t.note != null && t.note!.isNotEmpty
                                  ? t.note!
                                  : (isTransfer ? 'Transfer' : 'Transaction'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              DateFormat.MMMd().format(t.date),
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Text(
                              '${isIncome ? "+" : (isTransfer ? "" : "-")}${currency.format(t.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isIncome
                                    ? Colors.green.shade800
                                    : (isTransfer
                                          ? Colors.blue.shade800
                                          : Colors.red.shade800),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (_) => AddEditAccountDialog(account: account),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Account'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
