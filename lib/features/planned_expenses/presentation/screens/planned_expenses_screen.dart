import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/core/widgets/responsive_center.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';

import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/widgets/add_edit_planned_expense_dialog.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/widgets/monthly_override_dialog.dart';

class PlannedExpensesScreen extends ConsumerStatefulWidget {
  const PlannedExpensesScreen({super.key});

  @override
  ConsumerState<PlannedExpensesScreen> createState() =>
      _PlannedExpensesScreenState();
}

class _PlannedExpensesScreenState extends ConsumerState<PlannedExpensesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddPlanDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddEditPlannedExpenseDialog(),
    );
  }

  void _showEditPlanDialog(PlannedExpense plan) {
    showDialog(
      context: context,
      builder: (context) => AddEditPlannedExpenseDialog(plan: plan),
    );
  }

  void _showMonthlyOverrideDialog(
    MonthlyForecastItem item,
    int year,
    int month,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          MonthlyOverrideDialog(item: item, year: year, month: month),
    );
  }

  Future<void> _confirmArchivePlan(PlannedExpense plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Planned Expense'),
        content: Text(
          'Are you sure you want to archive "${plan.name}"?\n\n'
          'It will no longer generate forecast amounts for future months.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final errorColor = Theme.of(context).colorScheme.error;

      final success = await ref
          .read(plannedExpenseControllerProvider.notifier)
          .archivePlannedExpense(plan.id);

      if (mounted) {
        if (success) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Archived "${plan.name}"'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final state = ref.read(plannedExpenseControllerProvider);
          final error = state.error;
          final errorMessage = error is AppException
              ? error.message
              : 'Failed to archive plan';
          messenger.showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _restorePlan(PlannedExpense plan) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final success = await ref
        .read(plannedExpenseControllerProvider.notifier)
        .restorePlannedExpense(plan.id);

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Restored "${plan.name}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final state = ref.read(plannedExpenseControllerProvider);
        final error = state.error;
        final errorMessage = error is AppException
            ? error.message
            : 'Failed to restore plan';
        messenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: [
          _MonthlyForecastTabView(
            onEditOverride: _showMonthlyOverrideDialog,
            onAddPlan: _showAddPlanDialog,
          ),
          _RecurringPlansTabView(
            showArchived: _showArchived,
            onToggleArchived: () {
              setState(() {
                _showArchived = !_showArchived;
              });
            },
            onEdit: _showEditPlanDialog,
            onArchive: _confirmArchivePlan,
            onRestore: _restorePlan,
            onAdd: _showAddPlanDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPlanDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Plan'),
      ),
    );
  }
}

class _MonthlyForecastTabView extends ConsumerWidget {
  final void Function(MonthlyForecastItem, int, int) onEditOverride;
  final VoidCallback onAddPlan;

  const _MonthlyForecastTabView({
    required this.onEditOverride,
    required this.onAddPlan,
  });

  void _previousMonth(WidgetRef ref, DateTime currentDate) {
    ref.read(selectedForecastDateProvider.notifier).state = DateTime(
      currentDate.year,
      currentDate.month - 1,
    );
  }

  void _nextMonth(WidgetRef ref, DateTime currentDate) {
    ref.read(selectedForecastDateProvider.notifier).state = DateTime(
      currentDate.year,
      currentDate.month + 1,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedForecastDateProvider);
    final forecastAsync = ref.watch(monthlyForecastProvider);
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final theme = Theme.of(context);
    final monthName = DateFormat('MMMM yyyy').format(selectedDate);

    final categoryMap = <String, String>{};
    if (categoriesAsync.hasValue) {
      for (final cat in categoriesAsync.value!) {
        categoryMap[cat.id] = cat.name;
      }
    }

    return Column(
      children: [
        // Month Selector Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _previousMonth(ref, selectedDate),
              ),
              Text(
                monthName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _nextMonth(ref, selectedDate),
              ),
            ],
          ),
        ),

        // Forecast View Body
        Expanded(
          child: forecastAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error loading forecast: $err'),
              ),
            ),
            data: (forecast) {
              return SingleChildScrollView(
                child: ResponsiveCenter(
                  maxWidth: 1000,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageHeader(
                        title: 'Planned Expenses',
                        subtitle: 'Plan recurring obligations and upcoming spending before they occur.',
                        action: FilledButton.icon(
                          onPressed: onAddPlan,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Plan'),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Total Forecast Card
                      Card(
                        elevation: 0,
                        color: theme.colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.savings_outlined,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Total Forecasted Expense',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onPrimaryContainer,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const FinancialStatusChip(
                                    FinancialStatusType.forecast,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),
                              Text(
                                '₹ ${forecast.totalPlannedAmount.toStringAsFixed(2)}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Expected planned expenses for $monthName',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(
                        'Planned Expenses Breakdown',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (forecast.items.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_note_rounded,
                                  size: 48,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No planned expenses for $monthName',
                                  style: theme.textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: onAddPlan,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add Planned Expense'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...forecast.items.map((item) {
                          final categoryName =
                              categoryMap[item.plan.categoryId] ?? 'Expense';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                child: Icon(
                                  item.plan.frequency.icon,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              title: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 2,
                                children: [
                                  Text(
                                    item.plan.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (item.hasOverride)
                                    Chip(
                                      label: const Text('Overridden'),
                                      labelStyle: TextStyle(
                                        fontSize: 10,
                                        color: theme.colorScheme.tertiary,
                                      ),
                                      backgroundColor: theme
                                          .colorScheme
                                          .tertiaryContainer
                                          .withValues(alpha: 0.6),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                '$categoryName • ${item.plan.frequency.displayName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹ ${item.effectiveAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: item.hasOverride
                                          ? theme.colorScheme.tertiary
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    item.hasOverride
                                        ? 'Default: ₹${item.plan.defaultAmount.toStringAsFixed(2)}'
                                        : 'Default amount',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => onEditOverride(
                                item,
                                forecast.year,
                                forecast.month,
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecurringPlansTabView extends ConsumerWidget {
  final bool showArchived;
  final VoidCallback onToggleArchived;
  final void Function(PlannedExpense) onEdit;
  final void Function(PlannedExpense) onArchive;
  final void Function(PlannedExpense) onRestore;
  final VoidCallback onAdd;

  const _RecurringPlansTabView({
    required this.showArchived,
    required this.onToggleArchived,
    required this.onEdit,
    required this.onArchive,
    required this.onRestore,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plannedExpensesStreamProvider);
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    final categoryMap = <String, String>{};
    if (categoriesAsync.hasValue) {
      for (final cat in categoriesAsync.value!) {
        categoryMap[cat.id] = cat.name;
      }
    }

    return Column(
      children: [
        // Action Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recurring Templates',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(
                  showArchived ? Icons.archive_rounded : Icons.archive_outlined,
                ),
                tooltip: showArchived ? 'Hide Archived' : 'Show Archived',
                onPressed: onToggleArchived,
              ),
            ],
          ),
        ),

        Expanded(
          child: plansAsync.when(
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading plans: $err')),
            data: (plans) {
              final filtered = plans.where((p) {
                if (showArchived) return true;
                return p.active;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_repeat_rounded,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Planned Expenses',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          showArchived
                              ? 'No active or archived planned expenses found.'
                              : 'Tap the button below to add your first recurring planned expense.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Planned Expense'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(
                  top: 8,
                  left: 16,
                  right: 16,
                  bottom: 88,
                ),
                itemCount: filtered.length,

                itemBuilder: (context, index) {
                  final plan = filtered[index];
                  final isArchived = !plan.active;
                  final categoryName =
                      categoryMap[plan.categoryId] ?? 'Expense';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: isArchived ? 0 : 1,
                    color: isArchived
                        ? theme.colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          )
                        : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isArchived
                            ? theme.colorScheme.outline.withValues(alpha: 0.2)
                            : theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(
                          plan.frequency.icon,
                          color: isArchived
                              ? theme.colorScheme.outline
                              : theme.colorScheme.primary,
                        ),
                      ),
                      title: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          Text(
                            plan.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: isArchived
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isArchived
                                  ? theme.colorScheme.outline
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          if (isArchived)
                            Chip(
                              label: const Text('Archived'),
                              labelStyle: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.error,
                              ),
                              backgroundColor: theme.colorScheme.errorContainer
                                  .withValues(alpha: 0.5),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      subtitle: Text(
                        '$categoryName • ${plan.frequency.displayName} • Starts ${dateFormat.format(plan.startDate)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹ ${plan.defaultAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isArchived
                                  ? theme.colorScheme.outline
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!isArchived)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit Plan',
                              onPressed: () => onEdit(plan),
                            ),
                          if (!isArchived)
                            IconButton(
                              icon: const Icon(Icons.archive_outlined),
                              tooltip: 'Archive Plan',
                              onPressed: () => onArchive(plan),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.unarchive_outlined),
                              tooltip: 'Restore Plan',
                              onPressed: () => onRestore(plan),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
