import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/widgets/add_edit_loan_dialog.dart';
import 'package:personal_financial_assistant/features/loans/presentation/widgets/improve_forecast_card.dart';
import 'package:personal_financial_assistant/features/loans/presentation/widgets/what_if_scenario_card.dart';


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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    final loansAsync = ref.watch(loansStreamProvider);
    final selectedLoan = ref.watch(selectedLoanProvider);
    final forecast = ref.watch(loanForecastProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans & Forecasts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Loan',
            onPressed: () => _showAddLoanDialog(context),
          ),
        ],
      ),
      body: loansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading loans: $err')),
        data: (loans) {
          final activeLoans = loans.where((l) => l.active).toList();

          if (activeLoans.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.account_balance_outlined,
              title: 'No Loans Added Yet',
              message: 'Add your home loan, car loan, or credit card debt to forecast repayment timelines and test what-if scenarios.',
              actionLabel: 'Add Your First Loan',
              onAction: () => _showAddLoanDialog(context),
            );
          }

          final totalDebt = activeLoans.fold<double>(
            0.0,
            (sum, l) => sum + (l.outstandingPrincipal ?? 0.0),
          );

          final totalEmi = activeLoans.fold<double>(
            0.0,
            (sum, l) => sum + (l.emiAmount ?? 0.0),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Portfolio Debt Banner Card
                Card(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.account_balance_outlined,
                            color: colorScheme.error,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Outstanding Debt',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormat.format(totalDebt),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Monthly Commitments',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                            Text(
                              currencyFormat.format(totalEmi),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Loan Selector Chips / Dropdown
                Text(
                  'Select Loan to Forecast',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: activeLoans.map((loan) {
                      final isSelected = selectedLoan?.id == loan.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          avatar: Icon(
                            loan.type.icon,
                            size: 18,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : loan.type.color,
                          ),
                          label: Text(loan.name),
                          selected: isSelected,
                          onSelected: (_) {
                            ref.read(selectedLoanIdProvider.notifier).state =
                                loan.id;
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                if (selectedLoan != null) ...[
                  // Selected Loan Overview Header Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
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
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: selectedLoan.type.color.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  selectedLoan.type.icon,
                                  color: selectedLoan.type.color,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedLoan.name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      '${selectedLoan.type.displayName} • ${selectedLoan.interestRateType.displayName}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _showEditLoanDialog(context, selectedLoan);
                                  } else if (val == 'delete') {
                                    _confirmDeleteLoan(
                                      context,
                                      ref,
                                      selectedLoan,
                                    );
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
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
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Loan Metrics Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _MetricTile(
                                label: 'Outstanding Balance',
                                value: selectedLoan.hasOutstandingPrincipal
                                    ? currencyFormat.format(
                                        selectedLoan.outstandingPrincipal,
                                      )
                                    : 'Not specified',
                              ),
                              _MetricTile(
                                label: 'Interest Rate',
                                value: selectedLoan.hasInterestRate
                                    ? '${selectedLoan.interestRate}%'
                                    : 'Not specified',
                              ),
                              _MetricTile(
                                label: 'Current EMI',
                                value: selectedLoan.hasEmiAmount
                                    ? currencyFormat.format(
                                        selectedLoan.emiAmount,
                                      )
                                    : 'Not specified',
                              ),
                            ],
                          ),
                          if (forecast != null && forecast.hasTenure) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _MetricTile(
                                  label: 'Est. Remaining Tenure',
                                  value:
                                      '${forecast.estimatedRemainingTenureMonths} months',
                                ),
                                _MetricTile(
                                  label: 'Est. Payoff Date',
                                  value: forecast.estimatedClosureDate != null
                                      ? DateFormat(
                                          'MMM yyyy',
                                        ).format(forecast.estimatedClosureDate!)
                                      : 'N/A',
                                ),
                                _MetricTile(
                                  label: 'Est. Total Interest',
                                  value: forecast.hasInterest
                                      ? currencyFormat.format(
                                          forecast.estimatedRemainingInterest,
                                        )
                                      : 'N/A',
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            forecast?.note ?? 'Forecast based on the information currently provided.',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Progressive Info Card ("Improve this forecast")
                  if (forecast != null &&
                      forecast.missingFields.isNotEmpty) ...[
                    ImproveForecastCard(
                      missingFields: forecast.missingFields,
                      onAddMissingInfo: () =>
                          _showEditLoanDialog(context, selectedLoan),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // What-If Scenario Simulator
                  const WhatIfScenarioCard(),
                  const SizedBox(height: 20),

                  // Amortization Schedule Preview
                  if (forecast != null && forecast.schedule.isNotEmpty) ...[
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          'Estimated Amortization Preview',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Showing first ${forecast.schedule.take(12).length} months preview',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 18,
                              columns: const [
                                DataColumn(label: Text('Month')),
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Payment')),
                                DataColumn(label: Text('Principal')),
                                DataColumn(label: Text('Interest')),
                                DataColumn(label: Text('Balance')),
                              ],
                              rows: forecast.schedule.take(12).map((row) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text('#${row.monthNumber}')),
                                    DataCell(
                                      Text(
                                        DateFormat('MMM yyyy').format(row.date),
                                      ),
                                    ),
                                    DataCell(
                                      Text(currencyFormat.format(row.payment)),
                                    ),
                                    DataCell(
                                      Text(
                                        currencyFormat.format(
                                          row.principalComponent,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        currencyFormat.format(
                                          row.interestComponent,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        currencyFormat.format(
                                          row.remainingBalance,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

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
          ),
        ),
      ],
    );
  }
}
