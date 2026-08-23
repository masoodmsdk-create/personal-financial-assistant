import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/core/widgets/responsive_center.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/models/financial_blueprint.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/services/blueprint_persistence_service.dart';
import 'package:personal_financial_assistant/features/blueprint/presentation/providers/blueprint_providers.dart';

import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/workspaces/presentation/providers/workspace_providers.dart';
import 'package:personal_financial_assistant/features/workspaces/presentation/widgets/edit_workspace_dialog.dart';

class FinancialSetupScreen extends ConsumerStatefulWidget {
  const FinancialSetupScreen({super.key});

  @override
  ConsumerState<FinancialSetupScreen> createState() =>
      _FinancialSetupScreenState();
}

class _FinancialSetupScreenState extends ConsumerState<FinancialSetupScreen> {
  late final TextEditingController _inputController;
  final currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static const List<String> _promptExamples = [
    'My salary is ₹1,00,000, wife earns ₹60,000, home loan EMI is ₹45,000, rent ₹20,000, groceries ₹8,000, petrol ₹5,000, I have ₹2 lakh savings and want an emergency fund of ₹5 lakh.',
    'Salary ₹75,000, rent ₹18,000, utilities ₹4,000, groceries ₹9,000, ₹1.5 lakh in savings, vacation goal ₹50,000.',
    'Freelance income ₹1.2 lakh, car loan EMI ₹12,000, dining ₹6,000, savings ₹3 lakh.',
  ];

