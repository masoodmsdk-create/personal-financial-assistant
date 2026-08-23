import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';

import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';

class AddEditPlannedExpenseDialog extends ConsumerStatefulWidget {
  final PlannedExpense? plan;

  const AddEditPlannedExpenseDialog({super.key, this.plan});

  @override
  ConsumerState<AddEditPlannedExpenseDialog> createState() =>
      _AddEditPlannedExpenseDialogState();
}

class _AddEditPlannedExpenseDialogState
    extends ConsumerState<AddEditPlannedExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  String? _selectedCategoryId;
  late RecurrenceFrequency _selectedFrequency;
  late DateTime _startDate;
  DateTime? _endDate;
  String? _selectedAccountId;

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan?.name ?? '');
    _amountController = TextEditingController(
      text: widget.plan != null
          ? widget.plan!.defaultAmount.toStringAsFixed(2)
          : '',
    );
    _selectedCategoryId = widget.plan?.categoryId;
    _selectedFrequency = widget.plan?.frequency ?? RecurrenceFrequency.monthly;
    _startDate = widget.plan?.startDate ?? DateTime.now();
    _endDate = widget.plan?.endDate;
    _selectedAccountId = widget.plan?.accountId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 365)),
      firstDate: _startDate,
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an Expense category'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final isEditing = widget.plan != null;

    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    bool success;
    if (isEditing) {
      final updated = widget.plan!.copyWith(
        name: name,
        categoryId: _selectedCategoryId,
        defaultAmount: amount,
        frequency: _selectedFrequency,
        startDate: _startDate,
        endDate: _endDate,
        accountId: _selectedAccountId,
      );
      success = await ref
          .read(plannedExpenseControllerProvider.notifier)
          .updatePlannedExpense(updated);
    } else {
      success = await ref
          .read(plannedExpenseControllerProvider.notifier)
          .createPlannedExpense(
            name: name,
            categoryId: _selectedCategoryId!,
            defaultAmount: amount,
            frequency: _selectedFrequency,
            startDate: _startDate,
            endDate: _endDate,
            accountId: _selectedAccountId,
          );
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Planned expense updated'
                  : 'Planned expense added successfully',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final state = ref.read(plannedExpenseControllerProvider);
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
    final controllerState = ref.watch(plannedExpenseControllerProvider);
    final isLoading = controllerState.isLoading;
    final isEditing = widget.plan != null;

    final expenseCategoriesAsync = ref.watch(expenseCategoriesProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);

    return AlertDialog(
      title: Text(isEditing ? 'Edit Planned Expense' : 'Add Planned Expense'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Expense Name',
                    hintText: 'e.g. House Rent, Electricity, Internet',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Expense name is required';
                    }
                    if (value.trim().length > 50) {
                      return 'Name cannot exceed 50 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Builder(
                  builder: (context) {
                    final fallbackCats = Category.generateDefaults('default')
                        .where((c) => c.type == CategoryType.expense)
                        .toList();
                    final loadedCategories = expenseCategoriesAsync.value;
                    final categories =
                        (loadedCategories != null &&
                            loadedCategories.isNotEmpty)
                        ? loadedCategories
                        : fallbackCats;
                    final activeExpenseCategories = categories
                        .where((c) => c.active)
                        .toList();

                    if (_selectedCategoryId == null &&
                        activeExpenseCategories.isNotEmpty) {
                      _selectedCategoryId = activeExpenseCategories.first.id;
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Expense Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: activeExpenseCategories.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        );
                      }).toList(),
                      onChanged: (isLoading || activeExpenseCategories.isEmpty)
                          ? null
                          : (val) {
                              setState(() {
                                _selectedCategoryId = val;
                              });
                            },
                      validator: (val) =>
                          val == null ? 'Please select a category' : null,
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Default Amount
                TextFormField(
                  controller: _amountController,
                  enabled: !isLoading,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Default Planned Amount',
                    prefixText: '₹ ',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Amount must be greater than zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Frequency
                DropdownButtonFormField<RecurrenceFrequency>(
                  initialValue: _selectedFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Recurrence Frequency',
                    prefixIcon: Icon(Icons.repeat_rounded),
                  ),
                  items: RecurrenceFrequency.values.map((freq) {
                    return DropdownMenuItem(
                      value: freq,
                      child: Text(freq.displayName),
                    );
                  }).toList(),
                  onChanged: isLoading
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() {
                              _selectedFrequency = val;
                            });
                          }
                        },
                ),
                const SizedBox(height: 16),

                // Start Date & End Date Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: isLoading ? null : _pickStartDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            prefixIcon: Icon(Icons.calendar_today_rounded),
                          ),
                          child: Text(_dateFormat.format(_startDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: isLoading ? null : _pickEndDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'End Date (Optional)',
                            prefixIcon: const Icon(Icons.event_busy_rounded),
                            suffixIcon: _endDate != null
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _endDate = null;
                                      });
                                    },
                                  )
                                : null,
                          ),
                          child: Text(
                            _endDate != null
                                ? _dateFormat.format(_endDate!)
                                : 'No end date',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Preferred Account Selector (Optional)
                accountsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (accounts) {
                    final activeAccounts = accounts
                        .where((a) => a.active)
                        .toList();
                    return DropdownButtonFormField<String?>(
                      initialValue: _selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Payment Account (Optional)',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Unspecified'),
                        ),
                        ...activeAccounts.map((a) {
                          return DropdownMenuItem<String?>(
                            value: a.id,
                            child: Text('${a.name} (${a.type.displayName})'),
                          );
                        }),
                      ],
                      onChanged: isLoading
                          ? null
                          : (val) {
                              setState(() {
                                _selectedAccountId = val;
                              });
                            },
                    );
                  },
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
              : Text(isEditing ? 'Save Changes' : 'Add Plan'),
        ),
      ],
    );
  }
}
