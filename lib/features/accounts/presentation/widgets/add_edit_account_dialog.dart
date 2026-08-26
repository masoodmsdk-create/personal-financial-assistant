import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/domain/models/account_type_definition.dart';
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
  late String _selectedTypeId;
  late AccountType _selectedEnum;
  late AccountNature _selectedNature;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');

    _balanceController = TextEditingController(
      text: widget.account != null
          ? widget.account!.effectiveBalance.toStringAsFixed(2)
          : '0.00',
    );
    _selectedTypeId =
        widget.account?.accountTypeId ?? widget.account?.type.value ?? 'bank';
    _selectedEnum = widget.account?.type ?? AccountType.bank;
    _selectedNature =
        widget.account?.nature ??
        (widget.account?.isLiabilityAccount == true
            ? AccountNature.liability
            : AccountNature.asset);
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
            type: _selectedEnum,
            accountTypeId: _selectedTypeId,
            nature: _selectedNature,
            openingBalance: balance,
          );
    } else {
      success = await ref
          .read(accountControllerProvider.notifier)
          .createAccount(
            name: name,
            type: _selectedEnum,
            accountTypeId: _selectedTypeId,
            nature: _selectedNature,
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
    final accountTypesAsync = ref.watch(accountTypesStreamProvider);

    return AlertDialog(
      title: Text(isEditing ? 'Edit Account' : 'Add Account'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
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
                Builder(
                  builder: (context) {
                    final typeDefs =
                        accountTypesAsync.value ??
                        AccountTypeDefinition.defaultTypes;
                    final activeDefs = typeDefs.where((t) => t.active).toList();
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: activeDefs.map((tDef) {
                        final selected = _selectedTypeId == tDef.id;
                        return ChoiceChip(
                          label: Text(tDef.name),
                          avatar: Icon(
                            tDef.icon,
                            size: 18,
                            color: selected ? Colors.white : tDef.color,
                          ),
                          selected: selected,
                          selectedColor: tDef.color,
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
                                      _selectedTypeId = tDef.id;
                                      _selectedEnum = AccountTypeX.fromString(
                                        tDef.id,
                                      );
                                      _selectedNature = tDef.nature;
                                    });
                                  }
                                },
                        );
                      }).toList(),
                    );
                  },
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
              : Text(isEditing ? 'Save Changes' : 'Save Account'),
        ),
      ],
    );
  }
}
