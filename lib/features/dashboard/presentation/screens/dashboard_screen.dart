import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/analytics/presentation/widgets/income_expense_chart.dart';
import 'package:personal_financial_assistant/features/analytics/presentation/widgets/things_to_review_card.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';

import 'package:personal_financial_assistant/features/dashboard/presentation/widgets/monthly_review_dashboard_card.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  String _getDisplayName(User? user) {
    final displayName = user?.displayName;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    final email = user?.email;
    if (email != null && email.isNotEmpty) {
      final namePart = email.split('@').first;
      return namePart
          .split('.')
          .map(
            (part) => part.isNotEmpty
                ? part[0].toUpperCase() + part.substring(1)
                : '',
          )
          .join(' ');
    }
    return 'Welcome';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final displayName = _getDisplayName(user);
    final greeting = _getTimeBasedGreeting();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalBalance = ref.watch(calculatedTotalBalanceProvider);
    final summary = ref.watch(monthlyFinancialSummaryProvider);

    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

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

    final initial = displayName.isNotEmpty
        ? displayName
              .trim()
              .split(' ')
              .map((e) => e[0])
              .take(2)
              .join()
              .toUpperCase()
        : 'U';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Welcome Card
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primary,
                    child: Text(
                      initial,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, $displayName 👋',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Here's your financial snapshot.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Overview Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Overview',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Chip(
                label: const Text('Live Metrics'),
                backgroundColor: colorScheme.surfaceContainerHighest,
                avatar: const Icon(Icons.show_chart_rounded, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Financial Summary Cards (Grid)
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _LiveMetricCard(
                title: 'Total Balance',
                amount: totalBalance,
                icon: Icons.account_balance_outlined,
                color: Colors.blue,
                subtitle: 'Accounts + Txns',
              ),
              _LiveMetricCard(
                title: 'Monthly Income',
                amount: summary.totalIncome,
                icon: Icons.arrow_downward_outlined,
                color: Colors.green,
                subtitle: 'Current Month',
              ),
              _LiveMetricCard(
                title: 'Monthly Expenses',
                amount: summary.totalExpense,
                icon: Icons.arrow_upward_outlined,
                color: Colors.red,
                subtitle: 'Current Month',
              ),
              _LiveMetricCard(
                title: 'Net Cash Flow',
                amount: summary.netCashFlow,
                icon: Icons.savings_outlined,
                color: summary.netCashFlow >= 0 ? Colors.green : Colors.red,
                subtitle: 'Income - Expense',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Monthly Financial Review Entry Card
          const MonthlyReviewDashboardCard(),
          const SizedBox(height: 20),

          // Things to Review Section (In-App Insights)
          const ThingsToReviewCard(),

          const SizedBox(height: 20),

          // Income vs Expense Chart Card
          const IncomeExpenseChartCard(),
          const SizedBox(height: 20),

          // Recent Transactions Section Header
          Text(
            'Recent Transactions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Real Recent Transactions List
          Card(
            child: transactionsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(child: Text('Error: $err')),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 40,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No transactions recorded yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final recentList = transactions.take(5).toList();

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentList.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final t = recentList[index];
                    final isIncome = t.type == TransactionType.income;
                    final isExpense = t.type == TransactionType.expense;
                    final isTransfer = t.type == TransactionType.transfer;

                    String subtitle;
                    if (isTransfer) {
                      final from = accountMap[t.fromAccountId] ?? 'Account';
                      final to = accountMap[t.toAccountId] ?? 'Account';
                      subtitle = '$from ➔ $to';
                    } else {
                      final cat = categoryMap[t.categoryId] ?? 'Category';
                      final acc = accountMap[t.accountId] ?? 'Account';
                      subtitle = '$cat • $acc';
                    }

                    final dateStr = DateFormat('MMM dd').format(t.date);
                    final prefix = isIncome
                        ? '+ ₹ '
                        : (isExpense ? '- ₹ ' : '₹ ');

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: t.type.color.withValues(alpha: 0.1),
                        child: Icon(t.type.icon, size: 20, color: t.type.color),
                      ),
                      title: Text(
                        t.type.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('$subtitle ($dateStr)'),
                      trailing: Text(
                        '$prefix${t.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: t.type.color,
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
    );
  }
}

class _LiveMetricCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _LiveMetricCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 20, color: color),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoneyText(
                  amount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
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
