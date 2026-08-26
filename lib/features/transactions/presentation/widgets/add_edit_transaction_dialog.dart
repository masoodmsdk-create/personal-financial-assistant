import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class AddEditTransactionDialog extends ConsumerStatefulWidget {
  final Transaction? transaction;
  final bool initialIsRecurring;

  const AddEditTransactionDialog({
    super.key,
    this.transaction,
    this.initialIsRecurring = false,
  });

  @override
  ConsumerState<AddEditTransactionDialog> createState() =>
      _AddEditTransactionDialogState();
}

class _AddEditTransactionDialogState
    extends ConsumerState<AddEditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();

  late bool _isRecurring;
  late TransactionType _selectedType;
  late final TextEditingController _amountController;
  late final TextEditingController _nameController;
  late final TextEditingController _intervalController;
  late final TextEditingController _noteController;

  late DateTime _selectedDate;
  late DateTime _startDate;
  DateTime? _endDate;

  String? _selectedAccountId;
  String? _selectedCategoryId;
  String? _selectedFromAccountId;
  String? _selectedToAccountId;

  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  int? _dayOfMonth;
  int? _dayOfWeek;

  bool _isSavingRecurring = false;

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _isRecurring = widget.initialIsRecurring;
    _selectedType = t?.type ?? TransactionType.expense;
    _amountController = TextEditingController(
      text: t != null ? t.amount.toStringAsFixed(2) : '',
    );
    _nameController = TextEditingController();
    _intervalController = TextEditingController(text: '1');
    _noteController = TextEditingController(text: t?.note ?? '');
    _selectedDate = t?.date ?? DateTime.now();
    _startDate = DateTime.now();
    _dayOfMonth = _startDate.day;
    _dayOfWeek = _startDate.weekday;

    _selectedAccountId = t?.accountId;
    _selectedCategoryId = t?.categoryId;
    _selectedFromAccountId = t?.fromAccountId;
    _selectedToAccountId = t?.toAccountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _intervalController.dispose();
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
        if (_frequency == RecurrenceFrequency.monthly ||
            _frequency == RecurrenceFrequency.quarterly ||
            _frequency == RecurrenceFrequency.halfYearly ||
            _frequency == RecurrenceFrequency.yearly) {
          _dayOfMonth = picked.day;
        } else if (_frequency == RecurrenceFrequency.weekly) {
          _dayOfWeek = picked.weekday;
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

  Future<void> _saveOneTime() async {
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
        Navigator.of(context).pop(true);
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

  Future<void> _saveRecurring() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    final messenger = ScaffoldMessenger.of(context);

    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please sign in first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedAccountId == null || _selectedAccountId!.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please select an account'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSavingRecurring = true);

    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '')) ??
        0.0;
    final interval = int.tryParse(_intervalController.text.trim()) ?? 1;
    final now = DateTime.now();

    final service = ref.read(recurringTransactionServiceProvider);
    final initialNext =
        service.calculateNextOccurrence(
          fromDate: _startDate.subtract(const Duration(days: 1)),
          frequency: _frequency,
          interval: interval,
          dayOfMonth: _dayOfMonth,
          dayOfWeek: _dayOfWeek,
          endDate: _endDate,
        ) ??
        _startDate;

    final ruleName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : '${_selectedType.displayName} Commitment';

    final rule = RecurringTransactionRule(
      id: now.millisecondsSinceEpoch.toString(),
      userId: user.uid,
      createdAt: now,
      updatedAt: now,
      type: _selectedType,
      name: ruleName,
      amount: amount,
      categoryId: _selectedCategoryId!,
      accountId: _selectedAccountId!,
      frequency: _frequency,
      interval: interval,
      dayOfMonth: _dayOfMonth,
      dayOfWeek: _dayOfWeek,
      startDate: _startDate,
      endDate: _endDate,
      active: true,
      autoGenerate: true,
      nextOccurrence: initialNext,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
    );

    final success = await ref
        .read(recurringTransactionControllerProvider.notifier)
        .addRule(rule);

    if (mounted) {
      setState(() => _isSavingRecurring = false);
      if (success) {
        Navigator.of(context).pop(true);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Recurring rule "$ruleName" saved successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Failed to save recurring rule'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(transactionControllerProvider);
    final isLoading = controllerState.isLoading || _isSavingRecurring;
    final isEditing = widget.transaction != null;

    final accountsAsync = ref.watch(accountsStreamProvider);
    final categoriesAsync = _selectedType == TransactionType.income
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(expenseCategoriesProvider);

    return AlertDialog(
      title: Text(
        isEditing
            ? 'Edit Transaction'
            : (_isRecurring ? 'Add Recurring Rule' : 'Record Transaction'),
      ),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. One-time vs Recurring Selector (Only when creating new)
                if (!isEditing) ...[
                  Center(
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('One-time'),
                          icon: Icon(Icons.receipt_outlined),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Recurring'),
                          icon: Icon(Icons.repeat_rounded),
                        ),
                      ],
                      selected: {_isRecurring},
                      onSelectionChanged: isLoading
                          ? null
                          : (Set<bool> selection) {
                              setState(() {
                                _isRecurring = selection.first;
                                if (_isRecurring &&
                                    _selectedType == TransactionType.transfer) {
                                  _selectedType = TransactionType.expense;
                                }
                              });
                            },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 2. Transaction / Commitment Type Selector
                Center(
                  child: SegmentedButton<TransactionType>(
                    segments: [
                      const ButtonSegment(
                        value: TransactionType.income,
                        label: Text('Income'),
                        icon: Icon(Icons.arrow_downward_rounded),
                      ),
                      const ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('Expense'),
                        icon: Icon(Icons.arrow_upward_rounded),
                      ),
                      if (!_isRecurring)
                        const ButtonSegment(
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
                const SizedBox(height: 16),

                // 3. Recurring Rule Name / Title
                if (_isRecurring) ...[
                  TextFormField(
                    controller: _nameController,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Rule Title / Description *',
                      hintText: 'e.g. Monthly Salary, House Rent, Netflix',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a rule title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // 4. Amount
                TextFormField(
                  controller: _amountController,
                  enabled: !isLoading,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Amount *',
                    prefixText: '₹ ',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    final parsed = double.tryParse(
                      value.trim().replaceAll(',', ''),
                    );
                    if (parsed == null || parsed <= 0) {
                      return 'Amount must be greater than zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 5. Category & Account Dropdowns (for Income / Expense / Recurring)
                if (_selectedType != TransactionType.transfer ||
                    _isRecurring) ...[
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
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: '${_selectedType.displayName} Category *',
                          prefixIcon: const Icon(Icons.category_outlined),
                        ),
                        items: activeCategories.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.name,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Account *',
                          prefixIcon: Icon(Icons.account_balance_outlined),
                        ),
                        items: activeAccounts.map((a) {
                          return DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              '${a.name} (${a.type.displayName})',
                              overflow: TextOverflow.ellipsis,
                            ),
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

                // 6. Transfer From/To Accounts (Only for One-Time Transfer)
                if (!_isRecurring &&
                    _selectedType == TransactionType.transfer) ...[
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
                          DropdownButtonFormField<String>(
                            initialValue: _selectedFromAccountId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'From Account *',
                              prefixIcon: Icon(Icons.call_made_rounded),
                            ),
                            items: activeAccounts.map((a) {
                              return DropdownMenuItem(
                                value: a.id,
                                child: Text(
                                  '${a.name} (${a.type.displayName})',
                                  overflow: TextOverflow.ellipsis,
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
                          DropdownButtonFormField<String>(
                            initialValue: _selectedToAccountId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'To Account *',
                              prefixIcon: Icon(Icons.call_received_rounded),
                            ),
                            items: activeAccounts.map((a) {
                              return DropdownMenuItem(
                                value: a.id,
                                child: Text(
                                  '${a.name} (${a.type.displayName})',
                                  overflow: TextOverflow.ellipsis,
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

                // 7. Recurring Schedule Fields
                if (_isRecurring) ...[
                  // Frequency Dropdown
                  DropdownButtonFormField<RecurrenceFrequency>(
                    initialValue: _frequency,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Frequency *',
                      prefixIcon: Icon(Icons.timelapse_rounded),
                    ),
                    items: RecurrenceFrequency.values.map((f) {
                      return DropdownMenuItem(
                        value: f,
                        child: Text(
                          f.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: isLoading
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() {
                                _frequency = val;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 16),

                  // Interval TextFormField
                  TextFormField(
                    controller: _intervalController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Interval',
                      hintText: '1 (Every cycle)',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                    validator: (val) {
                      final p = int.tryParse(val ?? '');
                      if (p == null || p <= 0) return 'Must be >= 1';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Day of Month / Day of Week selector
                  if (_frequency == RecurrenceFrequency.monthly ||
                      _frequency == RecurrenceFrequency.quarterly ||
                      _frequency == RecurrenceFrequency.halfYearly ||
                      _frequency == RecurrenceFrequency.yearly) ...[
                    DropdownButtonFormField<int>(
                      initialValue: _dayOfMonth ?? _startDate.day,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Day of the Month *',
                        prefixIcon: Icon(Icons.calendar_month_rounded),
                        helperText: 'Safe handling for month-ends (e.g. 31st)',
                      ),
                      items: List.generate(31, (i) => i + 1).map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text('Day $d of month'),
                        );
                      }).toList(),
                      onChanged: isLoading
                          ? null
                          : (val) => setState(() => _dayOfMonth = val),
                    ),
                    const SizedBox(height: 16),
                  ] else if (_frequency == RecurrenceFrequency.weekly) ...[
                    DropdownButtonFormField<int>(
                      initialValue: _dayOfWeek ?? _startDate.weekday,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Day of the Week *',
                        prefixIcon: Icon(Icons.calendar_view_week_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Monday')),
                        DropdownMenuItem(value: 2, child: Text('Tuesday')),
                        DropdownMenuItem(value: 3, child: Text('Wednesday')),
                        DropdownMenuItem(value: 4, child: Text('Thursday')),
                        DropdownMenuItem(value: 5, child: Text('Friday')),
                        DropdownMenuItem(value: 6, child: Text('Saturday')),
                        DropdownMenuItem(value: 7, child: Text('Sunday')),
                      ],
                      onChanged: isLoading
                          ? null
                          : (val) => setState(() => _dayOfWeek = val),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Start Date Picker
                  InkWell(
                    onTap: isLoading ? null : _pickStartDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date *',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      child: Text(_dateFormat.format(_startDate)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Optional End Date Picker
                  InkWell(
                    onTap: isLoading ? null : _pickEndDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'End Date (Optional)',
                        prefixIcon: const Icon(Icons.event_busy_rounded),
                        suffixIcon: _endDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: isLoading
                                    ? null
                                    : () => setState(() => _endDate = null),
                              )
                            : null,
                      ),
                      child: Text(
                        _endDate != null
                            ? _dateFormat.format(_endDate!)
                            : 'No end date (Indefinite)',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 8. One-time Date Picker
                if (!_isRecurring) ...[
                  InkWell(
                    onTap: isLoading ? null : _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Transaction Date *',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      child: Text(_dateFormat.format(_selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 9. Note / Description
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
          onPressed: isLoading
              ? null
              : (_isRecurring ? _saveRecurring : _saveOneTime),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isEditing
                      ? 'Save Changes'
                      : (_isRecurring
                            ? 'Save Recurring Rule'
                            : 'Save Transaction'),
                ),
        ),
      ],
    );
  }
}
