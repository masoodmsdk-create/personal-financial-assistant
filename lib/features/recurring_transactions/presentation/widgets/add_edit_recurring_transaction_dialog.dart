import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class AddEditRecurringTransactionDialog extends ConsumerStatefulWidget {
  final RecurringTransactionRule? rule;
  final TransactionType initialType;

  const AddEditRecurringTransactionDialog({
    super.key,
    this.rule,
    this.initialType = TransactionType.expense,
  });

  @override
  ConsumerState<AddEditRecurringTransactionDialog> createState() =>
      _AddEditRecurringTransactionDialogState();
}

class _AddEditRecurringTransactionDialogState
    extends ConsumerState<AddEditRecurringTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _type;
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _intervalController;
  late TextEditingController _noteController;

  String? _selectedCategoryId;
  String? _selectedAccountId;
  late RecurrenceFrequency _frequency;
  int? _dayOfMonth;
  int? _dayOfWeek;
  late DateTime _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    if (rule != null) {
      _type = rule.type;
      _nameController = TextEditingController(text: rule.name);
      _amountController = TextEditingController(
        text: rule.amount.toStringAsFixed(2),
      );
      _intervalController = TextEditingController(
        text: rule.interval.toString(),
      );
      _noteController = TextEditingController(text: rule.note ?? '');
      _selectedCategoryId = rule.categoryId;
      _selectedAccountId = rule.accountId;
      _frequency = rule.frequency;
      _dayOfMonth = rule.dayOfMonth;
      _dayOfWeek = rule.dayOfWeek;
      _startDate = rule.startDate;
      _endDate = rule.endDate;
    } else {
      _type = widget.initialType;
      _nameController = TextEditingController();
      _amountController = TextEditingController();
      _intervalController = TextEditingController(text: '1');
      _noteController = TextEditingController();
      _frequency = RecurrenceFrequency.monthly;
      _startDate = DateTime.now();
      _dayOfMonth = _startDate.day;
      _dayOfWeek = _startDate.weekday;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _intervalController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please log in first')));
      return;
    }

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    if (_selectedAccountId == null || _selectedAccountId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an account')));
      return;
    }

    setState(() => _isLoading = true);

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
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

    final rule = RecurringTransactionRule(
      id: widget.rule?.id ?? now.millisecondsSinceEpoch.toString(),
      userId: user.uid,
      createdAt: widget.rule?.createdAt ?? now,
      updatedAt: now,
      type: _type,
      name: _nameController.text.trim(),
      amount: amount,
      categoryId: _selectedCategoryId!,
      accountId: _selectedAccountId!,
      frequency: _frequency,
      interval: interval,
      dayOfMonth: _dayOfMonth,
      dayOfWeek: _dayOfWeek,
      startDate: _startDate,
      endDate: _endDate,
      active: widget.rule?.active ?? true,
      lastGeneratedDate: widget.rule?.lastGeneratedDate,
      nextOccurrence: widget.rule?.nextOccurrence ?? initialNext,
      autoGenerate: true,
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
    );

    final success = widget.rule == null
        ? await ref
              .read(recurringTransactionControllerProvider.notifier)
              .addRule(rule)
        : await ref
              .read(recurringTransactionControllerProvider.notifier)
              .updateRule(rule);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.rule == null
                  ? 'Recurring rule created successfully'
                  : 'Recurring rule updated',
            ),
            backgroundColor: Colors.green[700],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to save recurring rule. Please check inputs.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.rule != null;

    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final accountsAsync = ref.watch(accountsStreamProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.repeat_rounded,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEditing
                            ? 'Edit Recurring Rule'
                            : 'New Recurring Transaction',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Type Segmented Switch (Income vs Expense)
                        SegmentedButton<TransactionType>(
                          segments: const [
                            ButtonSegment(
                              value: TransactionType.income,
                              label: Text('Income (e.g. Salary)'),
                              icon: Icon(
                                Icons.arrow_downward,
                                color: Colors.green,
                              ),
                            ),
                            ButtonSegment(
                              value: TransactionType.expense,
                              label: Text('Expense (e.g. Rent)'),
                              icon: Icon(Icons.arrow_upward, color: Colors.red),
                            ),
                          ],
                          selected: {_type},
                          onSelectionChanged: (selected) {
                            setState(() {
                              _type = selected.first;
                              _selectedCategoryId = null;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Name
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: _type == TransactionType.income
                                ? 'Rule Name (e.g. Monthly Salary)'
                                : 'Rule Name (e.g. Apartment Rent, Netflix)',
                            prefixIcon: const Icon(Icons.title_rounded),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter a name';
                            }
                            if (val.trim().length > 60) {
                              return 'Name cannot exceed 60 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Amount
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Amount (₹)',
                            prefixIcon: Icon(Icons.currency_rupee_rounded),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter amount';
                            }
                            final parsed = double.tryParse(
                              val.replaceAll(',', ''),
                            );
                            if (parsed == null || parsed <= 0) {
                              return 'Amount must be greater than 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Category Dropdown
                        categoriesAsync.when(
                          data: (categories) {
                            final filtered = categories
                                .where(
                                  (c) => _type == TransactionType.income
                                      ? c.type == CategoryType.income
                                      : c.type == CategoryType.expense,
                                )
                                .toList();
                            final items = filtered.isNotEmpty
                                ? filtered
                                : Category.generateDefaults('temp')
                                      .where(
                                        (c) => _type == TransactionType.income
                                            ? c.type == CategoryType.income
                                            : c.type == CategoryType.expense,
                                      )
                                      .toList();

                            if (_selectedCategoryId == null &&
                                items.isNotEmpty) {
                              _selectedCategoryId = items.first.id;
                            }

                            return DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue:
                                  items.any((c) => c.id == _selectedCategoryId)
                                  ? _selectedCategoryId
                                  : (items.isNotEmpty ? items.first.id : null),
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category_outlined),
                                border: OutlineInputBorder(),
                              ),
                              items: items.map((c) {
                                return DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    c.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedCategoryId = val),
                              validator: (val) =>
                                  val == null ? 'Please select category' : null,
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 12),

                        // Account Dropdown
                        accountsAsync.when(
                          data: (accounts) {
                            final validAccounts = accounts;
                            if (_selectedAccountId == null &&
                                validAccounts.isNotEmpty) {
                              _selectedAccountId = validAccounts.first.id;
                            }

                            return DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue:
                                  validAccounts.any(
                                    (a) => a.id == _selectedAccountId,
                                  )
                                  ? _selectedAccountId
                                  : (validAccounts.isNotEmpty
                                        ? validAccounts.first.id
                                        : null),
                              decoration: const InputDecoration(
                                labelText: 'Account',
                                prefixIcon: Icon(
                                  Icons.account_balance_outlined,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              items: validAccounts.map((a) {
                                return DropdownMenuItem(
                                  value: a.id,
                                  child: Text(
                                    a.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedAccountId = val),
                              validator: (val) =>
                                  val == null ? 'Please select account' : null,
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 16),

                        // Recurrence Settings Header
                        Text(
                          'Recurrence Schedule',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Frequency and Interval Row
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child:
                                  DropdownButtonFormField<RecurrenceFrequency>(
                                    isExpanded: true,
                                    initialValue: _frequency,
                                    decoration: const InputDecoration(
                                      labelText: 'Frequency',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: RecurrenceFrequency.daily,
                                        child: Text(
                                          'Daily',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: RecurrenceFrequency.weekly,
                                        child: Text(
                                          'Weekly',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: RecurrenceFrequency.monthly,
                                        child: Text(
                                          'Monthly',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: RecurrenceFrequency.quarterly,
                                        child: Text(
                                          'Quarterly (3 Mo)',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: RecurrenceFrequency.halfYearly,
                                        child: Text(
                                          'Half-Yearly',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: RecurrenceFrequency.yearly,
                                        child: Text(
                                          'Yearly',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _frequency = val);
                                      }
                                    },
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _intervalController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Interval',
                                  helperText: 'Every N...',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) {
                                  final num = int.tryParse(val ?? '');
                                  if (num == null || num < 1) return 'Min 1';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Day of Month or Day of Week selector
                        if (_frequency == RecurrenceFrequency.monthly ||
                            _frequency == RecurrenceFrequency.quarterly ||
                            _frequency == RecurrenceFrequency.halfYearly ||
                            _frequency == RecurrenceFrequency.yearly) ...[
                          DropdownButtonFormField<int>(
                            isExpanded: true,
                            initialValue: _dayOfMonth ?? 1,
                            decoration: const InputDecoration(
                              labelText: 'Day of Month',
                              helperText:
                                  'Handles month-end dates safely (e.g. 31st)',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(31, (i) => i + 1).map((d) {
                              return DropdownMenuItem(
                                value: d,
                                child: Text('Day $d of month'),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _dayOfMonth = val),
                          ),
                          const SizedBox(height: 12),
                        ] else if (_frequency ==
                            RecurrenceFrequency.weekly) ...[
                          DropdownButtonFormField<int>(
                            isExpanded: true,
                            initialValue: _dayOfWeek ?? 1,
                            decoration: const InputDecoration(
                              labelText: 'Day of Week',
                              prefixIcon: Icon(Icons.calendar_view_week),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('Monday')),
                              DropdownMenuItem(
                                value: 2,
                                child: Text('Tuesday'),
                              ),
                              DropdownMenuItem(
                                value: 3,
                                child: Text('Wednesday'),
                              ),
                              DropdownMenuItem(
                                value: 4,
                                child: Text('Thursday'),
                              ),
                              DropdownMenuItem(value: 5, child: Text('Friday')),
                              DropdownMenuItem(
                                value: 6,
                                child: Text('Saturday'),
                              ),
                              DropdownMenuItem(value: 7, child: Text('Sunday')),
                            ],
                            onChanged: (val) =>
                                setState(() => _dayOfWeek = val),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Start Date and Optional End Date
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2040),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _startDate = picked;
                                      _dayOfMonth = picked.day;
                                      _dayOfWeek = picked.weekday;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.event, size: 16),
                                label: Text(
                                  'Start: ${DateFormat('dd MMM yyyy').format(_startDate)}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        _endDate ??
                                        _startDate.add(
                                          const Duration(days: 365),
                                        ),
                                    firstDate: _startDate,
                                    lastDate: DateTime(2040),
                                  );
                                  if (picked != null) {
                                    setState(() => _endDate = picked);
                                  }
                                },
                                icon: const Icon(Icons.event_busy, size: 16),
                                label: Text(
                                  _endDate != null
                                      ? 'End: ${DateFormat('dd MMM yyyy').format(_endDate!)}'
                                      : 'No End Date',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_endDate != null) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => setState(() => _endDate = null),
                              child: const Text('Clear End Date'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Optional Note
                        TextFormField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Notes (Optional)',
                            prefixIcon: Icon(Icons.note_alt_outlined),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Mandatory Visible Save and Cancel Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        _isLoading
                            ? 'Saving...'
                            : (isEditing
                                  ? 'Save Changes'
                                  : 'Save Recurring Rule'),
                      ),
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
