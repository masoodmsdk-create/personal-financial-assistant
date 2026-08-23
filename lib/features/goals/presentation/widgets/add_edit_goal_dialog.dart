import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';

class AddEditGoalDialog extends ConsumerStatefulWidget {
  final Goal? goal;

  const AddEditGoalDialog({super.key, this.goal});

  @override
  ConsumerState<AddEditGoalDialog> createState() => _AddEditGoalDialogState();
}

class _AddEditGoalDialogState extends ConsumerState<AddEditGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetAmountController;
  late final TextEditingController _currentAmountController;
  late final TextEditingController _notesController;
  late GoalType _selectedType;
  DateTime? _selectedTargetDate;

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _nameController = TextEditingController(text: g?.name ?? '');
    _targetAmountController = TextEditingController(
      text: g != null ? g.targetAmount.toStringAsFixed(2) : '',
    );
    _currentAmountController = TextEditingController(
      text: g != null ? g.currentAmount.toStringAsFixed(2) : '0.00',
    );
    _notesController = TextEditingController(text: g?.notes ?? '');
    _selectedType = g?.type ?? GoalType.savingsGoal;
    _selectedTargetDate = g?.targetDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTargetDate ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: DateTime(now.year + 50),
    );
    if (picked != null) {
      setState(() {
        _selectedTargetDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final targetAmount =
        double.tryParse(_targetAmountController.text.trim()) ?? 0.0;
    final currentAmount =
        double.tryParse(_currentAmountController.text.trim()) ?? 0.0;
    final notes = _notesController.text.trim();

    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final isEditing = widget.goal != null;

    bool success;
    if (isEditing) {
      final updated = widget.goal!.copyWith(
        name: name,
        type: _selectedType,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        targetDate: _selectedTargetDate,
        notes: notes.isNotEmpty ? notes : null,
        updatedAt: DateTime.now(),
      );
      success = await ref
          .read(goalControllerProvider.notifier)
          .updateGoal(updated);
    } else {
      success = await ref
          .read(goalControllerProvider.notifier)
          .createGoal(
            name: name,
            type: _selectedType,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            targetDate: _selectedTargetDate,
            notes: notes.isNotEmpty ? notes : null,
          );
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Goal updated successfully'
                  : 'Goal created successfully',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final state = ref.read(goalControllerProvider);
        final error = state.error;
        final errorMessage = error is AppException
            ? error.message
            : (error?.toString() ?? 'Operation failed');
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
    final controllerState = ref.watch(goalControllerProvider);
    final isLoading = controllerState.isLoading;
    final theme = Theme.of(context);
    final isEditing = widget.goal != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Goal' : 'Create Financial Goal'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Goal Type Chips
                Text(
                  'Goal Category',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: GoalType.values.map((type) {
                    final selected = _selectedType == type;
                    return ChoiceChip(
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
                      onSelected: isLoading
                          ? null
                          : (val) {
                              if (val) {
                                setState(() {
                                  _selectedType = type;
                                });
                              }
                            },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Name
                TextFormField(
                  controller: _nameController,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Goal Title',
                    hintText: 'e.g. New Home Deposit, Emergency Fund',
                    prefixIcon: Icon(Icons.flag_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a goal title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Target Amount
                TextFormField(
                  controller: _targetAmountController,
                  enabled: !isLoading,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount',
                    prefixText: '₹ ',
                    prefixIcon: Icon(Icons.ads_click_rounded),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a target amount';
                    }
                    final parsed = double.tryParse(val.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid target amount greater than zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Current Saved Amount
                TextFormField(
                  controller: _currentAmountController,
                  enabled: !isLoading,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Current Saved Amount',
                    prefixText: '₹ ',
                    prefixIcon: Icon(Icons.savings_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty) {
                      final parsed = double.tryParse(val.trim());
                      if (parsed == null || parsed < 0) {
                        return 'Enter a valid saved amount';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Target Date Selector
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedTargetDate == null
                            ? 'Target Date: Not set'
                            : 'Target Date: ${_dateFormat.format(_selectedTargetDate!)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: isLoading ? null : _pickTargetDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(
                        _selectedTargetDate == null ? 'Set Date' : 'Change',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Notes
                TextFormField(
                  controller: _notesController,
                  enabled: !isLoading,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Description (Optional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                    border: OutlineInputBorder(),
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
              : Text(isEditing ? 'Save Changes' : 'Create Goal'),
        ),
      ],
    );
  }
}
