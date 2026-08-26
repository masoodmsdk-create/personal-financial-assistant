import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/budgets/presentation/providers/budget_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class AvailableToSpendBreakdownDialog extends ConsumerWidget {
  const AvailableToSpendBreakdownDialog({super.key});

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

    final uncommittedVariableBudget =
        totalBudgetedAmount > (activeRecurringExpenses + totalPlannedExpenses)
        ? (totalBudgetedAmount - activeRecurringExpenses - totalPlannedExpenses)
        : 0.0;

    final availableToSpend =
        expectedIncome -
        activeRecurringExpenses -
        totalMonthlyEmi -
        totalPlannedExpenses -
        uncommittedVariableBudget;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available to Spend Breakdown',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Deterministic math behind your safe-to-spend margin',
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
                      // Total Summary Header Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: availableToSpend >= 0
                              ? Colors.teal.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: availableToSpend >= 0
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
                                  'Available to Safely Spend',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: availableToSpend >= 0
                                        ? Colors.teal.shade900
                                        : Colors.red.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currency.format(availableToSpend),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: availableToSpend >= 0
                                        ? Colors.teal.shade900
                                        : Colors.red.shade900,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              availableToSpend >= 0
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.warning_amber_rounded,
                              color: availableToSpend >= 0
                                  ? Colors.teal.shade800
                                  : Colors.red.shade800,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'Calculation Breakdown',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _BreakdownTile(
                        title: '1. Expected Monthly Income',
                        subtitle: activeRecurringIncome > 0
                            ? 'From active recurring income rules'
                            : 'From actual recorded income this month',
                        amount: expectedIncome,
                        isAddition: true,
                        color: Colors.green.shade800,
                      ),
                      const SizedBox(height: 8),

                      _BreakdownTile(
                        title: '2. Recurring Expense Commitments',
                        subtitle:
                            '${recurringRules.where((r) => r.active && r.type == TransactionType.expense).length} active recurring rules (rent, subscriptions, bills)',
                        amount: activeRecurringExpenses,
                        isAddition: false,
                        color: Colors.orange.shade800,
                      ),
                      const SizedBox(height: 8),

                      _BreakdownTile(
                        title: '3. Monthly Loan EMIs',
                        subtitle:
                            '${activeLoans.length} active loan obligations',
                        amount: totalMonthlyEmi,
                        isAddition: false,
                        color: Colors.purple.shade800,
                      ),
                      const SizedBox(height: 8),

                      _BreakdownTile(
                        title: '4. Planned / Non-Monthly Expenses',
                        subtitle:
                            '${plannedExpenses.where((p) => p.active).length} planned future commitments due this period',
                        amount: totalPlannedExpenses,
                        isAddition: false,
                        color: Colors.indigo.shade800,
                      ),
                      const SizedBox(height: 8),

                      if (uncommittedVariableBudget > 0) ...[
                        _BreakdownTile(
                          title: '5. Variable Budget Reservations',
                          subtitle: 'Category budget allocations exceeding recurring/planned items',
                          amount: uncommittedVariableBudget,
                          isAddition: false,
                          color: Colors.brown.shade800,
                        ),
                        const SizedBox(height: 8),
                      ],

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Note: Available to Spend reflects uncommitted cash. Future unearned income is not treated as liquid until received.',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/budgets');
                    },
                    icon: const Icon(Icons.pie_chart_outline_rounded, size: 16),
                    label: const Text('Manage Budgets'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Got it'),
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

class _BreakdownTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final bool isAddition;
  final Color color;

  const _BreakdownTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isAddition,
    required this.color,
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
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${isAddition ? '+' : '-'} ${currency.format(amount)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
