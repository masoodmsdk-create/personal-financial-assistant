import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';

class AddEditAccountDialog extends ConsumerStatefulWidget {
  final Account? account;

  const AddEditAccountDialog({super.key, this.account});

  @override
  ConsumerState<AddEditAccountDialog> createState() =>
      _AddEditAccountDialogState();
}

class _AddEditAccountDialogState extends ConsumerState<AddEditAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late AccountType _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _balanceController = TextEditingController(
      text: widget.account != null
          ? widget.account!.effectiveBalance.toStringAsFixed(2)
          : '0.00',
    );
    _selectedType = widget.account?.type ?? AccountType.bank;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    final isEditing = widget.account != null;

    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    bool success;
    if (isEditing) {
      success = await ref
          .read(accountControllerProvider.notifier)
          .updateAccount(
            account: widget.account!,
            name: name,
            type: _selectedType,
            openingBalance: balance,
          );
    } else {
      success = await ref
          .read(accountControllerProvider.notifier)
          .createAccount(
            name: name,
            type: _selectedType,
            openingBalance: balance,
          );
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Account updated' : 'Account created successfully',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final state = ref.read(accountControllerProvider);
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
    final controllerState = ref.watch(accountControllerProvider);
    final isLoading = controllerState.isLoading;
    final theme = Theme.of(context);
    final isEditing = widget.account != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Account' : 'Add Account'),
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
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    hintText: 'e.g. HDFC Bank, Cash Wallet',
                    prefixIcon: Icon(Icons.label_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Account name is required';
                    }
                    if (value.trim().length > 50) {
                      return 'Name cannot exceed 50 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Account Type',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AccountType.values.map((type) {
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
                TextFormField(
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  onFieldSubmitted: (_) => _save(),
                  decoration: const InputDecoration(
                    labelText: 'Opening Balance',
                    prefixText: '₹ ',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Balance is required';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Enter a valid number';
                    }
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
              : Text(isEditing ? 'Save Changes' : 'Add Account'),
        ),
      ],
    );
  }
}
