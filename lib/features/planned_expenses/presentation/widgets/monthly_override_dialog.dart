import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';

class MonthlyOverrideDialog extends ConsumerStatefulWidget {
  final MonthlyForecastItem item;
  final int year;
  final int month;

  const MonthlyOverrideDialog({
    super.key,
    required this.item,
    required this.year,
    required this.month,
  });

  @override
  ConsumerState<MonthlyOverrideDialog> createState() =>
      _MonthlyOverrideDialogState();
}

class _MonthlyOverrideDialogState extends ConsumerState<MonthlyOverrideDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.item.effectiveAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveOverride() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final success = await ref
        .read(plannedExpenseControllerProvider.notifier)
        .setMonthlyOverride(
          planId: widget.item.plan.id,
          year: widget.year,
          month: widget.month,
          amount: amount,
        );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Monthly planned amount override saved'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final state = ref.read(plannedExpenseControllerProvider);
        final error = state.error;
        final errorMessage = error is AppException
            ? error.message
            : 'Failed to save monthly override';
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

  Future<void> _resetToDefault() async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final success = await ref
        .read(plannedExpenseControllerProvider.notifier)
        .removeMonthlyOverride(
          planId: widget.item.plan.id,
          year: widget.year,
          month: widget.month,
        );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Reset to default recurring amount'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final state = ref.read(plannedExpenseControllerProvider);
        final error = state.error;
        final errorMessage = error is AppException
            ? error.message
            : 'Failed to reset override';
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
    final theme = Theme.of(context);
    final monthName = DateFormat('MMMM yyyy')
        .format(DateTime(widget.year, widget.month));

    return AlertDialog(
      title: Text('Override for $monthName'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.plan.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Default recurring amount: ₹${widget.item.plan.defaultAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  enabled: !isLoading,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Monthly Forecast Amount',
                    prefixText: '₹ ',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null || parsed < 0) {
                      return 'Amount cannot be negative';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'This override applies ONLY to $monthName and will not change the recurring default amount.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (widget.item.hasOverride)
          TextButton(
            onPressed: isLoading ? null : _resetToDefault,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Reset to Default'),
          ),
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isLoading ? null : _saveOverride,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Override'),
        ),
      ],
    );
  }
}
