import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/providers/command_center_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';

class FinancialSituationCard extends ConsumerWidget {
  const FinancialSituationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final summary = ref.watch(monthlyFinancialSummaryProvider);
    final totalBalance = ref.watch(calculatedTotalBalanceProvider);
    final accountsSummary = ref.watch(accountsSummaryDataProvider);
    final loans = ref.watch(loansStreamProvider).value ?? [];

    final activeLoans = loans.where((l) => l.active).toList();
    final totalMonthlyEmi = activeLoans.fold<double>(
      0.0,
      (sum, l) => sum + (l.emiAmount ?? 0.0),
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final gridColumns = isDesktop ? 4 : (isTablet ? 2 : 1);

    final availableCashFlow = summary.totalIncome -
        summary.totalExpense -
        totalMonthlyEmi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Financial Situation',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Live cash flow and dynamic balances',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Chip(
              label: const Text('Live Snapshot'),
              backgroundColor: colorScheme.surfaceContainerHighest,
              avatar: const Icon(Icons.show_chart_rounded, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Live Financial Metrics Grid
        RepaintBoundary(
          child: GridView.count(
            crossAxisCount: gridColumns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: gridColumns == 1 ? 2.6 : 1.35,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _MetricCard(
                title: 'Total Net Balance',
                amount: totalBalance,
                icon: Icons.account_balance_outlined,
                color: colorScheme.primary,
                subtitle: 'Total Assets - Liabilities',
                isPrimary: true,
              ),
              _MetricCard(
                title: 'Monthly Income',
                amount: summary.totalIncome,
                icon: Icons.arrow_downward_outlined,
                color: Colors.teal,
                subtitle: 'Current Month Inflows',
              ),
              _MetricCard(
                title: 'Monthly Expenses',
                amount: summary.totalExpense,
                icon: Icons.arrow_upward_outlined,
                color: Colors.redAccent,
                subtitle: 'Living & Discretionary',
              ),
              _MetricCard(
                title: 'Remaining Cash Flow',
                amount: availableCashFlow,
                icon: Icons.savings_outlined,
                color: availableCashFlow >= 0 ? Colors.teal : Colors.redAccent,
                subtitle: totalMonthlyEmi > 0
                    ? 'After ${currency.format(totalMonthlyEmi)} EMI'
                    : 'Income - Expenses',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Compact Accounts Summary Card
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push('/accounts'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accounts Overview (${accountsSummary.activeAccountsCount} Active)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Assets: ${currency.format(accountsSummary.totalAssets)} • Liabilities: ${currency.format(accountsSummary.totalLiabilities)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final String subtitle;
  final bool isPrimary;

  const _MetricCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.subtitle,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isPrimary ? 2 : 0,
      color: isPrimary
          ? colorScheme.primaryContainer.withValues(alpha: 0.7)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPrimary
            ? BorderSide(color: colorScheme.primary.withValues(alpha: 0.4), width: 1.5)
            : BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isPrimary
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            MoneyText(
              amount,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isPrimary ? colorScheme.onPrimaryContainer : null,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isPrimary
                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                    : colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

