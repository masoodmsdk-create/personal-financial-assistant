import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';

class AddEditLoanDialog extends ConsumerStatefulWidget {
  final Loan? loan;

  const AddEditLoanDialog({super.key, this.loan});

  @override
  ConsumerState<AddEditLoanDialog> createState() => _AddEditLoanDialogState();
}

class _AddEditLoanDialogState extends ConsumerState<AddEditLoanDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _originalPrincipalController;
  late TextEditingController _outstandingPrincipalController;
  late TextEditingController _interestRateController;
  late TextEditingController _emiController;
  late TextEditingController _tenureController;
  late TextEditingController _notesController;

  late LoanType _selectedType;
  late InterestRateType _selectedInterestType;
  DateTime? _startDate;
  DateTime? _nextEmiDate;
  String? _selectedAccountId;
  bool _showAdvancedFields = false;

  bool get _isEditing => widget.loan != null;

  @override
  void initState() {
    super.initState();
    final l = widget.loan;
    _nameController = TextEditingController(text: l?.name ?? '');
    _originalPrincipalController = TextEditingController(
      text: l?.originalPrincipal != null ? l!.originalPrincipal.toString() : '',
    );
    _outstandingPrincipalController = TextEditingController(
      text: l?.outstandingPrincipal != null
          ? l!.outstandingPrincipal.toString()
          : '',
    );
    _interestRateController = TextEditingController(
      text: l?.interestRate != null ? l!.interestRate.toString() : '',
    );
    _emiController = TextEditingController(
      text: l?.emiAmount != null ? l!.emiAmount.toString() : '',
    );
    _tenureController = TextEditingController(
      text: l?.remainingTenureMonths != null
          ? l!.remainingTenureMonths.toString()
          : '',
    );
    _notesController = TextEditingController(text: l?.notes ?? '');

    _selectedType = l?.type ?? LoanType.homeLoan;
    _selectedInterestType = l?.interestRateType ?? InterestRateType.fixed;
    _startDate = l?.startDate;
    _nextEmiDate = l?.nextEmiDate;
    _selectedAccountId = l?.linkedAccountId;

    if (_isEditing) {
      _showAdvancedFields = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _originalPrincipalController.dispose();
    _outstandingPrincipalController.dispose();
    _interestRateController.dispose();
    _emiController.dispose();
    _tenureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final origP = double.tryParse(_originalPrincipalController.text.trim());
    final outP = double.tryParse(_outstandingPrincipalController.text.trim());
    final rate = double.tryParse(_interestRateController.text.trim());
    final emi = double.tryParse(_emiController.text.trim());
    final tenure = int.tryParse(_tenureController.text.trim());
    final notes = _notesController.text.trim();

    final controller = ref.read(loanControllerProvider.notifier);

    bool success;
    if (_isEditing) {
      final updated = widget.loan!.copyWith(
        name: name,
        type: _selectedType,
        originalPrincipal: origP,
        outstandingPrincipal: outP,
        interestRate: rate,
        interestRateType: _selectedInterestType,
        emiAmount: emi,
        remainingTenureMonths: tenure,
        startDate: _startDate,
        nextEmiDate: _nextEmiDate,
        linkedAccountId: _selectedAccountId,
        notes: notes.isNotEmpty ? notes : null,
      );
      success = await controller.updateLoan(updated);
    } else {
      success = await controller.createLoan(
        name: name,
        type: _selectedType,
        originalPrincipal: origP,
        outstandingPrincipal: outP,
        interestRate: rate,
        interestRateType: _selectedInterestType,
        emiAmount: emi,
        remainingTenureMonths: tenure,
        startDate: _startDate,
        nextEmiDate: _nextEmiDate,
        linkedAccountId: _selectedAccountId,
        notes: notes.isNotEmpty ? notes : null,
      );
    }

    if (mounted && success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final accounts = accountsAsync.value ?? [];
    final isLoading = ref.watch(loanControllerProvider).isLoading;

    return AlertDialog(
      title: Text(_isEditing ? 'Edit Loan' : 'Add Loan / Debt'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 450,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Loan Name *',
                    hintText: 'e.g. HDFC Home Loan, SBI Car Loan',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter a loan name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<LoanType>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Loan Type *',
                    border: OutlineInputBorder(),
                  ),
                  items: LoanType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(type.icon, size: 20, color: type.color),
                          const SizedBox(width: 8),
                          Text(type.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _outstandingPrincipalController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Outstanding Principal (₹)',
                    hintText: 'e.g. 4500000',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _interestRateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Interest Rate (%)',
                          hintText: 'e.g. 8.5',
                          suffixText: '%',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _emiController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'EMI Amount (₹)',
                          hintText: 'e.g. 52000',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextButton.icon(
                  onPressed: () {
                    setState(() => _showAdvancedFields = !_showAdvancedFields);
                  },
                  icon: Icon(
                    _showAdvancedFields ? Icons.expand_less : Icons.expand_more,
                  ),
                  label: Text(
                    _showAdvancedFields
                        ? 'Hide Optional Details'
                        : 'Add More Details (Tenure, Accounts, Dates)',
                  ),
                ),

                if (_showAdvancedFields) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _originalPrincipalController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Original Principal (₹)',
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
                            labelText: 'Remaining Months',
                            hintText: 'e.g. 180',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<InterestRateType>(
                    initialValue: _selectedInterestType,
                    decoration: const InputDecoration(
                      labelText: 'Interest Rate Type',
                      border: OutlineInputBorder(),
                    ),
                    items: InterestRateType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(t.displayName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedInterestType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  if (accounts.isNotEmpty) ...[
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedAccountId,
                      decoration: const InputDecoration(
                        labelText: 'Linked Payment Account',
                        border: OutlineInputBorder(),
                      ),

                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('None'),
                        ),
                        ...accounts.map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.name} (${a.type.displayName})'),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedAccountId = val),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
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
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Save Changes' : 'Create Loan'),
        ),
      ],
    );
  }
}
