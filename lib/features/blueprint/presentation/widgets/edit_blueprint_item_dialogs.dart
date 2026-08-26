import 'package:flutter/material.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/models/financial_blueprint.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';

/// Dialog for editing a Blueprint Income item, with Type change (Income <-> Expense) support.
class EditBlueprintIncomeDialog extends StatefulWidget {
  final BlueprintIncomeItem item;

  const EditBlueprintIncomeDialog({super.key, required this.item});

  @override
  State<EditBlueprintIncomeDialog> createState() =>
      _EditBlueprintIncomeDialogState();
}

class _EditBlueprintIncomeDialogState extends State<EditBlueprintIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _amountController;
  String _type = 'income'; // 'income' or 'expense'

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.item.label);
    _amountController = TextEditingController(
      text: widget.item.monthlyAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '').trim()) ??
        0.0;
    final label = _labelController.text.trim();

    if (_type == 'income') {
      Navigator.of(context)
          .pop(widget.item.copyWith(label: label, monthlyAmount: amount));
    } else {
      // Converted to Expense
      Navigator.of(context).pop(
        BlueprintExpenseItem(
          id: widget.item.id,
          categoryName: label,
          monthlyAmount: amount,
          sourceText: widget.item.sourceText,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Income Item'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Record Type *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'income', child: Text('Income')),
                    DropdownMenuItem(value: 'expense', child: Text('Expense')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _type = val);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Name / Source *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Amount (₹) *',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    final p = double.tryParse(
                      val?.replaceAll(',', '').trim() ?? '',
                    );
                    if (p == null || p <= 0) return 'Enter a valid amount > 0';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Save Changes'),
        ),
      ],
    );
  }
}

/// Dialog for editing a Blueprint Expense item, with Type change (Expense <-> Income) support.
class EditBlueprintExpenseDialog extends StatefulWidget {
  final BlueprintExpenseItem item;

  const EditBlueprintExpenseDialog({super.key, required this.item});

  @override
  State<EditBlueprintExpenseDialog> createState() =>
      _EditBlueprintExpenseDialogState();
}

class _EditBlueprintExpenseDialogState
    extends State<EditBlueprintExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  String _type = 'expense'; // 'expense' or 'income'

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.categoryName);
    _amountController = TextEditingController(
      text: widget.item.monthlyAmount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '').trim()) ??
        0.0;
    final name = _nameController.text.trim();

    if (_type == 'expense') {
      Navigator.of(context)
          .pop(widget.item.copyWith(categoryName: name, monthlyAmount: amount));
    } else {
      // Converted to Income
      Navigator.of(context).pop(
        BlueprintIncomeItem(
          id: widget.item.id,
          label: name,
          monthlyAmount: amount,
          sourceText: widget.item.sourceText,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Expense Item'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Record Type *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'expense', child: Text('Expense')),
                    DropdownMenuItem(value: 'income', child: Text('Income')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _type = val);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category / Expense Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monthly Amount (₹) *',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    final p = double.tryParse(
                      val?.replaceAll(',', '').trim() ?? '',
                    );
                    if (p == null || p <= 0) return 'Enter a valid amount > 0';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Save Changes'),
        ),
      ],
    );
  }
}

/// Dialog for editing a Blueprint Loan item.
class EditBlueprintLoanDialog extends StatefulWidget {
  final BlueprintLoanItem item;

  const EditBlueprintLoanDialog({super.key, required this.item});

  @override
  State<EditBlueprintLoanDialog> createState() =>
      _EditBlueprintLoanDialogState();
}

