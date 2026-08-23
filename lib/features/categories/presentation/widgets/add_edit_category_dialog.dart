import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';

class AddEditCategoryDialog extends ConsumerStatefulWidget {
  final Category? category;
  final CategoryType defaultType;

  const AddEditCategoryDialog({
    super.key,
    this.category,
    this.defaultType = CategoryType.expense,
  });

  @override
  ConsumerState<AddEditCategoryDialog> createState() =>
      _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends ConsumerState<AddEditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late CategoryType _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedType = widget.category?.type ?? widget.defaultType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final isEditing = widget.category != null;

    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    bool success;
    if (isEditing) {
      final updated = widget.category!.copyWith(name: name);
      success = await ref
          .read(categoryControllerProvider.notifier)
          .updateCategory(updated);
    } else {
      success = await ref
          .read(categoryControllerProvider.notifier)
          .createCategory(name: name, type: _selectedType);
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Category updated' : 'Category created successfully',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final state = ref.read(categoryControllerProvider);
        final error = state.error;
        final errorMessage = error is AppException
            ? error.message
            : (error?.toString() ?? 'Operation failed. Please try again.');
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
    final controllerState = ref.watch(categoryControllerProvider);
    final isLoading = controllerState.isLoading;
    final theme = Theme.of(context);
    final isEditing = widget.category != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Category' : 'Add Category'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  onFieldSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g. Groceries, Investment, Books',
                    prefixIcon: Icon(Icons.label_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Category name is required';
                    }
                    if (value.trim().length > 50) {
                      return 'Name cannot exceed 50 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Category Type',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: CategoryType.values.map((type) {
                    final selected = _selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(type.displayName),
                        avatar: Icon(
                          type.icon,
                          size: 18,
                          color: selected ? Colors.white : type.color,
                        ),
                        selected: selected,
                        selectedColor: type.color,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (isLoading || isEditing)
                            ? null
                            : (val) {
                                if (val) {
                                  setState(() {
                                    _selectedType = type;
                                  });
                                }
                              },
                      ),
                    );
                  }).toList(),
                ),
                if (isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      'Category type cannot be changed once created.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isLoading ? null : _save,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEditing ? 'Save Changes' : 'Add Category'),
        ),
      ],
    );
  }
}
