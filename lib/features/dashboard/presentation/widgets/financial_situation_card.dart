import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/features/budgets/presentation/providers/budget_providers.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/providers/command_center_providers.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/widgets/financial_position_breakdown_dialog.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class FinancialSituationCard extends ConsumerWidget {
  const FinancialSituationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    final summary = ref.watch(monthlyFinancialSummaryProvider);
    final accountsSummary = ref.watch(accountsSummaryDataProvider);
    final loans = ref.watch(loansStreamProvider).value ?? [];
    final recurringRules =
        ref.watch(recurringTransactionsStreamProvider).value ?? [];
    final plannedExpenses =
        ref.watch(plannedExpensesStreamProvider).value ?? [];
    final budgets = ref.watch(budgetsStreamProvider).value ?? [];

    final activeLoans = loans.where((l) => l.active).toList();
    final totalMonthlyEmi = activeLoans.fold<double>(
      0.0,
      (sum, l) => sum + (l.emiAmount ?? 0.0),
    );

    final activeRecurringIncome = recurringRules
        .where((r) => r.active && r.type == TransactionType.income)
        .fold<double>(0.0, (sum, r) => sum + r.amount);

    final activeRecurringExpenses = recurringRules
        .where((r) => r.active && r.type == TransactionType.expense)
        .fold<double>(0.0, (sum, r) => sum + r.amount);

    final totalPlannedExpenses = plannedExpenses
        .where((p) => p.active)
        .fold<double>(0.0, (sum, p) => sum + p.defaultAmount);

    final totalBudgetedAmount = budgets.fold<double>(
      0.0,
      (sum, b) => sum + b.plannedAmount,
    );

    final expectedIncome = activeRecurringIncome > 0
        ? activeRecurringIncome
        : summary.totalIncome;

    final availableToSpend =
        expectedIncome -
        activeRecurringExpenses -
        totalMonthlyEmi -
        totalPlannedExpenses -
        (totalBudgetedAmount > (activeRecurringExpenses + totalPlannedExpenses)
            ? (totalBudgetedAmount -
                  activeRecurringExpenses -
                  totalPlannedExpenses)
            : 0.0);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final gridColumns = isDesktop ? 3 : (isTablet ? 3 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==========================================
        // SECTION 1 — FINANCIAL POSITION
        // ==========================================
        Card(
          elevation: 0,
          color: colorScheme.primaryContainer.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: colorScheme.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Icon(
                          Icons.account_balance_outlined,
                          color: colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                        Text(
                          'Financial Position',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              const FinancialPositionBreakdownDialog(),
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined, size: 16),
                      label: const Text('Breakdown'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                MoneyText(
                  accountsSummary.netBalance,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Assets',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                          Text(
                            currency.format(accountsSummary.totalAssets),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.25,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Liabilities & Debt',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                          Text(
                            currency.format(accountsSummary.totalLiabilities),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ==========================================
        // SECTION 2 — THIS MONTH CASH FLOW
        // ==========================================
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Month’s Cash Flow',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Recorded actuals vs expected full-month commitments',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/analytics'),
              icon: const Icon(Icons.show_chart_rounded, size: 16),
              label: const Text('View Analytics'),
            ),
          ],
        ),
        const SizedBox(height: 10),

        GridView.count(
          crossAxisCount: gridColumns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: gridColumns == 1 ? 2.4 : 1.4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _FlowMetricCard(
              title: 'Income (Actual)',
              amount: summary.totalIncome,
              expectedAmount: activeRecurringIncome > 0
                  ? activeRecurringIncome
                  : null,
              icon: Icons.arrow_downward_rounded,
              color: Colors.green.shade700,
              typeLabel: 'ACTUAL RECORDED',
            ),
            _FlowMetricCard(
              title: 'Expenses (Actual)',
              amount: summary.totalExpense,
              expectedAmount:
                  (activeRecurringExpenses + totalPlannedExpenses) > 0
                  ? (activeRecurringExpenses + totalPlannedExpenses)
                  : null,
              icon: Icons.arrow_upward_rounded,
              color: Colors.orange.shade800,
              typeLabel: 'ACTUAL RECORDED',
            ),
            _FlowMetricCard(
              title: 'Net Cash Flow',
              amount: summary.netCashFlow,
              icon: Icons.savings_outlined,
              color: summary.netCashFlow >= 0
                  ? Colors.teal.shade700
                  : Colors.red.shade700,
              typeLabel: 'ACTUAL SURPLUS',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ==========================================
        // SECTION 3 — AVAILABLE TO SPEND
        // ==========================================
        Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
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
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.teal.shade700,
                          size: 20,
                        ),
                        Text(
                          'Available to Safely Spend',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => context.push('/budgets'),
                      icon: const Icon(
                        Icons.pie_chart_outline_rounded,
                        size: 16,
                      ),
                      label: const Text('View Budget'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                MoneyText(
                  availableToSpend,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: availableToSpend >= 0
                        ? Colors.teal.shade800
                        : Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Calculation: Expected Income (${currency.format(expectedIncome)}) '
                  '- Recurring (${currency.format(activeRecurringExpenses)}) '
                  '- Loans (${currency.format(totalMonthlyEmi)}) '
                  '- Planned (${currency.format(totalPlannedExpenses)}) '
                  '= ${currency.format(availableToSpend)} safe margin.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FlowMetricCard extends StatelessWidget {
  final String title;
  final double amount;
  final double? expectedAmount;
  final IconData icon;
  final Color color;
  final String typeLabel;

  const _FlowMetricCard({
    required this.title,
    required this.amount,
    this.expectedAmount,
    required this.icon,
    required this.color,
    required this.typeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 16),
              ],
            ),
            MoneyText(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              expectedAmount != null
                  ? 'Expected full-mo: ${currency.format(expectedAmount!)}'
                  : typeLabel,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
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
