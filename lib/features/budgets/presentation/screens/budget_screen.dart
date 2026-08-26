import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/features/budgets/domain/models/budget.dart';
import 'package:personal_financial_assistant/features/budgets/domain/services/budget_calculation_service.dart';
import 'package:personal_financial_assistant/features/budgets/presentation/providers/budget_providers.dart';
import 'package:personal_financial_assistant/features/budgets/presentation/widgets/add_edit_budget_dialog.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';

enum BudgetFilterStatus { all, onTrack, warning, overBudget }

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  BudgetFilterStatus _selectedFilter = BudgetFilterStatus.all;

  void _previousMonth() {
    final current = ref.read(selectedBudgetMonthProvider);
    ref.read(selectedBudgetMonthProvider.notifier).state = DateTime(
      current.year,
      current.month - 1,
    );
  }

  void _nextMonth() {
    final current = ref.read(selectedBudgetMonthProvider);
    ref.read(selectedBudgetMonthProvider.notifier).state = DateTime(
      current.year,
      current.month + 1,
    );
  }

  void _resetToCurrentMonth() {
    final now = DateTime.now();
    ref.read(selectedBudgetMonthProvider.notifier).state = DateTime(
      now.year,
      now.month,
    );
  }

  void _openAddBudgetDialog([Budget? budget]) {
    final selectedMonth = ref.read(selectedBudgetMonthProvider);
    showDialog(
      context: context,
      builder: (context) => AddEditBudgetDialog(
        budget: budget,
        initialYear: selectedMonth.year,
        initialMonth: selectedMonth.month,
      ),
    );
  }

  void _confirmDeleteBudget(Budget budget) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: const Text(
          'Are you sure you want to delete this category budget? Past transactions will remain intact.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final success = await ref
                  .read(budgetControllerProvider.notifier)
                  .deleteBudget(budget.id);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Budget deleted successfully')),
                );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedMonth = ref.watch(selectedBudgetMonthProvider);
    final budgetSummary = ref.watch(monthlyBudgetSummaryProvider);
    final cashFlowPlan = ref.watch(monthlyCashFlowPlanProvider);
    final monthFormat = DateFormat('MMMM yyyy');

    final isCurrentMonth =
        selectedMonth.year == DateTime.now().year &&
        selectedMonth.month == DateTime.now().month;

    // Filter category breakdowns
    final filteredCategories = budgetSummary.categoryBreakdowns.where((c) {
      switch (_selectedFilter) {
        case BudgetFilterStatus.all:
          return true;
        case BudgetFilterStatus.onTrack:
          return !c.isOverBudget && c.utilizationPercentage < 85.0;
        case BudgetFilterStatus.warning:
          return !c.isOverBudget && c.utilizationPercentage >= 85.0;
        case BudgetFilterStatus.overBudget:
          return c.isOverBudget;
      }
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Budget & Cash-Flow Planning',
                subtitle: 'Understand how much you can safely spend, what is committed, and what remains available.',
                action: budgetSummary.categoryBreakdowns.isNotEmpty
                    ? FilledButton.icon(
                        onPressed: () => _openAddBudgetDialog(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Budget'),
                      )
                    : null,
              ),

              // Month Selector Bar
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        tooltip: 'Previous Month',
                        onPressed: _previousMonth,
                      ),
                      Expanded(
                        child: Text(
                          monthFormat.format(selectedMonth),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        tooltip: 'Next Month',
                        onPressed: _nextMonth,
                      ),
                      if (!isCurrentMonth) ...[
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.today_rounded, size: 14),
                          label: const Text('This Month'),
                          onPressed: _resetToCurrentMonth,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Available-to-Spend & Cash Flow Banner
              _buildAvailableToSpendCard(context, cashFlowPlan),
              const SizedBox(height: 16),

              // Budget vs Actual KPI Metric Cards
              _buildKpiMetrics(context, budgetSummary),
              const SizedBox(height: 20),

              // Filter Chips & Section Header
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Category Budgets (${budgetSummary.categoryBreakdowns.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedFilter == BudgetFilterStatus.all,
                    onSelected: (_) => setState(
                      () => _selectedFilter = BudgetFilterStatus.all,
                    ),
                  ),
                  FilterChip(
                    label: const Text('On Track'),
                    selected: _selectedFilter == BudgetFilterStatus.onTrack,
                    onSelected: (_) => setState(
                      () => _selectedFilter = BudgetFilterStatus.onTrack,
                    ),
                  ),
                  FilterChip(
                    label: const Text('Warning (85%+)'),
                    selected: _selectedFilter == BudgetFilterStatus.warning,
                    onSelected: (_) => setState(
                      () => _selectedFilter = BudgetFilterStatus.warning,
                    ),
                  ),
                  FilterChip(
                    label: Text(
                      'Over Budget (${budgetSummary.overBudgetCategoriesCount})',
                    ),
                    selected: _selectedFilter == BudgetFilterStatus.overBudget,
                    selectedColor: colorScheme.errorContainer,
                    onSelected: (_) => setState(
                      () => _selectedFilter = BudgetFilterStatus.overBudget,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Category Budget Cards List or Empty State
              if (filteredCategories.isEmpty)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: EmptyStateWidget(
                      icon: Icons.savings_outlined,
                      title: budgetSummary.categoryBreakdowns.isEmpty
                          ? 'No Category Budgets Set'
                          : 'No categories match filter',
                      message: budgetSummary.categoryBreakdowns.isEmpty
                          ? 'Set monthly budgets for groceries, dining, shopping, and living expenses to control spending.'
                          : 'Try changing the filter chips above.',
                      actionLabel: budgetSummary.categoryBreakdowns.isEmpty
                          ? 'Add Budget'
                          : null,
                      onAction: budgetSummary.categoryBreakdowns.isEmpty
                          ? () => _openAddBudgetDialog()
                          : null,
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredCategories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filteredCategories[index];
                    return _buildCategoryBudgetCard(context, item);
                  },
                ),

              const SizedBox(height: 80), // Fab clearance
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableToSpendCard(
    BuildContext context,
    MonthlyCashFlowPlan plan,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isNegative = plan.availableToSpend < 0;

    return Card(
      elevation: 0,
      color: isNegative
          ? colorScheme.errorContainer.withValues(alpha: 0.3)
          : colorScheme.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isNegative
              ? colorScheme.error.withValues(alpha: 0.5)
              : colorScheme.primary.withValues(alpha: 0.3),
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
                  Icons.account_balance_wallet_rounded,
                  color: isNegative ? colorScheme.error : colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AVAILABLE TO SPEND',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: isNegative
                          ? colorScheme.error
                          : colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  '₹${plan.availableToSpend.toStringAsFixed(0)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isNegative ? colorScheme.error : colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Cash-Flow Deterministic Breakdown
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildFlowPill(
                  context,
                  label: 'Expected Income',
                  amount: plan.expectedIncome,
                  color: Colors.green.shade700,
                  isPositive: true,
                ),
                _buildFlowPill(
                  context,
                  label: 'Committed Fixed',
                  amount: plan.totalCommittedExpenses,
                  color: Colors.orange.shade800,
                  isPositive: false,
                ),
                _buildFlowPill(
                  context,
                  label: 'Budgeted Variable',
                  amount: plan.budgetedVariableExpenses,
                  color: Colors.blue.shade700,
                  isPositive: false,
                ),
                _buildFlowPill(
                  context,
                  label: 'Actual Spent So Far',
                  amount: plan.actualExpenses,
                  color: colorScheme.onSurfaceVariant,
                  isPositive: false,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Available to Spend represents uncommitted cash. Future income is not assumed until recorded.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowPill(
    BuildContext context, {
    required String label,
    required double amount,
    required Color color,
    required bool isPositive,
  }) {
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        text: '$label: ',
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        children: [
          TextSpan(
            text: '${isPositive ? '+' : '-'}₹${amount.toStringAsFixed(0)}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetrics(BuildContext context, MonthlyBudgetSummary summary) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final cardWidth = isWide
            ? (constraints.maxWidth - 24) / 3
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                context,
                title: 'Total Budgeted',
                value: '₹${summary.totalPlanned.toStringAsFixed(0)}',
                subtitle: '${summary.budgetedCategoriesCount} Categories',
                icon: Icons.checklist_rounded,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                context,
                title: 'Actual Spent',
                value: '₹${summary.totalActual.toStringAsFixed(0)}',
                subtitle:
                    '${summary.overallUtilization.toStringAsFixed(1)}% Used',
                icon: Icons.shopping_bag_outlined,
                color: summary.overallUtilization > 100
                    ? colorScheme.error
                    : Colors.teal.shade700,
              ),
            ),
            SizedBox(
              width: isWide ? cardWidth : constraints.maxWidth,
              child: _buildMetricCard(
                context,
                title: 'Remaining Budget',
                value: '₹${summary.totalRemaining.toStringAsFixed(0)}',
                subtitle: summary.totalRemaining < 0
                    ? 'Exceeded Planned Budget'
                    : 'Within Planned Budget',
                icon: summary.totalRemaining < 0
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                color: summary.totalRemaining < 0
                    ? colorScheme.error
                    : Colors.green.shade700,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBudgetCard(
    BuildContext context,
    BudgetVsActualCategory item,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final progress = item.planned > 0
        ? (item.actual / item.planned).clamp(0.0, 1.0)
        : (item.actual > 0 ? 1.0 : 0.0);

    Color progressColor;
    if (item.isOverBudget) {
      progressColor = colorScheme.error;
    } else if (item.utilizationPercentage >= 85.0) {
      progressColor = Colors.orange.shade700;
    } else {
      progressColor = colorScheme.primary;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: item.isOverBudget
              ? colorScheme.error.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    item.category.type.icon,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.category.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.budget?.note != null &&
                          item.budget!.note!.isNotEmpty)
                        Text(
                          item.budget!.note!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Utilization Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: item.isOverBudget
                        ? colorScheme.errorContainer
                        : (item.utilizationPercentage >= 85
                              ? Colors.orange.shade50
                              : colorScheme.primaryContainer),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.isOverBudget
                        ? 'OVER BY ₹${(item.actual - item.planned).toStringAsFixed(0)}'
                        : '${item.utilizationPercentage.toStringAsFixed(0)}% Used',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: item.isOverBudget
                          ? colorScheme.onErrorContainer
                          : (item.utilizationPercentage >= 85
                                ? Colors.orange.shade900
                                : colorScheme.onPrimaryContainer),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                if (item.budget != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (val) {
                      if (val == 'edit') {
                        _openAddBudgetDialog(item.budget);
                      } else if (val == 'delete') {
                        _confirmDeleteBudget(item.budget!);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Budget'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete Budget',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Set Budget for Category',
                    onPressed: () {
                      final selectedMonth = ref.read(
                        selectedBudgetMonthProvider,
                      );
                      showDialog(
                        context: context,
                        builder: (context) => AddEditBudgetDialog(
                          initialYear: selectedMonth.year,
                          initialMonth: selectedMonth.month,
                          budget: Budget(
                            id: '',
                            userId: '',
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                            year: selectedMonth.year,
                            month: selectedMonth.month,
                            categoryId: item.category.id,
                            plannedAmount: 0.0,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 8),

            // Spent vs Budgeted stats with Wrap
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'Spent: ₹${item.actual.toStringAsFixed(0)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item.planned > 0
                      ? 'Budget: ₹${item.planned.toStringAsFixed(0)} (Rem: ₹${item.remaining.toStringAsFixed(0)})'
                      : 'Unbudgeted (Spent ₹${item.actual.toStringAsFixed(0)})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
