import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/domain/models/account_type_definition.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';

class FinancialPositionBreakdownDialog extends ConsumerWidget {
  const FinancialPositionBreakdownDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accounts = ref.watch(accountsStreamProvider).value ?? [];
    final dynamicBalances = ref.watch(calculatedAccountBalancesProvider);
    final loans = ref.watch(loansStreamProvider).value ?? [];

    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final assetAccounts = accounts
        .where((a) => a.active && a.nature == AccountNature.asset)
        .toList();
    final liabilityAccounts = accounts
        .where((a) => a.active && a.nature == AccountNature.liability)
        .toList();
    final activeLoans = loans.where((l) => l.active).toList();

    double totalAssets = 0.0;
    for (final a in assetAccounts) {
      totalAssets += dynamicBalances[a.id] ?? a.openingBalance;
    }

    double totalCreditCardDebt = 0.0;
    for (final a in liabilityAccounts) {
      totalCreditCardDebt += (dynamicBalances[a.id] ?? a.openingBalance).abs();
    }

    double totalLoanPrincipal = 0.0;
    for (final l in activeLoans) {
      totalLoanPrincipal +=
          l.outstandingPrincipal ?? l.originalPrincipal ?? 0.0;
    }

    final totalLiabilities = totalCreditCardDebt + totalLoanPrincipal;
    final netWorth = totalAssets - totalLiabilities;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 750),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.account_balance_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Financial Position Breakdown',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Where your Net Position / Net Worth comes from',
                          style: theme.textTheme.bodySmall?.copyWith(
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

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Net Position Header Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: netWorth >= 0
                              ? Colors.teal.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: netWorth >= 0
                                ? Colors.teal.shade300
                                : Colors.red.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Net Financial Position',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: netWorth >= 0
                                        ? Colors.teal.shade900
                                        : Colors.red.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currency.format(netWorth),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: netWorth >= 0
                                        ? Colors.teal.shade900
                                        : Colors.red.shade900,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Assets - Liabilities',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: netWorth >= 0
                                    ? Colors.teal.shade800
                                    : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 1. Assets Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '1. Total Assets',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currency.format(totalAssets),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (assetAccounts.isEmpty)
                        Text(
                          'No asset accounts configured yet.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        )
                      else
                        ...assetAccounts.map((acc) {
                          final bal =
                              dynamicBalances[acc.id] ?? acc.openingBalance;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 8.0,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  acc.type.icon,
                                  size: 16,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    acc.name,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  currency.format(bal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 20),

                      // 2. Liabilities Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '2. Total Liabilities & Debt',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currency.format(totalLiabilities),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (liabilityAccounts.isEmpty && activeLoans.isEmpty)
                        Text(
                          'No liabilities or debt obligations recorded.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        )
                      else ...[
                        ...liabilityAccounts.map((acc) {
                          final bal =
                              (dynamicBalances[acc.id] ?? acc.openingBalance)
                                  .abs();
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 8.0,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  acc.type.icon,
                                  size: 16,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    acc.name,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  currency.format(bal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        ...activeLoans.map((l) {
                          final principal =
                              l.outstandingPrincipal ??
                              l.originalPrincipal ??
                              0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4.0,
                              horizontal: 8.0,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.account_balance_outlined,
                                  size: 16,
                                  color: Colors.purple.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l.name,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  currency.format(principal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
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
                      context.push('/accounts');
                    },
                    icon: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 16,
                    ),
                    label: const Text('Manage Accounts'),
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
