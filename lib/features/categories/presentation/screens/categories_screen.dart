import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/core/widgets/responsive_center.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/categories/presentation/widgets/add_edit_category_dialog.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
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

  void _showAddCategoryDialog(CategoryType type) {
    showDialog(
      context: context,
      builder: (context) => AddEditCategoryDialog(defaultType: type),
    );
  }

  void _showEditCategoryDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => AddEditCategoryDialog(category: category),
    );
  }

  Future<void> _confirmArchiveCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Category'),
        content: Text(
          'Are you sure you want to archive "${category.name}"?\n\n'
          'It will no longer appear for new transactions, but will remain available for historical records.',
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
          .read(categoryControllerProvider.notifier)
          .archiveCategory(category.id);

      if (mounted) {
        if (success) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Archived "${category.name}"'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final state = ref.read(categoryControllerProvider);
          final error = state.error;
          final errorMessage = error is AppException
              ? error.message
              : 'Failed to archive category';
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

  Future<void> _restoreCategory(Category category) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final success = await ref
        .read(categoryControllerProvider.notifier)
        .restoreCategory(category.id);

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Restored "${category.name}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final state = ref.read(categoryControllerProvider);
        final error = state.error;
        final errorMessage = error is AppException
            ? error.message
            : 'Failed to restore category';
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
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: Icon(
              _showArchived ? Icons.archive_rounded : Icons.archive_outlined,
            ),
            tooltip: _showArchived ? 'Hide Archived' : 'Show Archived',
            onPressed: () {
              setState(() {
                _showArchived = !_showArchived;
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(
                Icons.arrow_downward_rounded,
                color: Color(0xFF2E7D32),
              ),
              text: 'Income',
            ),
            Tab(
              icon: Icon(Icons.arrow_upward_rounded, color: Color(0xFFC62828)),
              text: 'Expense',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryListView(
            type: CategoryType.income,
            showArchived: _showArchived,
            onEdit: _showEditCategoryDialog,
            onArchive: _confirmArchiveCategory,
            onRestore: _restoreCategory,
            onAdd: () => _showAddCategoryDialog(CategoryType.income),
          ),
          _CategoryListView(
            type: CategoryType.expense,
            showArchived: _showArchived,
            onEdit: _showEditCategoryDialog,
            onArchive: _confirmArchiveCategory,
            onRestore: _restoreCategory,
            onAdd: () => _showAddCategoryDialog(CategoryType.expense),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final currentType = _tabController.index == 0
              ? CategoryType.income
              : CategoryType.expense;
          _showAddCategoryDialog(currentType);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Category'),
      ),
    );
  }
}

class _CategoryListView extends ConsumerWidget {
  final CategoryType type;
  final bool showArchived;
  final void Function(Category) onEdit;
  final void Function(Category) onArchive;
  final void Function(Category) onRestore;
  final VoidCallback onAdd;

  const _CategoryListView({
    required this.type,
    required this.showArchived,
    required this.onEdit,
    required this.onArchive,
    required this.onRestore,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = type == CategoryType.income
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(expenseCategoriesProvider);

    final theme = Theme.of(context);

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading categories',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (categories) {
        final filtered = categories.where((c) {
          if (showArchived) return true;
          return c.active;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(type.icon, size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No ${type.displayName} Categories',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    showArchived
                        ? 'No active or archived ${type.displayName.toLowerCase()} categories found.'
                        : 'Tap the button below to add your first ${type.displayName.toLowerCase()} category.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded),
                    label: Text('Add ${type.displayName} Category'),
                  ),
                ],
              ),
            ),
          );
        }

        return ResponsiveCenter(
          maxWidth: 800,
          padding: const EdgeInsets.only(
            top: 8,
            left: 16,
            right: 16,
            bottom: 88,
          ),
          child: ListView.builder(
            itemCount: filtered.length,

            itemBuilder: (context, index) {
              final category = filtered[index];
              final isArchived = !category.active;

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
                        : type.color.withValues(alpha: 0.12),
                    child: Icon(
                      type.icon,
                      color: isArchived
                          ? theme.colorScheme.outline
                          : type.color,
                    ),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          category.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: isArchived
                                ? TextDecoration.lineThrough
                                : null,
                            color: isArchived
                                ? theme.colorScheme.outline
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (category.isDefault) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: const Text('Default'),
                          labelStyle: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                      if (isArchived) ...[
                        const SizedBox(width: 8),
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
                    ],
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isArchived)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit Category',
                          onPressed: () => onEdit(category),
                        ),
                      if (!isArchived)
                        IconButton(
                          icon: const Icon(Icons.archive_outlined),
                          tooltip: 'Archive Category',
                          onPressed: () => onArchive(category),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.unarchive_outlined),
                          tooltip: 'Restore Category',
                          onPressed: () => onRestore(category),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
