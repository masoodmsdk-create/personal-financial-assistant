import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/core/widgets/responsive_center.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';

import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:personal_financial_assistant/features/analytics/presentation/widgets/category_breakdown_card.dart';
import 'package:personal_financial_assistant/features/analytics/presentation/widgets/income_expense_chart.dart';
import 'package:personal_financial_assistant/features/analytics/presentation/widgets/period_selector_widget.dart';
import 'package:personal_financial_assistant/features/analytics/presentation/widgets/things_to_review_card.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    final summary = ref.watch(periodSummaryProvider);
    final expenseBreakdown = ref.watch(expenseCategoryBreakdownProvider);
    final incomeBreakdown = ref.watch(incomeCategoryBreakdownProvider);
    final plannedVsActual = ref.watch(periodPlannedVsActualProvider);

    final accountsAsync = ref.watch(accountsStreamProvider);
    final calculatedBalances = ref.watch(calculatedAccountBalancesProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: ResponsiveCenter(
          maxWidth: 1000,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Analytics & Trends',
                subtitle: 'Explore your spending patterns, cash flow, and monthly trends.',
              ),

              // Period Selector
              const PeriodSelectorWidget(),
              const SizedBox(height: 16),

              // Executive Summary Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 460;
                  if (isNarrow) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryCard(
                                title: 'Income',
                                amount: currencyFormat.format(
                                  summary.totalIncome,
                                ),
                                color: const Color(0xFF2E7D32),
                                icon: Icons.arrow_downward_rounded,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _SummaryCard(
                                title: 'Expense',
                                amount: currencyFormat.format(
                                  summary.totalExpense,
                                ),
                                color: const Color(0xFFD32F2F),
                                icon: Icons.arrow_upward_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _SummaryCard(
                          title: 'Net Cash Flow',
                          amount: currencyFormat.format(summary.netCashFlow),
                          color: colorScheme.primary,
                          icon: Icons.swap_vert_rounded,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Income',
                          amount: currencyFormat.format(summary.totalIncome),
                          color: const Color(0xFF2E7D32),
                          icon: Icons.arrow_downward_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Expense',
                          amount: currencyFormat.format(summary.totalExpense),
                          color: const Color(0xFFD32F2F),
                          icon: Icons.arrow_upward_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Net Cash Flow',
                          amount: currencyFormat.format(summary.netCashFlow),
                          color: colorScheme.primary,
                          icon: Icons.swap_vert_rounded,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Planned vs Actual Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 480;
                          final titleWidget = Text(
                            'Planned vs Actual (Monthly)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          );
                          final actionWidget = FilledButton.tonalIcon(
                            onPressed: () => context.push('/budgets'),
                            icon: const Icon(Icons.savings_rounded, size: 16),
                            label: const Text('Manage Budget'),
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                titleWidget,
                                const SizedBox(height: 8),
                                actionWidget,
                              ],
                            );
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: titleWidget),
                              const SizedBox(width: 12),
                              actionWidget,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 480;
                          final isAbovePlan =
                              plannedVsActual.totalActualExpense >
                              plannedVsActual.totalPlannedAmount;

                          final plannedTile = _PlannedMetricTile(
                            label: 'Planned',
                            amount: currencyFormat.format(
                              plannedVsActual.totalPlannedAmount,
                            ),
                            icon: Icons.assignment_outlined,
                            color: colorScheme.primary,
                          );
                          final actualTile = _PlannedMetricTile(
                            label: 'Actual',
                            amount: currencyFormat.format(
                              plannedVsActual.totalActualExpense,
                            ),
                            icon: Icons.receipt_outlined,
                            color: isAbovePlan
                                ? colorScheme.error
                                : Colors.teal.shade700,
                          );
                          final diffTile = _PlannedMetricTile(
                            label: isAbovePlan ? 'Above Plan' : 'Difference',
                            amount: currencyFormat.format(
                              (plannedVsActual.totalPlannedAmount -
                                      plannedVsActual.totalActualExpense)
                                  .abs(),
                            ),
                            icon: isAbovePlan
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline_rounded,
                            color: isAbovePlan
                                ? colorScheme.error
                                : Colors.green.shade700,
                            isWarning: isAbovePlan,
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: plannedTile),
                                    const SizedBox(width: 8),
                                    Expanded(child: actualTile),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                diffTile,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: plannedTile),
                              const SizedBox(width: 12),
                              Expanded(child: actualTile),
                              const SizedBox(width: 12),
                              Expanded(child: diffTile),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Things to Review Section
              const RepaintBoundary(child: ThingsToReviewCard()),
              const SizedBox(height: 16),

              // Income vs Expense Chart Card
              const RepaintBoundary(child: IncomeExpenseChartCard()),
              const SizedBox(height: 16),

              // Category Breakdown Cards
              RepaintBoundary(
                child: CategoryBreakdownCard(
                  title: 'Expense Categories',
                  items: expenseBreakdown,
                  type: CategoryType.expense,
                ),
              ),
              const SizedBox(height: 16),

              RepaintBoundary(
                child: CategoryBreakdownCard(
                  title: 'Income Categories',
                  items: incomeBreakdown,
                  type: CategoryType.income,
                ),
              ),
              const SizedBox(height: 16),

              // Account & Credit Card Breakdown Card
              accountsAsync.when(
                data: (accounts) {
                  if (accounts.isEmpty) return const SizedBox.shrink();

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Balances & Liabilities',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: accounts.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 16),
                            itemBuilder: (context, index) {
                              final acc = accounts[index];
                              final bal =
                                  calculatedBalances[acc.id] ??
                                  acc.openingBalance;
                              final isCredit =
                                  acc.type == AccountType.creditCard;

                              return Row(
                                children: [
                                  Icon(acc.type.icon, color: acc.type.color),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          acc.name,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        Text(
                                          isCredit
                                              ? 'Credit Card Outstanding'
                                              : acc.type.displayName,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: isCredit
                                                    ? colorScheme.error
                                                    : colorScheme
                                                          .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(bal),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isCredit
                                          ? colorScheme.error
                                          : colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannedMetricTile extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;
  final bool isWarning;

  const _PlannedMetricTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isWarning ? colorScheme.error : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
