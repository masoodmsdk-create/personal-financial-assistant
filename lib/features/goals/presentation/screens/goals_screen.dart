import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/core/widgets/responsive_center.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/goals/presentation/widgets/add_edit_goal_dialog.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  void _showAddGoalDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const AddEditGoalDialog(),
    );
  }

  void _showEditGoalDialog(BuildContext context, Goal goal) {
    showDialog<void>(
      context: context,
      builder: (context) => AddEditGoalDialog(goal: goal),
    );
  }

  Future<void> _confirmDeleteGoal(
    BuildContext context,
    WidgetRef ref,
    Goal goal,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text(
          'Are you sure you want to delete "${goal.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: errorColor),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(goalControllerProvider.notifier)
          .deleteGoal(goal.id);

      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Goal "${goal.name}" deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final state = ref.read(goalControllerProvider);
        messenger.showSnackBar(
          SnackBar(
            content: Text(state.error?.toString() ?? 'Failed to delete goal.'),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsStreamProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return SingleChildScrollView(
              child: ResponsiveCenter(
                maxWidth: 1000,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    PageHeader(
                      title: 'Financial Goals',
                      subtitle: 'Track savings targets, emergency reserves, and major purchases.',
                      action: FilledButton.icon(
                        onPressed: () => _showAddGoalDialog(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Goal'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    EmptyStateWidget(
                      icon: Icons.flag_outlined,
                      title: 'No Goals Created Yet',
                      message: 'Define your savings targets, debt payoff plans, or emergency reserve goals to stay motivated and track your progress.',
                      actionLabel: 'Create Goal',
                      onAction: () => _showAddGoalDialog(context),
                    ),
                  ],
                ),
              ),
            );
          }

          final activeGoals = goals.where((g) => g.active).toList();

          return SingleChildScrollView(
            child: ResponsiveCenter(
              maxWidth: 1000,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHeader(
                    title: 'Financial Goals',
                    subtitle: 'Track savings targets, emergency reserves, and major purchases.',
                    action: FilledButton.icon(
                      onPressed: () => _showAddGoalDialog(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Goal'),
                    ),
                  ),

                  // Active Goals Summary Card
                  Card(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Icon(
                              Icons.flag_rounded,
                              size: 32,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Financial Targets',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${activeGoals.length} Active Goals tracked',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Your Goals',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeGoals.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final goal = activeGoals[index];
                      return _GoalCard(
                        goal: goal,
                        onEdit: () => _showEditGoalDialog(context, goal),
                        onDelete: () => _confirmDeleteGoal(context, ref, goal),
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
        loading: () =>
            const LoadingWidget(message: 'Loading financial goals...'),
        error: (error, stack) => AppErrorWidget(
          message: 'Failed to load goals: $error',
          onRetry: () => ref.invalidate(goalsStreamProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Goal'),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final type = goal.type;
    final progress = (goal.progressPercentage / 100.0).clamp(0.0, 1.0);
    final dateStr = goal.targetDate != null
        ? DateFormat('MMM yyyy').format(goal.targetDate!)
        : null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: type.color.withValues(alpha: 0.15),
                  child: Icon(type.icon, size: 22, color: type.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type.displayName +
                            (dateStr != null ? ' • Target: $dateStr' : ''),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Goal'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amounts Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    MoneyText(
                      goal.currentAmount,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: type.color,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    MoneyText(
                      goal.targetAmount,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: type.color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(type.color),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.progressPercentage.toStringAsFixed(0)}% Completed',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: type.color,
                  ),
                ),
                Text(
                  '₹ ${goal.remainingAmount.toStringAsFixed(0)} Remaining',
                  style: theme.textTheme.labelSmall?.copyWith(
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
