import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/widgets/responsive_center.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/widgets/add_edit_loan_dialog.dart';
import 'package:personal_financial_assistant/features/loans/presentation/widgets/improve_forecast_card.dart';
import 'package:personal_financial_assistant/features/loans/presentation/widgets/what_if_scenario_card.dart';

class LoanDetailScreen extends ConsumerStatefulWidget {
  final String loanId;

  const LoanDetailScreen({super.key, required this.loanId});

  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(selectedLoanIdProvider.notifier).state = widget.loanId;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditDialog(BuildContext context, Loan loan) {
    showDialog(
      context: context,
      builder: (context) => AddEditLoanDialog(loan: loan),
    );
  }

  void _confirmDelete(BuildContext context, Loan loan) {
    final parentNav = Navigator.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Loan?'),
        content: Text(
          'Are you sure you want to delete "${loan.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref
                  .read(loanControllerProvider.notifier)
                  .deleteLoan(loan.id);
              if (mounted) {
                parentNav.pop();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(loansStreamProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return loansAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Loan Detail')),
        body: Center(child: Text('Error: $err')),
      ),
      data: (loans) {
        final loan = loans.where((l) => l.id == widget.loanId).firstOrNull;
        if (loan == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loan Not Found')),
            body: const Center(child: Text('This loan no longer exists.')),
          );
        }

        final forecast = ref.watch(loanForecastByIdProvider(loan.id));
        final interestAnalysis = ref.watch(
          loanInterestAnalysisProvider(loan.id),
        );
        final accounts = ref.watch(accountsStreamProvider).value ?? [];
        final linkedAccount = accounts
            .where((a) => a.id == loan.linkedAccountId)
            .firstOrNull;

        return Scaffold(
          appBar: AppBar(
            title: Text(loan.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Loan',
                onPressed: () => _showEditDialog(context, loan),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete Loan',
                onPressed: () => _confirmDelete(context, loan),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(
                  icon: Icon(Icons.analytics_outlined),
                  text: 'Cost & Breakdown',
                ),
                Tab(
                  icon: Icon(Icons.psychology_alt_outlined),
                  text: 'What-If Simulator',
                ),
                Tab(
                  icon: Icon(Icons.table_chart_outlined),
                  text: 'Amortization',
                ),
                Tab(
                  icon: Icon(Icons.pie_chart_outline),
                  text: 'Cash Flow & Goals',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: Cost & Interest Intelligence
              _OverviewTab(
                loan: loan,
                forecast: forecast,
                analysis: interestAnalysis,
                linkedAccountName: linkedAccount?.name,
                currencyFormat: currencyFormat,
                onEdit: () => _showEditDialog(context, loan),
              ),

              // TAB 2: What-If Prepayment Simulator
              const SingleChildScrollView(
                child: ResponsiveCenter(
                  maxWidth: 900,
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [WhatIfScenarioCard(), SizedBox(height: 40)],
                  ),
                ),
              ),

              // TAB 3: Full Amortization Schedule
              _AmortizationTab(
                forecast: forecast,
                currencyFormat: currencyFormat,
              ),

              // TAB 4: Cash Flow & Goal Impact
              _CashFlowGoalTab(
                loan: loan,
                forecast: forecast,
                currencyFormat: currencyFormat,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Loan loan;
  final dynamic forecast;
  final dynamic analysis;
  final String? linkedAccountName;
  final NumberFormat currencyFormat;
  final VoidCallback onEdit;

  const _OverviewTab({
    required this.loan,
    required this.forecast,
    required this.analysis,
    this.linkedAccountName,
    required this.currencyFormat,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final principal =
        loan.outstandingPrincipal ?? loan.originalPrincipal ?? 0.0;
    final estInterest = forecast?.estimatedRemainingInterest ?? 0.0;
    final totalRepayment = principal + estInterest;

    final interestRatio = totalRepayment > 0
        ? (estInterest / totalRepayment)
        : 0.0;
    final principalRatio = 1.0 - interestRatio;

    final lenderPart = loan.lenderName != null ? ' • ${loan.lenderName}' : '';

    return SingleChildScrollView(
      child: ResponsiveCenter(
        maxWidth: 900,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loan Header Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: loan.type.color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: loan.type.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            loan.type.icon,
                            size: 28,
                            color: loan.type.color,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loan.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${loan.type.displayName} • ${loan.interestRateType.displayName}$lenderPart',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
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
                      runSpacing: 12,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        _DetailMetric(
                          label: 'Outstanding Principal',
                          value: loan.hasOutstandingPrincipal
                              ? currencyFormat.format(loan.outstandingPrincipal)
                              : 'Not set',
                        ),
                        _DetailMetric(
                          label: 'Interest Rate',
                          value: loan.hasInterestRate
                              ? '${loan.interestRate}%'
                              : 'Not set',
                        ),
                        _DetailMetric(
                          label: 'Monthly EMI',
                          value: loan.hasEmiAmount
                              ? currencyFormat.format(loan.emiAmount)
                              : (forecast?.effectiveEmi != null
                                    ? '~${currencyFormat.format(forecast.effectiveEmi)}'
                                    : 'Not set'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Interest Proportion Breakdown Card
            if (analysis != null && totalRepayment > 0) ...[
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Remaining Repayment Composition',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Illustrative breakdown of your remaining ₹${currencyFormat.format(totalRepayment)} repayment.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Two-color progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            if (principalRatio > 0)
                              Expanded(
                                flex: (principalRatio * 100).toInt(),
                                child: Container(
                                  height: 20,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            if (interestRatio > 0)
                              Expanded(
                                flex: (interestRatio * 100).toInt(),
                                child: Container(
                                  height: 20,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Principal: ${currencyFormat.format(principal)} (${(principalRatio * 100).toStringAsFixed(1)}%)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade700,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Interest: ${currencyFormat.format(estInterest)} (${(interestRatio * 100).toStringAsFixed(1)}%)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Next 12 Months Preview Card
            if (analysis != null && analysis.next12MonthsTotalPayment > 0) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
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
                            Icons.calendar_month_outlined,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Next 12 Months Payment Trajectory',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          _DetailMetric(
                            label: 'Total 12-Month Outflow',
                            value: currencyFormat.format(
                              analysis.next12MonthsTotalPayment,
                            ),
                          ),
                          _DetailMetric(
                            label: 'Principal Paid Down',
                            value: currencyFormat.format(
                              analysis.next12MonthsPrincipal,
                            ),
                            color: Colors.blue.shade700,
                          ),
                          _DetailMetric(
                            label: 'Interest Cost Incurred',
                            value: currencyFormat.format(
                              analysis.next12MonthsInterest,
                            ),
                            color: Colors.orange.shade800,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Missing information / Improve forecast banner
            if (forecast != null && forecast.missingFields.isNotEmpty) ...[
              ImproveForecastCard(
                missingFields: forecast.missingFields,
                onAddMissingInfo: onEdit,
              ),
              const SizedBox(height: 16),
            ],

            // Additional details
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan Details & Settings',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: 'Lender Name',
                      value: loan.lenderName ?? 'Not specified',
                    ),
                    _InfoRow(
                      label: 'Linked EMI Account',
                      value: linkedAccountName ?? 'None',
                    ),
                    _InfoRow(
                      label: 'Next EMI Date',
                      value: loan.nextEmiDate != null
                          ? DateFormat('MMM dd, yyyy').format(loan.nextEmiDate!)
                          : 'Not set',
                    ),
                    _InfoRow(
                      label: 'Estimated Closure',
                      value: forecast?.estimatedClosureDate != null
                          ? DateFormat('MMMM yyyy')
                                .format(forecast.estimatedClosureDate!)
                          : 'Not available',
                    ),
                    if (loan.processingFee != null)
                      _InfoRow(
                        label: 'Processing Fee',
                        value: currencyFormat.format(loan.processingFee),
                      ),
                    if (loan.notes != null && loan.notes!.isNotEmpty)
                      _InfoRow(label: 'Notes', value: loan.notes!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _AmortizationTab extends StatelessWidget {
  final dynamic forecast;
  final NumberFormat currencyFormat;

  const _AmortizationTab({
    required this.forecast,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (forecast == null || forecast.schedule.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.table_rows_outlined,
                size: 48,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'Schedule Not Available',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Add outstanding principal and interest rate to generate an amortization schedule.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final schedule = forecast.schedule;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: ResponsiveCenter(
        maxWidth: 1000,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Complete Amortization Schedule (${schedule.length} Months)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text('${schedule.length} Installments'),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text('Month')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('EMI Payment')),
                      DataColumn(label: Text('Principal')),
                      DataColumn(label: Text('Interest')),
                      DataColumn(label: Text('Remaining Balance')),
                    ],
                    rows: schedule.map<DataRow>((row) {
                      return DataRow(
                        cells: [
                          DataCell(Text('#${row.monthNumber}')),
                          DataCell(
                            Text(DateFormat('MMM yyyy').format(row.date)),
                          ),
                          DataCell(Text(currencyFormat.format(row.payment))),
                          DataCell(
                            Text(
                              currencyFormat.format(row.principalComponent),
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ),
                          DataCell(
                            Text(
                              currencyFormat.format(row.interestComponent),
                              style: const TextStyle(color: Colors.orange),
                            ),
                          ),
                          DataCell(
                            Text(
                              currencyFormat.format(row.remainingBalance),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
}

class _CashFlowGoalTab extends ConsumerWidget {
  final Loan loan;
  final dynamic forecast;
  final NumberFormat currencyFormat;

  const _CashFlowGoalTab({
    required this.loan,
    required this.forecast,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final goalsAsync = ref.watch(goalsStreamProvider);
    final goals = goalsAsync.value ?? [];
    final emi = loan.emiAmount ?? forecast?.effectiveEmi ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: ResponsiveCenter(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cash Flow Burden Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
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
                          Icons.account_balance_wallet_outlined,
                          size: 22,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Monthly Cash Flow Commitment',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This loan commits approximately ${currencyFormat.format(emi)} each month from your cash flow. Once fully paid off, this amount is completely freed up for your savings, investments, or living expenses.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Goal Competition / Trade-off
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
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
                          Icons.flag_outlined,
                          size: 22,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Interaction with Active Goals',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (goals.isEmpty)
                      Text(
                        'You currently have no active savings goals. Adding emergency fund or savings goals allows FINAURA to calculate debt vs savings trade-offs.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      Column(
                        children: goals.map((g) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Icon(
                                  g.type.icon,
                                  size: 18,
                                  color: g.type.color,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${g.name} (${currencyFormat.format(g.targetAmount)})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${((g.currentAmount / g.targetAmount) * 100).toStringAsFixed(0)}% reached',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _DetailMetric({required this.label, required this.value, this.color});

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
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
