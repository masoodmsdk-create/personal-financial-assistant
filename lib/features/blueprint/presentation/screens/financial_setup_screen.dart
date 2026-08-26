import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/core/widgets/responsive_center.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/widgets/add_edit_account_dialog.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/models/financial_blueprint.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/services/blueprint_persistence_service.dart';
import 'package:personal_financial_assistant/features/blueprint/presentation/providers/blueprint_providers.dart';
import 'package:personal_financial_assistant/features/blueprint/presentation/widgets/edit_blueprint_item_dialogs.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/goals/presentation/widgets/add_edit_goal_dialog.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/widgets/add_edit_loan_dialog.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/widgets/add_edit_planned_expense_dialog.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/widgets/add_edit_recurring_transaction_dialog.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';
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

  Future<bool> _confirmDelete(String itemName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Blueprint Item'),
        content: Text('Are you sure you want to remove "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  // --- EDIT DRAFT ITEM HANDLERS ---
  Future<void> _editIncomeItem(int index, BlueprintIncomeItem item) async {
    final result = await showDialog(
      context: context,
      builder: (ctx) => EditBlueprintIncomeDialog(item: item),
    );
    if (result != null && mounted) {
      if (result is BlueprintIncomeItem) {
        ref
            .read(blueprintControllerProvider.notifier)
            .updateIncomeItem(index, result);
      } else if (result is BlueprintExpenseItem) {
        ref
            .read(blueprintControllerProvider.notifier)
            .convertIncomeToExpense(index, result);
      }
    }
  }

  Future<void> _editExpenseItem(int index, BlueprintExpenseItem item) async {
    final result = await showDialog(
      context: context,
      builder: (ctx) => EditBlueprintExpenseDialog(item: item),
    );
    if (result != null && mounted) {
      if (result is BlueprintExpenseItem) {
        ref
            .read(blueprintControllerProvider.notifier)
            .updateExpenseItem(index, result);
      } else if (result is BlueprintIncomeItem) {
        ref
            .read(blueprintControllerProvider.notifier)
            .convertExpenseToIncome(index, result);
      }
    }
  }

  Future<void> _editLoanItem(int index, BlueprintLoanItem item) async {
    final result = await showDialog<BlueprintLoanItem>(
      context: context,
      builder: (ctx) => EditBlueprintLoanDialog(item: item),
    );
    if (result != null && mounted) {
      ref
          .read(blueprintControllerProvider.notifier)
          .updateLoanItem(index, result);
    }
  }

  Future<void> _editSavingsItem(int index, BlueprintSavingsItem item) async {
    final result = await showDialog<BlueprintSavingsItem>(
      context: context,
      builder: (ctx) => EditBlueprintSavingsDialog(item: item),
    );
    if (result != null && mounted) {
      ref
          .read(blueprintControllerProvider.notifier)
          .updateSavingsItem(index, result);
    }
  }

  Future<void> _editGoalItem(int index, BlueprintGoalItem item) async {
    final result = await showDialog<BlueprintGoalItem>(
      context: context,
      builder: (ctx) => EditBlueprintGoalDialog(item: item),
    );
    if (result != null && mounted) {
      ref
          .read(blueprintControllerProvider.notifier)
          .updateGoalItem(index, result);
    }
  }

  Future<void> _saveBlueprint(FinancialBlueprint bp) async {
    final user = ref.read(currentUserProvider);
    final userId = user?.uid ?? 'guest';

    final success = await ref
        .read(blueprintControllerProvider.notifier)
        .confirmAndPersist(userId);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Financial setup created successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = ref.read(blueprintControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Failed to create financial records'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blueprintControllerProvider);
    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final bp = state.blueprint;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final recurringRules =
        ref.watch(recurringTransactionsStreamProvider).value ?? [];
    final plannedExpenses =
        ref.watch(plannedExpensesStreamProvider).value ?? [];
    final accounts = ref.watch(accountsStreamProvider).value ?? [];
    final loans = ref.watch(loansStreamProvider).value ?? [];
    final goals = ref.watch(goalsStreamProvider).value ?? [];

    final hasActiveBlueprint =
        recurringRules.isNotEmpty ||
        plannedExpenses.isNotEmpty ||
        accounts.isNotEmpty ||
        loans.isNotEmpty ||
        goals.isNotEmpty;

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
                title: 'Your Money Blueprint',
                subtitle: 'Describe, view, and manage your income, expenses, loans, accounts, and goals',
                action:
                    (bp != null &&
                        bp.totalEntitiesCount > 0 &&
                        !state.isConfirmed)
                    ? FilledButton.icon(
                        onPressed: state.isPersisting
                            ? null
                            : () => _saveBlueprint(bp),
                        icon: state.isPersisting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          state.isPersisting
                              ? 'Saving Blueprint...'
                              : 'Save Blueprint',
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
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
                      Text(
                        'Describe or Update Your Financial Situation',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
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

              // Live Mutable Financial Blueprint Content (DRAFT REVIEW)
              if (bp != null &&
                  bp.totalEntitiesCount > 0 &&
                  !state.isConfirmed) ...[
                const SizedBox(height: 24),
                _BlueprintSummaryMetrics(bp: bp),
                const SizedBox(height: 16),
                Text(
                  'Detected Financial Items',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Sections Breakdown with EDIT and DELETE buttons
                if (bp.incomes.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Income Sources',
                    count: bp.incomes.length,
                  ),
                  ...bp.incomes.asMap().entries.map(
                    (e) => _IncomeItemCard(
                      item: e.value,
                      onEdit: () => _editIncomeItem(e.key, e.value),
                      onDelete: () async {
                        if (await _confirmDelete(e.value.label)) {
                          ref
                              .read(blueprintControllerProvider.notifier)
                              .removeIncomeItem(e.key);
                        }
                      },
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
                      onEdit: () => _editLoanItem(e.key, e.value),
                      onDelete: () async {
                        if (await _confirmDelete(e.value.loanName)) {
                          ref
                              .read(blueprintControllerProvider.notifier)
                              .removeLoanItem(e.key);
                        }
                      },
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
                      onEdit: () => _editExpenseItem(e.key, e.value),
                      onDelete: () async {
                        if (await _confirmDelete(e.value.categoryName)) {
                          ref
                              .read(blueprintControllerProvider.notifier)
                              .removeExpenseItem(e.key);
                        }
                      },
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
                      onEdit: () => _editSavingsItem(e.key, e.value),
                      onDelete: () async {
                        if (await _confirmDelete(e.value.accountName)) {
                          ref
                              .read(blueprintControllerProvider.notifier)
                              .removeSavingsItem(e.key);
                        }
                      },
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
                      onEdit: () => _editGoalItem(e.key, e.value),
                      onDelete: () async {
                        if (await _confirmDelete(e.value.goalName)) {
                          ref
                              .read(blueprintControllerProvider.notifier)
                              .removeGoalItem(e.key);
                        }
                      },
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
                      onDelete: () async {
                        if (await _confirmDelete(e.value.note)) {
                          ref
                              .read(blueprintControllerProvider.notifier)
                              .removeTransactionItem(e.key);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              // ACTIVE BLUEPRINT MANAGEMENT (When existing entities exist)
              if (bp == null && hasActiveBlueprint) ...[
                const SizedBox(height: 32),
                _buildActiveBlueprintSection(
                  context: context,
                  recurringRules: recurringRules,
                  plannedExpenses: plannedExpenses,
                  accounts: accounts,
                  loans: loans,
                  goals: goals,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveBlueprintSection({
    required BuildContext context,
    required List<RecurringTransactionRule> recurringRules,
    required List<PlannedExpense> plannedExpenses,
    required List<Account> accounts,
    required List<Loan> loans,
    required List<Goal> goals,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final incomeRules = recurringRules
        .where((r) => r.type == TransactionType.income)
        .toList();
    final expenseRules = recurringRules
        .where((r) => r.type == TransactionType.expense)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_tree_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Your Active Financial Blueprint',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'View, edit, or manage existing income sources, commitments, loans, accounts, and goals.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // 1. Income Rules
        if (incomeRules.isNotEmpty) ...[
          _SectionHeader(
            title: 'Active Income Streams',
            count: incomeRules.length,
          ),
          ...incomeRules.map((rule) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    color: Colors.green.shade800,
                  ),
                ),
                title: Text(
                  rule.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${rule.frequencyDescription} • ${rule.active ? "Active" : "Paused"}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${currencyFormat.format(rule.amount)}/mo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.green.shade800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Income Rule',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              AddEditRecurringTransactionDialog(rule: rule),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Delete Income Rule',
                      onPressed: () async {
                        if (await _confirmDelete(rule.name)) {
                          await ref
                              .read(
                                recurringTransactionControllerProvider.notifier,
                              )
                              .deleteRule(rule.id);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // 2. Planned / Recurring Expenses
        if (plannedExpenses.isNotEmpty || expenseRules.isNotEmpty) ...[
          _SectionHeader(
            title: 'Active Living & Planned Expenses',
            count: plannedExpenses.length + expenseRules.length,
          ),
          ...plannedExpenses.map((plan) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.orange.shade800,
                  ),
                ),
                title: Text(
                  plan.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Planned Expense • ${plan.active ? "Active" : "Paused"}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${currencyFormat.format(plan.defaultAmount)}/mo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Planned Expense',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              AddEditPlannedExpenseDialog(plan: plan),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Delete Planned Expense',
                      onPressed: () async {
                        if (await _confirmDelete(plan.name)) {
                          await ref
                              .read(plannedExpenseControllerProvider.notifier)
                              .archivePlannedExpense(plan.id);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          ...expenseRules.map((rule) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: Icon(
                    Icons.repeat_rounded,
                    color: Colors.orange.shade800,
                  ),
                ),
                title: Text(
                  rule.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Recurring Rule • ${rule.frequencyDescription}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${currencyFormat.format(rule.amount)}/mo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Recurring Expense',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              AddEditRecurringTransactionDialog(rule: rule),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Delete Recurring Expense',
                      onPressed: () async {
                        if (await _confirmDelete(rule.name)) {
                          await ref
                              .read(
                                recurringTransactionControllerProvider.notifier,
                              )
                              .deleteRule(rule.id);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // 3. Loans
        if (loans.isNotEmpty) ...[
          _SectionHeader(
            title: 'Active Loans & Debt Commitments',
            count: loans.length,
          ),
          ...loans.map((loan) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.shade100,
                  child: Icon(
                    Icons.account_balance_outlined,
                    color: Colors.purple.shade800,
                  ),
                ),
                title: Text(
                  loan.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Principal: ${currencyFormat.format(loan.outstandingPrincipal)} • Rate: ${loan.interestRate}%',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${currencyFormat.format(loan.emiAmount)}/mo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.purple.shade800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Loan',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddEditLoanDialog(loan: loan),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Delete Loan',
                      onPressed: () async {
                        if (await _confirmDelete(loan.name)) {
                          await ref
                              .read(loanControllerProvider.notifier)
                              .deleteLoan(loan.id);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // 4. Accounts & Reserves
        if (accounts.isNotEmpty) ...[
          _SectionHeader(
            title: 'Accounts & Savings Reserves',
            count: accounts.length,
          ),
          ...accounts.map((acc) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(
                    Icons.savings_outlined,
                    color: Colors.blue.shade800,
                  ),
                ),
                title: Text(
                  acc.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(acc.type.displayName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currencyFormat.format(acc.effectiveBalance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Account',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddEditAccountDialog(account: acc),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Delete Account',
                      onPressed: () async {
                        if (await _confirmDelete(acc.name)) {
                          await ref
                              .read(accountControllerProvider.notifier)
                              .deleteAccount(acc.id);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // 5. Goals
        if (goals.isNotEmpty) ...[
          _SectionHeader(title: 'Financial Goals', count: goals.length),
          ...goals.map((goal) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(Icons.flag_outlined, color: Colors.teal.shade800),
                ),
                title: Text(
                  goal.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Target: ${currencyFormat.format(goal.targetAmount)} • Saved: ${currencyFormat.format(goal.currentAmount)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Goal',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddEditGoalDialog(goal: goal),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Delete Goal',
                      onPressed: () async {
                        if (await _confirmDelete(goal.name)) {
                          await ref
                              .read(goalControllerProvider.notifier)
                              .deleteGoal(goal.id);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
      ],
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
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Extracted Blueprint Overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _SummaryMetricItem(
                  label: 'Total Monthly Income',
                  value: currency.format(bp.totalMonthlyIncome),
                  color: Colors.green.shade700,
                ),
                _SummaryMetricItem(
                  label: 'Committed Living Expenses',
                  value: currency.format(bp.totalMonthlyExpenses),
                  color: Colors.orange.shade800,
                ),
                _SummaryMetricItem(
                  label: 'Monthly Loan EMIs',
                  value: currency.format(bp.totalMonthlyEmi),
                  color: Colors.purple.shade700,
                ),
                _SummaryMetricItem(
                  label: 'Net Monthly Cash Flow',
                  value: currency.format(bp.knownRemainingMonthlyCashFlow),
                  color: bp.knownRemainingMonthlyCashFlow >= 0
                      ? Colors.teal.shade700
                      : Colors.red.shade700,
                ),
                _SummaryMetricItem(
                  label: 'Savings & Reserves',
                  value: currency.format(bp.totalSavings),
                  color: Colors.blue.shade700,
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
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _IncomeItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

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
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Edit Item',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: 'Delete Item',
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LoanItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

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
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Edit Item',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: 'Delete Item',
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

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
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Edit Item',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: 'Delete Item',
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SavingsItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

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
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Edit Item',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: 'Delete Item',
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

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
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Edit Item',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: 'Delete Item',
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
              tooltip: 'Delete Item',
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
              'Created ${result.totalRecordsCreated} record(s): ${result.recurringIncomesCreated} income rule(s), ${result.expensesCreated} recurring expenses, ${result.loansCreated} loans, ${result.savingsCreated} accounts, ${result.goalsCreated} goals, ${result.transactionsCreated} transactions.',
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
