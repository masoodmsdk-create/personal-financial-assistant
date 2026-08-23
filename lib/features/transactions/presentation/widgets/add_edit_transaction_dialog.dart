import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class AddEditTransactionDialog extends ConsumerStatefulWidget {
  final Transaction? transaction;

  const AddEditTransactionDialog({super.key, this.transaction});

  @override
  ConsumerState<AddEditTransactionDialog> createState() =>
      _AddEditTransactionDialogState();
}

class _AddEditTransactionDialogState
    extends ConsumerState<AddEditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _selectedType;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late DateTime _selectedDate;

  String? _selectedAccountId;
  String? _selectedCategoryId;
  String? _selectedFromAccountId;
  String? _selectedToAccountId;

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _selectedType = t?.type ?? TransactionType.expense;
    _amountController = TextEditingController(
      text: t != null ? t.amount.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: t?.note ?? '');
    _selectedDate = t?.date ?? DateTime.now();

    _selectedAccountId = t?.accountId;
    _selectedCategoryId = t?.categoryId;
    _selectedFromAccountId = t?.fromAccountId;
    _selectedToAccountId = t?.toAccountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final note = _noteController.text.trim();
    final isEditing = widget.transaction != null;

    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    bool success = false;
    final controller = ref.read(transactionControllerProvider.notifier);

    if (isEditing) {
      final updated = widget.transaction!.copyWith(
        type: _selectedType,
        amount: amount,
        accountId: _selectedType != TransactionType.transfer
            ? _selectedAccountId
            : null,
        categoryId: _selectedType != TransactionType.transfer
            ? _selectedCategoryId
            : null,
        fromAccountId: _selectedType == TransactionType.transfer
            ? _selectedFromAccountId
            : null,
        toAccountId: _selectedType == TransactionType.transfer
            ? _selectedToAccountId
            : null,
        date: _selectedDate,
        note: note.isNotEmpty ? note : null,
      );
      success = await controller.updateTransaction(updated);
    } else {
      switch (_selectedType) {
        case TransactionType.income:
          if (_selectedAccountId == null || _selectedCategoryId == null) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Please select account and category'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          success = await controller.createIncomeTransaction(
            amount: amount,
            accountId: _selectedAccountId!,
            categoryId: _selectedCategoryId!,
            date: _selectedDate,
            note: note.isNotEmpty ? note : null,
          );
          break;

        case TransactionType.expense:
          if (_selectedAccountId == null || _selectedCategoryId == null) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Please select account and category'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          success = await controller.createExpenseTransaction(
            amount: amount,
            accountId: _selectedAccountId!,
            categoryId: _selectedCategoryId!,
            date: _selectedDate,
            note: note.isNotEmpty ? note : null,
          );
          break;

        case TransactionType.transfer:
          if (_selectedFromAccountId == null || _selectedToAccountId == null) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Please select From and To accounts'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          success = await controller.createTransferTransaction(
            amount: amount,
            fromAccountId: _selectedFromAccountId!,
            toAccountId: _selectedToAccountId!,
            date: _selectedDate,
            note: note.isNotEmpty ? note : null,
          );
          break;
      }
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Transaction updated' : 'Transaction recorded',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final state = ref.read(transactionControllerProvider);
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
    final controllerState = ref.watch(transactionControllerProvider);
    final isLoading = controllerState.isLoading;
    final isEditing = widget.transaction != null;

    final accountsAsync = ref.watch(accountsStreamProvider);
    final categoriesAsync = _selectedType == TransactionType.income
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(expenseCategoriesProvider);

    return AlertDialog(
      title: Text(isEditing ? 'Edit Transaction' : 'Record Transaction'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Segmented Button Type Selector
                Center(
                  child: SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text('Income'),
                        icon: Icon(Icons.arrow_downward_rounded),
                      ),
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('Expense'),
                        icon: Icon(Icons.arrow_upward_rounded),
                      ),
                      ButtonSegment(
                        value: TransactionType.transfer,
                        label: Text('Transfer'),
                        icon: Icon(Icons.swap_horiz_rounded),
                      ),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: isLoading
                        ? null
                        : (Set<TransactionType> selection) {
                            setState(() {
                              _selectedType = selection.first;
                              _selectedCategoryId = null;
                            });
                          },
                  ),
                ),
                const SizedBox(height: 20),

                // Amount
                TextFormField(
                  controller: _amountController,
                  enabled: !isLoading,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
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

                // Fields for Income / Expense
                if (_selectedType != TransactionType.transfer) ...[
                  // Category Dropdown
                  Builder(
                    builder: (context) {
                      final isIncome = _selectedType == TransactionType.income;
                      final targetCategoryType = isIncome
                          ? CategoryType.income
                          : CategoryType.expense;
                      final fallbackCats = Category.generateDefaults('default')
                          .where((c) => c.type == targetCategoryType)
                          .toList();

                      final loadedCategories = categoriesAsync.value;
                      final categories =
                          (loadedCategories != null &&
                              loadedCategories.isNotEmpty)
                          ? loadedCategories
                          : fallbackCats;

                      final activeCategories = categories
                          .where((c) => c.active || c.id == _selectedCategoryId)
                          .toList();

                      if (_selectedCategoryId == null &&
                          activeCategories.isNotEmpty) {
                        _selectedCategoryId = activeCategories.first.id;
                      }

                      return DropdownButtonFormField<String>(
                        initialValue: _selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: '${_selectedType.displayName} Category',
                          prefixIcon: const Icon(Icons.category_outlined),
                        ),
                        items: activeCategories.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          );
                        }).toList(),
                        onChanged: (isLoading || activeCategories.isEmpty)
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

                  // Account Dropdown
                  Builder(
                    builder: (context) {
                      final accounts = accountsAsync.value ?? [];
                      final activeAccounts = accounts
                          .where((a) => a.active || a.id == _selectedAccountId)
                          .toList();

                      if (_selectedAccountId == null &&
                          activeAccounts.isNotEmpty) {
                        _selectedAccountId = activeAccounts.first.id;
                      }

                      return DropdownButtonFormField<String>(
                        initialValue: _selectedAccountId,
                        decoration: const InputDecoration(
                          labelText: 'Account',
                          prefixIcon: Icon(Icons.account_balance_outlined),
                        ),
                        items: activeAccounts.map((a) {
                          return DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.name} (${a.type.displayName})'),
                          );
                        }).toList(),
                        onChanged: (isLoading || activeAccounts.isEmpty)
                            ? null
                            : (val) {
                                setState(() {
                                  _selectedAccountId = val;
                                });
                              },
                        validator: (val) =>
                            val == null ? 'Please select an account' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Fields for Transfer
                if (_selectedType == TransactionType.transfer) ...[
                  Builder(
                    builder: (context) {
                      final accounts = accountsAsync.value ?? [];
                      final activeAccounts = accounts
                          .where(
                            (a) =>
                                a.active ||
                                a.id == _selectedFromAccountId ||
                                a.id == _selectedToAccountId,
                          )
                          .toList();

                      if (_selectedFromAccountId == null &&
                          activeAccounts.isNotEmpty) {
                        _selectedFromAccountId = activeAccounts.first.id;
                      }
                      if (_selectedToAccountId == null &&
                          activeAccounts.length > 1) {
                        _selectedToAccountId = activeAccounts[1].id;
                      }

                      return Column(
                        children: [
                          // From Account
                          DropdownButtonFormField<String>(
                            initialValue: _selectedFromAccountId,
                            decoration: const InputDecoration(
                              labelText: 'From Account',
                              prefixIcon: Icon(Icons.call_made_rounded),
                            ),
                            items: activeAccounts.map((a) {
                              return DropdownMenuItem(
                                value: a.id,
                                child: Text(
                                  '${a.name} (${a.type.displayName})',
                                ),
                              );
                            }).toList(),
                            onChanged: isLoading
                                ? null
                                : (val) {
                                    setState(() {
                                      _selectedFromAccountId = val;
                                    });
                                  },
                            validator: (val) => val == null
                                ? 'Please select From Account'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // To Account
                          DropdownButtonFormField<String>(
                            initialValue: _selectedToAccountId,
                            decoration: const InputDecoration(
                              labelText: 'To Account',
                              prefixIcon: Icon(Icons.call_received_rounded),
                            ),
                            items: activeAccounts.map((a) {
                              return DropdownMenuItem(
                                value: a.id,
                                child: Text(
                                  '${a.name} (${a.type.displayName})',
                                ),
                              );
                            }).toList(),
                            onChanged: isLoading
                                ? null
                                : (val) {
                                    setState(() {
                                      _selectedToAccountId = val;
                                    });
                                  },
                            validator: (val) {
                              if (val == null) {
                                return 'Please select To Account';
                              }
                              if (val == _selectedFromAccountId) {
                                return 'From and To accounts must be different';
                              }
                              return null;
                            },
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                ],

                // Date Picker Input Decorator
                InkWell(
                  onTap: isLoading ? null : _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Transaction Date',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                    child: Text(_dateFormat.format(_selectedDate)),
                  ),
                ),
                const SizedBox(height: 16),

                // Note
                TextFormField(
                  controller: _noteController,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Note / Description (Optional)',
                    hintText: 'e.g. Monthly salary, Lunch with team',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().length > 200) {
                      return 'Note cannot exceed 200 characters';
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
              : Text(isEditing ? 'Save Changes' : 'Record Transaction'),
        ),
      ],
    );
  }
}
