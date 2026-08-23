import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/features/accounts/domain/models/account_type_definition.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';

class AddEditAccountTypeDialog extends ConsumerStatefulWidget {
  const AddEditAccountTypeDialog({super.key});

  @override
  ConsumerState<AddEditAccountTypeDialog> createState() =>
      _AddEditAccountTypeDialogState();
}

class _AddEditAccountTypeDialogState
    extends ConsumerState<AddEditAccountTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  AccountNature _selectedNature = AccountNature.asset;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(customAccountTypeControllerProvider.notifier).resetState();
      }
    });
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final success = await ref
        .read(customAccountTypeControllerProvider.notifier)
        .createAccountType(name: name, nature: _selectedNature);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Custom Account Type "$name" created'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final state = ref.read(customAccountTypeControllerProvider);
        final error = state.error;
        final errorMessage = error is AppException
            ? error.message
            : (error?.toString() ?? 'Failed to create account type.');
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
    final controllerState = ref.watch(customAccountTypeControllerProvider);
    final isLoading = controllerState.isLoading;
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('New Custom Account Type'),
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
                  enabled: !isLoading,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Type Name',
                    hintText: 'e.g. Provident Fund, Savings Wallet',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Type name is required';
                    }
                    if (value.trim().length > 50) {
                      return 'Name cannot exceed 50 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Financial Nature',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<AccountNature>(
                  segments: const [
                    ButtonSegment<AccountNature>(
                      value: AccountNature.asset,
                      label: Text('Asset'),
                      icon: Icon(Icons.trending_up),
                    ),
                    ButtonSegment<AccountNature>(
                      value: AccountNature.liability,
                      label: Text('Liability'),
                      icon: Icon(Icons.trending_down),
                    ),
                  ],
                  selected: {_selectedNature},
                  onSelectionChanged: isLoading
                      ? null
                      : (newSelection) {
                          setState(() {
                            _selectedNature = newSelection.first;
                          });
                        },
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedNature.explanation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
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
              : const Text('Create Type'),
        ),
      ],
    );
  }
}
