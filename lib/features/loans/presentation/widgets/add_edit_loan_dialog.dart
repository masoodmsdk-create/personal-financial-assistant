import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
  late TextEditingController _lenderController;
  late TextEditingController _originalPrincipalController;
  late TextEditingController _outstandingPrincipalController;
  late TextEditingController _interestRateController;
  late TextEditingController _emiController;
  late TextEditingController _tenureController;
  late TextEditingController _processingFeeController;
  late TextEditingController _prepaymentChargesController;
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
    _lenderController = TextEditingController(text: l?.lenderName ?? '');
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
    _processingFeeController = TextEditingController(
      text: l?.processingFee != null ? l!.processingFee.toString() : '',
    );
    _prepaymentChargesController = TextEditingController(
      text: l?.prepaymentCharges != null ? l!.prepaymentCharges.toString() : '',
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
    _lenderController.dispose();
    _originalPrincipalController.dispose();
    _outstandingPrincipalController.dispose();
    _interestRateController.dispose();
    _emiController.dispose();
    _tenureController.dispose();
    _processingFeeController.dispose();
    _prepaymentChargesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final lender = _lenderController.text.trim();
    final origP = double.tryParse(_originalPrincipalController.text.trim());
    final outP = double.tryParse(_outstandingPrincipalController.text.trim());
    final rate = double.tryParse(_interestRateController.text.trim());
    final emi = double.tryParse(_emiController.text.trim());
    final tenure = int.tryParse(_tenureController.text.trim());
    final fee = double.tryParse(_processingFeeController.text.trim());
    final penalty = double.tryParse(_prepaymentChargesController.text.trim());
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
        lenderName: lender.isNotEmpty ? lender : null,
        processingFee: fee,
        prepaymentCharges: penalty,
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
        lenderName: lender.isNotEmpty ? lender : null,
        processingFee: fee,
        prepaymentCharges: penalty,
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
                  isExpanded: true,
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
                  controller: _lenderController,
                  decoration: const InputDecoration(
                    labelText: 'Lender / Bank Name (Optional)',
                    hintText: 'e.g. HDFC Bank, SBI, ICICI',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _outstandingPrincipalController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Outstanding Principal (₹)',
                    hintText: 'Current balance owed',
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
                          hintText: 'Annual %',
                          suffixText: '%',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<InterestRateType>(
                        isExpanded: true,
                        initialValue: _selectedInterestType,
                        decoration: const InputDecoration(
                          labelText: 'Rate Type',
                          border: OutlineInputBorder(),
                        ),
                        items: InterestRateType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          );
                        }).toList(),

                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedInterestType = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emiController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Monthly EMI (₹)',
                          prefixText: '₹ ',
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
                          hintText: 'Tenure',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Toggle Advanced Fields
                InkWell(
                  onTap: () => setState(
                    () => _showAdvancedFields = !_showAdvancedFields,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          _showAdvancedFields
                              ? Icons.arrow_drop_down
                              : Icons.arrow_right,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        Text(
                          _showAdvancedFields
                              ? 'Hide Advanced Details'
                              : 'Show Advanced Details (Fees, Dates, Account)',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showAdvancedFields) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _originalPrincipalController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Original Loan Principal (₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _processingFeeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Processing Fee (₹)',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _prepaymentChargesController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Prepayment Charges (₹)',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Linked EMI Account',
                      hintText: 'Account from which EMI is debited',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('None / Unlinked'),
                      ),
                      ...accounts.map((acc) {
                        return DropdownMenuItem(
                          value: acc.id,
                          child: Text(
                            '${acc.name} (${acc.type.displayName})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedAccountId = val),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _nextEmiDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => _nextEmiDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _nextEmiDate != null
                                ? 'Next EMI: ${DateFormat('dd/MM/yy').format(_nextEmiDate!)}'
                                : 'Next EMI Date',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Remarks',
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
        FilledButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Save Changes' : 'Save Loan'),
        ),
      ],
    );
  }
}