class _EditBlueprintLoanDialogState extends State<EditBlueprintLoanDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emiController;
  late TextEditingController _principalController;
  late TextEditingController _interestRateController;
  late TextEditingController _tenureController;
  late LoanType _loanType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.loanName);
    _emiController = TextEditingController(
      text: widget.item.emiAmount.toStringAsFixed(0),
    );
    _principalController = TextEditingController(
      text: widget.item.outstandingPrincipal != null
          ? widget.item.outstandingPrincipal!.toStringAsFixed(0)
          : '',
    );
    _interestRateController = TextEditingController(
      text: widget.item.interestRate != null
          ? widget.item.interestRate!.toString()
          : '',
    );
    _tenureController = TextEditingController(
      text: widget.item.remainingTenureMonths != null
          ? widget.item.remainingTenureMonths!.toString()
          : '',
    );
    _loanType = widget.item.loanType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emiController.dispose();
    _principalController.dispose();
    _interestRateController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final emi =
        double.tryParse(_emiController.text.replaceAll(',', '').trim()) ?? 0.0;
    final principal = double.tryParse(
      _principalController.text.replaceAll(',', '').trim(),
    );
    final rate = double.tryParse(_interestRateController.text.trim());
    final tenure = int.tryParse(_tenureController.text.trim());

    Navigator.of(context).pop(
      widget.item.copyWith(
        loanName: _nameController.text.trim(),
        emiAmount: emi,
        loanType: _loanType,
        outstandingPrincipal: principal,
        interestRate: rate,
        remainingTenureMonths: tenure,
        missingFields: [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Loan Obligation'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Loan Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Loan name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<LoanType>(
                  initialValue: _loanType,
                  decoration: const InputDecoration(
                    labelText: 'Loan Type *',
                    border: OutlineInputBorder(),
                  ),
                  items: LoanType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.displayName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _loanType = val);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emiController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monthly EMI (₹) *',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    final p = double.tryParse(
                      val?.replaceAll(',', '').trim() ?? '',
                    );
                    if (p == null || p <= 0) return 'Enter a valid EMI > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _principalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Outstanding Principal (₹) (Optional)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _interestRateController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Interest Rate (%)',
                          suffixText: '%',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _tenureController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tenure (Months)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Save Changes'),
        ),
      ],
    );
  }
}

/// Dialog for editing a Blueprint Savings/Account item.
class EditBlueprintSavingsDialog extends StatefulWidget {
  final BlueprintSavingsItem item;

  const EditBlueprintSavingsDialog({super.key, required this.item});

  @override
  State<EditBlueprintSavingsDialog> createState() =>
      _EditBlueprintSavingsDialogState();
}

class _EditBlueprintSavingsDialogState
    extends State<EditBlueprintSavingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.accountName);
    _amountController = TextEditingController(
      text: widget.item.amount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '').trim()) ??
        0.0;
    Navigator.of(context).pop(
      widget.item.copyWith(
        accountName: _nameController.text.trim(),
        amount: amount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Account / Savings'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account / Fund Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Balance / Reserve Amount (₹) *',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  final p = double.tryParse(
                    val?.replaceAll(',', '').trim() ?? '',
                  );
                  if (p == null || p < 0) return 'Enter a valid amount >= 0';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Save Changes'),
        ),
      ],
    );
  }
}

/// Dialog for editing a Blueprint Goal item.
class EditBlueprintGoalDialog extends StatefulWidget {
  final BlueprintGoalItem item;

  const EditBlueprintGoalDialog({super.key, required this.item});

  @override
  State<EditBlueprintGoalDialog> createState() =>
      _EditBlueprintGoalDialogState();
}

class _EditBlueprintGoalDialogState extends State<EditBlueprintGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _monthsController;
  late GoalType _goalType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.goalName);
    _amountController = TextEditingController(
      text: widget.item.targetAmount.toStringAsFixed(0),
    );
    _monthsController = TextEditingController(
      text: widget.item.targetMonths != null
          ? widget.item.targetMonths.toString()
          : '',
    );
    _goalType = widget.item.goalType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '').trim()) ??
        0.0;
    final months = int.tryParse(_monthsController.text.trim());

    Navigator.of(context).pop(
      widget.item.copyWith(
        goalName: _nameController.text.trim(),
        targetAmount: amount,
        targetMonths: months,
        goalType: _goalType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Financial Goal'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Goal Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Goal name is required'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GoalType>(
                initialValue: _goalType,
                decoration: const InputDecoration(
                  labelText: 'Goal Type *',
                  border: OutlineInputBorder(),
                ),
                items: GoalType.values.map((t) {
                  return DropdownMenuItem(value: t, child: Text(t.displayName));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _goalType = val);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Amount (₹) *',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  final p = double.tryParse(
                    val?.replaceAll(',', '').trim() ?? '',
                  );
                  if (p == null || p <= 0) return 'Enter a valid target > 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _monthsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Horizon (Months) (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_rounded, size: 18),
          label: const Text('Save Changes'),
        ),
      ],
    );
  }
}
