import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/core/widgets/responsive_center.dart';
import 'package:personal_financial_assistant/features/loans/domain/models/debt_intelligence.dart';
import 'package:personal_financial_assistant/features/loans/domain/services/loan_forecast_service.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/screens/loan_detail_screen.dart';
import 'package:personal_financial_assistant/features/loans/presentation/widgets/add_edit_loan_dialog.dart';

class LoansScreen extends ConsumerWidget {
  const LoansScreen({super.key});

  void _showAddLoanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddEditLoanDialog(),
    );
  }

  void _showEditLoanDialog(BuildContext context, Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AddEditLoanDialog(loan: loan),
    );
  }

  void _confirmDeleteLoan(BuildContext context, WidgetRef ref, Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Loan?'),
        content: Text(
          'Are you sure you want to delete "${loan.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await ref
                  .read(loanControllerProvider.notifier)
                  .deleteLoan(loan.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String loanId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => LoanDetailScreen(loanId: loanId)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    final loansAsync = ref.watch(loansStreamProvider);
    final portfolio = ref.watch(debtPortfolioSummaryProvider);
    final prioritization = ref.watch(debtPrioritizationProvider);
    final insights = ref.watch(loanInsightsProvider);
    final activeStrategy = ref.watch(selectedDebtStrategyProvider);

    return Scaffold(
      body: loansAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading loans: $err')),
        data: (loans) {
          final activeLoans = loans.where((l) => l.active).toList();

          if (activeLoans.isEmpty) {
            return SingleChildScrollView(
              child: ResponsiveCenter(
                maxWidth: 1000,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    PageHeader(
                      title: 'Loans & Debt Intelligence',
                      subtitle: 'Track total debt burden, interest costs, prioritization strategies, and prepayment forecasts.',
                      action: FilledButton.icon(
                        onPressed: () => _showAddLoanDialog(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Loan'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    EmptyStateWidget(
                      icon: Icons.account_balance_outlined,
                      title: 'No Loans Added Yet',
                      message: 'Add your home loan, personal loan, car loan, or credit card debt to forecast repayment timelines, optimize debt payoff order, and test what-if scenarios.',
                      actionLabel: 'Add Your First Loan',
                      onAction: () => _showAddLoanDialog(context),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: ResponsiveCenter(
              maxWidth: 1000,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHeader(
                    title: 'Loans & Debt Intelligence',
                    subtitle: 'Track total debt burden, interest costs, prioritization strategies, and prepayment forecasts.',
                    action: FilledButton.icon(
                      onPressed: () => _showAddLoanDialog(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Loan'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Overall Portfolio Debt Metrics Grid Card
                  Card(
                    color: colorScheme.errorContainer.withValues(alpha: 0.25),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.error.withValues(
                                    alpha: 0.15,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.account_balance_outlined,
                                  color: colorScheme.error,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Portfolio Debt Burden',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onErrorContainer,
                                          ),
                                    ),
                                    Text(
                                      '${portfolio.activeLoansCount} Active Debt Obligation(s)${portfolio.weightedAverageInterestRate != null ? ' • Weighted Rate: ${portfolio.weightedAverageInterestRate}%' : ''}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onErrorContainer
                                                .withValues(alpha: 0.8),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Wrap(
                            spacing: 24,
                            runSpacing: 16,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              _SummaryTile(
                                label: 'Total Outstanding Debt',
                                value: currencyFormat.format(
                                  portfolio.totalOutstandingDebt,
                                ),
                                color: colorScheme.onErrorContainer,
                              ),
                              _SummaryTile(
                                label: 'Monthly Commitments',
                                value: currencyFormat.format(
                                  portfolio.totalMonthlyEmi,
                                ),
                                color: colorScheme.onErrorContainer,
                              ),
                              _SummaryTile(
                                label: 'Est. Remaining Interest',
                                value: currencyFormat.format(
                                  portfolio.estimatedTotalRemainingInterest,
                                ),
                                color: Colors.orange.shade800,
                              ),
                              if (portfolio.debtToIncomeRatio != null)
                                _SummaryTile(
                                  label: 'EMI / Income Ratio',
                                  value: '${portfolio.debtToIncomeRatio}%',
                                  color: portfolio.debtToIncomeRatio! > 40
                                      ? Colors.red
                                      : Colors.green.shade800,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // High-Value Insights Section
                  if (insights.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Debt Intelligence & Nuances',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...insights.take(3).map((insight) {
                      Color bg;
                      Color text;
                      IconData ic;
                      if (insight.severity == LoanInsightSeverity.warning) {
                        bg = colorScheme.errorContainer.withValues(alpha: 0.4);
                        text = colorScheme.onErrorContainer;
                        ic = Icons.warning_amber_rounded;
                      } else if (insight.severity ==
                          LoanInsightSeverity.opportunity) {
                        bg = colorScheme.primaryContainer.withValues(
                          alpha: 0.4,
                        );
                        text = colorScheme.onPrimaryContainer;
                        ic = Icons.lightbulb_outline_rounded;
                      } else {
                        bg = colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        );
                        text = colorScheme.onSurfaceVariant;
                        ic = Icons.info_outline;
                      }

                      return Card(
                        elevation: 0,
                        color: bg,
                        margin: const EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(ic, size: 20, color: text),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      insight.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: text,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      insight.message,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: text.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (insight.loanId != null)
                                TextButton(
                                  onPressed: () => _navigateToDetail(
                                    context,
                                    insight.loanId!,
                                  ),
                                  child: const Text(
                                    'View Loan',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  // Debt Prioritization Strategy Section
                  if (activeLoans.length > 1) ...[
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.sort_rounded,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Debt Prioritization Strategy',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Compare how different payoff strategies optimize your debt timeline.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Strategy Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: DebtStrategyType.values.map((strat) {
                                  final isSelected = activeStrategy == strat;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      avatar: Icon(strat.icon, size: 16),
                                      label: Text(strat.shortName),
                                      selected: isSelected,
                                      onSelected: (_) {
                                        ref
                                                .read(
                                                  selectedDebtStrategyProvider
                                                      .notifier,
                                                )
                                                .state =
                                            strat;
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Strategy Description Banner
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prioritization.strategyName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    prioritization.strategyDescription,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Trade-off: ${prioritization.tradeOffExplanation}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Prioritized Loan Order List
                            ...prioritization.prioritizedLoans.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () =>
                                      _navigateToDetail(context, item.loan.id),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6.0,
                                      horizontal: 4.0,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor:
                                              colorScheme.primaryContainer,
                                          child: Text(
                                            '#${item.rank}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Icon(
                                          item.loan.type.icon,
                                          size: 16,
                                          color: item.loan.type.color,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.loan.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                item.rationale,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                      fontSize: 11,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          currencyFormat.format(
                                            item.monthlyEmiFreed,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Loan Cards List Header
                  Text(
                    'Your Loans (${activeLoans.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Loan Cards Grid / List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeLoans.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final loan = activeLoans[index];
                      final forecast = LoanForecastService.calculateForecast(
                        loan,
                      );

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: loan.type.color.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _navigateToDetail(context, loan.id),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: loan.type.color.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        loan.type.icon,
                                        color: loan.type.color,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            loan.name,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Text(
                                            '${loan.type.displayName} • ${loan.interestRateType.displayName}${loan.lenderName != null ? ' • ${loan.lenderName}' : ''}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (val) {
                                        if (val == 'detail') {
                                          _navigateToDetail(context, loan.id);
                                        } else if (val == 'edit') {
                                          _showEditLoanDialog(context, loan);
                                        } else if (val == 'delete') {
                                          _confirmDeleteLoan(
                                            context,
                                            ref,
                                            loan,
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'detail',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.analytics_outlined,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text('View Full Intelligence'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit_outlined,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Edit Details'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Delete Loan',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),

                                // Metric columns
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.spaceBetween,
                                  children: [
                                    _SummaryTile(
                                      label: 'Outstanding Principal',
                                      value: loan.hasOutstandingPrincipal
                                          ? currencyFormat.format(
                                              loan.outstandingPrincipal,
                                            )
                                          : 'Not set',
                                    ),
                                    _SummaryTile(
                                      label: 'Interest Rate',
                                      value: loan.hasInterestRate
                                          ? '${loan.interestRate}%'
                                          : 'Not set',
                                    ),
                                    _SummaryTile(
                                      label: 'Monthly EMI',
                                      value: loan.hasEmiAmount
                                          ? currencyFormat.format(
                                              loan.emiAmount,
                                            )
                                          : (forecast.effectiveEmi != null
                                                ? '~${currencyFormat.format(forecast.effectiveEmi)}'
                                                : 'Not set'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    _SummaryTile(
                                      label: 'Est. Remaining Interest',
                                      value: forecast.hasInterest
                                          ? currencyFormat.format(
                                              forecast
                                                  .estimatedRemainingInterest,
                                            )
                                          : 'N/A',
                                      color: Colors.orange.shade800,
                                    ),
                                    _SummaryTile(
                                      label: 'Est. Payoff Date',
                                      value:
                                          forecast.estimatedClosureDate != null
                                          ? DateFormat('MMM yyyy').format(
                                              forecast.estimatedClosureDate!,
                                            )
                                          : 'N/A',
                                    ),
                                    FilledButton.tonal(
                                      onPressed: () =>
                                          _navigateToDetail(context, loan.id),
                                      child: const Text('View Forecast'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryTile({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
