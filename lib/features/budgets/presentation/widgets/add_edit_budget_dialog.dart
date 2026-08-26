import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/budgets/domain/models/budget.dart';
import 'package:personal_financial_assistant/features/budgets/presentation/providers/budget_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';

class AddEditBudgetDialog extends ConsumerStatefulWidget {
  final Budget? budget;
  final int initialYear;
  final int initialMonth;

  const AddEditBudgetDialog({
    super.key,
    this.budget,
    required this.initialYear,
    required this.initialMonth,
  });

  @override
  ConsumerState<AddEditBudgetDialog> createState() =>
      _AddEditBudgetDialogState();
}

class _AddEditBudgetDialogState extends ConsumerState<AddEditBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  String? _selectedCategoryId;
  late int _year;
  late int _month;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    _amountController = TextEditingController(
      text: b != null ? b.plannedAmount.toStringAsFixed(0) : '',
    );
    _noteController = TextEditingController(text: b?.note ?? '');
    _selectedCategoryId = b?.categoryId;
    _year = b?.year ?? widget.initialYear;
    _month = b?.month ?? widget.initialMonth;
  }

  @override
  void dispose() {
    _amountController.dispose;
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than 0'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final isEdit = widget.budget != null;
    final now = DateTime.now();

    final budget = Budget(
      id: widget.budget?.id ?? 'budget_${now.millisecondsSinceEpoch}',
      userId: widget.budget?.userId ?? '',
      createdAt: widget.budget?.createdAt ?? now,
      updatedAt: now,
      year: _year,
      month: _month,
      categoryId: _selectedCategoryId!,
      plannedAmount: amount,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
      active: true,
    );

    bool success;
    if (isEdit) {
      success = await ref
          .read(budgetControllerProvider.notifier)
          .updateBudget(budget);
    } else {
      success = await ref
          .read(budgetControllerProvider.notifier)
          .addBudget(budget);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Budget updated successfully'
                  : 'Budget added successfully',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save budget')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categories =
        ref.watch(categoriesStreamProvider).value ??
        Category.generateDefaults('default');

    // Only expense categories can be budgeted
    final expenseCategories = categories
        .where((c) => c.type == CategoryType.expense && c.active)
        .toList();

    // Default category if none selected
    if (_selectedCategoryId == null && expenseCategories.isNotEmpty) {
      _selectedCategoryId = expenseCategories.first.id;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.budget != null
                          ? Icons.edit_note_rounded
                          : Icons.add_chart_rounded,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.budget != null
                            ? 'Edit Budget'
                            : 'Set Category Budget',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_rounded),
                    border: OutlineInputBorder(),
                  ),
                  items: expenseCategories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Select a category' : null,
                ),
                const SizedBox(height: 16),

                // Planned Amount Input
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Monthly Budget Amount',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 8000',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Enter budget amount';
                    }
                    final parsed = double.tryParse(val.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Notes (Optional)
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Target dining out cap for this month',
                  ),
                ),
                const SizedBox(height: 24),

                // Mandatory Visible Submit / Cancel Actions
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        widget.budget != null ? 'Save Changes' : 'Add Budget',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