  @override
  void initState() {
    super.initState();
    final currentInput = ref.read(blueprintControllerProvider).rawInput;
    _inputController = TextEditingController(text: currentInput);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _triggerParse() {
    final accounts = ref.read(accountsStreamProvider).value ?? [];
    final categories =
        ref.read(categoriesStreamProvider).value ??
        Category.generateDefaults(
          ref.read(currentUserProvider)?.uid ?? 'guest',
        );
    final loans = ref.read(loansStreamProvider).value ?? [];
    final goals = ref.read(goalsStreamProvider).value ?? [];
    final activeWorkspace = ref.read(activeWorkspaceProvider);

    ref
        .read(blueprintControllerProvider.notifier)
        .setInput(_inputController.text);
    ref
        .read(blueprintControllerProvider.notifier)
        .parseSituation(
          accounts: accounts,
          categories: categories,
          existingLoans: loans,
          existingGoals: goals,
          workspaceContext: activeWorkspace.purpose,
        );
  }

  Future<void> _showConfirmDialog(
    BuildContext context,
    FinancialBlueprint bp,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Financial Setup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FINAURA will create the following records in your active workspace:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (bp.incomes.isNotEmpty)
              _bulletPoint('${bp.incomes.length} Income source(s)'),
            if (bp.loans.isNotEmpty)
              _bulletPoint('${bp.loans.length} Loan obligation(s)'),
            if (bp.recurringExpenses.isNotEmpty)
              _bulletPoint(
                '${bp.recurringExpenses.length} Recurring planned expense(s)',
              ),
            if (bp.savings.isNotEmpty)
              _bulletPoint('${bp.savings.length} Savings / Account record(s)'),
            if (bp.goals.isNotEmpty)
              _bulletPoint('${bp.goals.length} Financial goal(s)'),
            if (bp.transactions.isNotEmpty)
              _bulletPoint('${bp.transactions.length} Actual transaction(s)'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'No financial records were created yet. Tapping "Confirm & Create" will save these to your workspace.',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Review Again'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm & Create'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(blueprintControllerProvider.notifier)
          .confirmAndPersist(user.uid);
      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Financial setup created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blueprintControllerProvider);
    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final bp = state.blueprint;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        child: ResponsiveCenter(
          maxWidth: 1000,
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 60,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Tell FINAURA About Your Money',
                subtitle: 'Describe your income, expenses, loans, and goals in plain language',
                action: OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Back'),
                ),
              ),
              const SizedBox(height: 16),

              // Active Workspace Context Badge
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspaces_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Workspace Context: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: activeWorkspace.name,
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (activeWorkspace.purpose.isNotEmpty)
                                TextSpan(
                                  text: ' • "${activeWorkspace.purpose}"',
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) =>
                                EditWorkspaceDialog(workspace: activeWorkspace),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        tooltip: 'Edit Workspace Context',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Natural Language Input Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _inputController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'e.g. My salary is 1 lakh, wife earns 60k, home loan EMI is 45k, rent 20k, groceries around 8k and petrol 5k. I have 2 lakh savings and want an emergency fund of 5 lakh.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Quick examples:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ..._promptExamples.map((example) {
                            return ActionChip(
                              label: Text(
                                '${example.substring(0, 32)}...',
                                style: const TextStyle(fontSize: 11),
                              ),

                              onPressed: () {
                                _inputController.text = example;
                                _triggerParse();
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              _inputController.clear();
                              ref
                                  .read(blueprintControllerProvider.notifier)
                                  .clearBlueprint();
                            },
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            label: const Text('Clear'),
                          ),
                          FilledButton.icon(
                            onPressed: state.isParsing ? null : _triggerParse,
                            icon: state.isParsing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 18,
                                  ),
                            label: const Text('Parse & Build Blueprint'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (state.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Success Confirmed Banner
              if (state.isConfirmed && state.persistenceResult != null) ...[
                const SizedBox(height: 24),
                _SuccessBanner(result: state.persistenceResult!),
              ],

              // Clarification Loop Q&A Card
              if (bp != null &&
                  bp.hasUnresolvedClarifications &&
                  !state.isConfirmed) ...[
                const SizedBox(height: 20),
                _ClarificationCard(
                  question: bp.unresolvedQuestions.first,
                  onAnswer: (optId) {
                    ref
                        .read(blueprintControllerProvider.notifier)
                        .answerClarification(
                          questionId: bp.unresolvedQuestions.first.id,
                          optionId: optId,
                        );
                  },
                  onSkip: () {
                    ref
                        .read(blueprintControllerProvider.notifier)
                        .skipClarification(bp.unresolvedQuestions.first.id);
                  },
                ),
              ],

              // Live Mutable Financial Blueprint Content
              if (bp != null &&
                  bp.totalEntitiesCount > 0 &&
                  !state.isConfirmed) ...[
                const SizedBox(height: 24),
                _BlueprintSummaryMetrics(bp: bp),
                const SizedBox(height: 20),

                // Sections Breakdown
                if (bp.incomes.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Income Sources',
                    count: bp.incomes.length,
                  ),
                  ...bp.incomes.asMap().entries.map(
                    (e) => _IncomeItemCard(
                      item: e.value,
                      onDelete: () => ref
                          .read(blueprintControllerProvider.notifier)
                          .removeIncomeItem(e.key),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (bp.loans.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Loans & Commitments',
                    count: bp.loans.length,
                  ),
                  ...bp.loans.asMap().entries.map(
                    (e) => _LoanItemCard(
                      item: e.value,
                      onDelete: () => ref
                          .read(blueprintControllerProvider.notifier)
                          .removeLoanItem(e.key),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (bp.recurringExpenses.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Recurring Living Expenses',
                    count: bp.recurringExpenses.length,
                  ),
                  ...bp.recurringExpenses.asMap().entries.map(
                    (e) => _ExpenseItemCard(
                      item: e.value,
                      onDelete: () => ref
                          .read(blueprintControllerProvider.notifier)
                          .removeExpenseItem(e.key),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (bp.savings.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Savings & Reserves',
                    count: bp.savings.length,
                  ),
                  ...bp.savings.asMap().entries.map(
                    (e) => _SavingsItemCard(
                      item: e.value,
                      onDelete: () => ref
                          .read(blueprintControllerProvider.notifier)
                          .removeSavingsItem(e.key),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (bp.goals.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Financial Goals',
                    count: bp.goals.length,
                  ),
                  ...bp.goals.asMap().entries.map(
                    (e) => _GoalItemCard(
                      item: e.value,
                      onDelete: () => ref
                          .read(blueprintControllerProvider.notifier)
                          .removeGoalItem(e.key),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (bp.transactions.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Actual Historical Transactions',
                    count: bp.transactions.length,
                  ),
                  ...bp.transactions.asMap().entries.map(
                    (e) => _TransactionItemCard(
                      item: e.value,
                      onDelete: () => ref
                          .read(blueprintControllerProvider.notifier)
                          .removeTransactionItem(e.key),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Explicit Confirmation Bar
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.primary, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ready to Create Financial Setup',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${bp.totalEntitiesCount} records ready to be saved in ${activeWorkspace.name}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: state.isPersisting
                                  ? null
                                  : () => _showConfirmDialog(context, bp),
                              icon: state.isPersisting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_rounded),
                              label: const Text('Confirm & Create Setup'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- SUB-WIDGETS ---

class _ClarificationCard extends StatelessWidget {
  final ClarificationQuestion question;
  final ValueChanged<String> onAnswer;
  final VoidCallback onSkip;

  const _ClarificationCard({
    required this.question,
    required this.onAnswer,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.amber.shade400, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline_rounded, color: Colors.amber.shade900),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'FINAURA needs a quick clarification',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
                if (question.canSkip)
                  TextButton(
                    onPressed: onSkip,
                    child: const Text('Skip for now'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              question.question,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (question.contextSnippet != null) ...[
              const SizedBox(height: 4),
              Text(
                'Source snippet: "${question.contextSnippet}"',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: question.options.map((opt) {
                return ActionChip(
                  label: Text(opt.label),
                  onPressed: () => onAnswer(opt.id),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlueprintSummaryMetrics extends StatelessWidget {
  final FinancialBlueprint bp;

  const _BlueprintSummaryMetrics({required this.bp});

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
            Text(
              'FINANCIAL PICTURE SUMMARY',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _SummaryMetricItem(
                  label: 'Monthly Income',
                  value: currency.format(bp.totalMonthlyIncome),
                  color: Colors.green.shade700,
                ),
                _SummaryMetricItem(
                  label: 'Living Expenses',
                  value: currency.format(bp.totalMonthlyExpenses),
                  color: Colors.orange.shade800,
                ),
                _SummaryMetricItem(
                  label: 'EMI Commitments',
                  value: currency.format(bp.totalMonthlyEmi),
                  color: Colors.purple.shade700,
                ),
                _SummaryMetricItem(
                  label: 'Remaining Cash Flow',
                  value: currency.format(bp.knownRemainingMonthlyCashFlow),
                  color: bp.knownRemainingMonthlyCashFlow >= 0
                      ? Colors.teal.shade700
                      : Colors.red.shade700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryMetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text('$count', style: const TextStyle(fontSize: 11)),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _IncomeItemCard extends StatelessWidget {
  final BlueprintIncomeItem item;
  final VoidCallback onDelete;

  const _IncomeItemCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(
            Icons.arrow_downward_rounded,
            color: Colors.green.shade800,
          ),
        ),
        title: Text(
          item.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Source: "${item.sourceText}"'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${currency.format(item.monthlyAmount)}/mo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.green.shade800,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanItemCard extends StatelessWidget {
  final BlueprintLoanItem item;
  final VoidCallback onDelete;

  const _LoanItemCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade100,
          child: Icon(
            Icons.account_balance_outlined,
            color: Colors.purple.shade800,
          ),
        ),
        title: Text(
          item.loanName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          item.missingFields.isNotEmpty
              ? 'EMI commitment (Principal & rate not specified)'
              : 'Configured loan',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${currency.format(item.emiAmount)}/mo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.purple.shade800,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseItemCard extends StatelessWidget {
  final BlueprintExpenseItem item;
  final VoidCallback onDelete;

  const _ExpenseItemCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: Icon(
            Icons.shopping_bag_outlined,
            color: Colors.orange.shade800,
          ),
        ),
        title: Text(
          item.categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Source: "${item.sourceText}"'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${currency.format(item.monthlyAmount)}/mo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.orange.shade800,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsItemCard extends StatelessWidget {
  final BlueprintSavingsItem item;
  final VoidCallback onDelete;

  const _SavingsItemCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.savings_outlined, color: Colors.blue.shade800),
        ),
        title: Text(
          item.accountName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Opening balance / reserve'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currency.format(item.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.blue.shade800,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalItemCard extends StatelessWidget {
  final BlueprintGoalItem item;
  final VoidCallback onDelete;

  const _GoalItemCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          child: Icon(Icons.flag_outlined, color: Colors.teal.shade800),
        ),
        title: Text(
          item.goalName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Target Goal'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currency.format(item.targetAmount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.teal.shade800,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionItemCard extends StatelessWidget {
  final BlueprintTransactionItem item;
  final VoidCallback onDelete;

  const _TransactionItemCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child: Icon(Icons.receipt_long_outlined, color: Colors.red.shade800),
        ),
        title: Text(
          item.categoryName ?? 'Expense',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(item.note),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currency.format(item.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.red.shade800,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final BlueprintPersistenceResult result;

  const _SuccessBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 48,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            Text(
              'Financial Setup Created Successfully!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Created ${result.totalRecordsCreated} record(s): ${result.expensesCreated} recurring expenses, ${result.loansCreated} loans, ${result.savingsCreated} accounts, ${result.goalsCreated} goals, ${result.transactionsCreated} transactions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.green.shade800),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('/dashboard'),
                  icon: const Icon(Icons.dashboard_rounded, size: 18),
                  label: const Text('Go to Dashboard'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/monthly-review'),
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: const Text('View Monthly Review'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
