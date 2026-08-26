import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/core/widgets/responsive_center.dart';

import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/smart_entry/domain/models/parsed_draft_transaction.dart';
import 'package:personal_financial_assistant/features/smart_entry/presentation/providers/smart_entry_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class SmartEntryScreen extends ConsumerStatefulWidget {
  const SmartEntryScreen({super.key});

  @override
  ConsumerState<SmartEntryScreen> createState() => _SmartEntryScreenState();
}

class _SmartEntryScreenState extends ConsumerState<SmartEntryScreen> {
  late final TextEditingController _textController;

  static const List<String> _samplePrompts = [
    'Paid 450 for lunch on HDFC card yesterday',
    'Salary 80000 every month to HDFC',
    'Rent 15000 every month',
    'Insurance 20000 every year',
    'Electricity 2000 every 2 months',
    'Bought groceries 1400 cash',
    'Transferred 5000 from SBI to HDFC',
  ];

  @override
  void initState() {
    super.initState();
    final initialText = ref.read(smartEntryControllerProvider).rawInput;
    _textController = TextEditingController(text: initialText);
    _textController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _triggerParse() {
    final text = _textController.text;
    ref.read(smartEntryControllerProvider.notifier).setInput(text);

    final accounts = ref.read(accountsStreamProvider).value ?? [];
    final categories =
        ref.read(categoriesStreamProvider).value ??
        Category.generateDefaults('default');

    ref.read(smartEntryControllerProvider.notifier).parse(accounts, categories);
  }

  Future<void> _recordAll() async {
    final messenger = ScaffoldMessenger.of(context);
    final count = ref.read(smartEntryControllerProvider).drafts.length;

    final success = await ref
        .read(smartEntryControllerProvider.notifier)
        .saveAll(ref);

    if (mounted && success) {
      _textController.clear();
      messenger.showSnackBar(
        SnackBar(
          content: Text('$count transaction(s) recorded successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _recordSingle(int index) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await ref
        .read(smartEntryControllerProvider.notifier)
        .saveSingle(index, ref);

    if (mounted && success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Transaction recorded successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartEntryControllerProvider);
    final accounts = ref.watch(accountsStreamProvider).value ?? [];
    final categories =
        ref.watch(categoriesStreamProvider).value ??
        Category.generateDefaults('default');

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Financial Assistant'),
        actions: [
          if (state.drafts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all_rounded),
              tooltip: 'Clear All',
              onPressed: () {
                _textController.clear();
                ref.read(smartEntryControllerProvider.notifier).clearAll();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: ResponsiveCenter(
          maxWidth: 800,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Smart Assistant Entry',
                subtitle: 'Type or paste free-form notes. The assistant automatically detects amounts, categories, accounts, and types.',
                action: FilledButton.tonalIcon(
                  onPressed: () => context.push('/financial-setup'),
                  icon: const Icon(Icons.psychology_alt_rounded, size: 18),
                  label: const Text('Full Financial Setup'),
                ),
              ),

              // Sample Prompt Chips
              Text(
                'Quick Examples (tap to test)',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _samplePrompts.map((prompt) {
                  return ActionChip(
                    avatar: const Icon(Icons.auto_awesome_outlined, size: 14),
                    label: Text(prompt, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      _textController.text = prompt;
                      _triggerParse();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Free-form Editor Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _textController,
                        maxLines: 4,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty && !state.isParsing) {
                            _triggerParse();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter one or multiple lines, e.g.:\n• Lunch 350 at cafe yesterday\n• Salary 80000 into SBI\n• Transferred 2000 from SBI to HDFC\n• Bought groceries 850 cash',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 1.8,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLowest,
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: 13,
                          ),
                        ),
                        onChanged: (val) {
                          ref
                              .read(smartEntryControllerProvider.notifier)
                              .setInput(val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (_textController.text.isNotEmpty)
                            TextButton.icon(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              label: const Text('Clear'),
                              onPressed: state.isParsing
                                  ? null
                                  : () {
                                      _textController.clear();
                                      ref
                                          .read(
                                            smartEntryControllerProvider
                                                .notifier,
                                          )
                                          .clearAll();
                                    },
                            )
                          else
                            const SizedBox.shrink(),
                          FilledButton.icon(
                            onPressed:
                                _textController.text.trim().isEmpty ||
                                    state.isParsing
                                ? null
                                : _triggerParse,
                            icon: state.isParsing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 18,
                                  ),
                            label: Text(
                              state.isParsing
                                  ? 'Understanding...'
                                  : 'Understand',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Draft Review Section
              if (state.drafts.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Detected Transactions (${state.drafts.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: state.isSaving ? null : _recordAll,
                      icon: state.isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.done_all_rounded, size: 18),
                      label: Text(
                        'Confirm & Save All (${state.drafts.length})',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.drafts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final draft = state.drafts[index];
                    return _DraftTransactionCard(
                      draft: draft,
                      accounts: accounts,
                      categories: categories,
                      isSaving: state.isSaving,
                      onUpdate: (updated) {
                        ref
                            .read(smartEntryControllerProvider.notifier)
                            .updateDraft(index, updated);
                      },
                      onDelete: () {
                        ref
                            .read(smartEntryControllerProvider.notifier)
                            .removeDraft(index);
                      },
                      onSave: () => _recordSingle(index),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftTransactionCard extends StatelessWidget {
  final ParsedDraftTransaction draft;
  final List<Account> accounts;
  final List<Category> categories;
  final bool isSaving;
  final ValueChanged<ParsedDraftTransaction> onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onSave;

  const _DraftTransactionCard({
    required this.draft,
    required this.accounts,
    required this.categories,
    required this.isSaving,
    required this.onUpdate,
    required this.onDelete,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTransfer = draft.type == TransactionType.transfer;
    final isIncome = draft.type == TransactionType.income;

    final targetCatType = isIncome ? CategoryType.income : CategoryType.expense;
    final filteredCategories = categories
        .where((c) => c.type == targetCatType && c.active)
        .toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: (draft.isRecurring ? Colors.purple : draft.type.color)
              .withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Type Badge + Amount + Delete button
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (draft.isRecurring ? Colors.purple : draft.type.color)
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        draft.isRecurring
                            ? Icons.repeat_rounded
                            : draft.type.icon,
                        size: 14,
                        color: draft.isRecurring
                            ? Colors.purple
                            : draft.type.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        draft.isRecurring
                            ? 'RECURRING ${draft.type.displayName.toUpperCase()}'
                            : draft.type.displayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: draft.isRecurring
                              ? Colors.purple
                              : draft.type.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹ ${draft.amount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: draft.isRecurring
                            ? Colors.purple
                            : draft.type.color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: 'Remove',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Raw input hint
            Text(
              '"${draft.rawText}"',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // Mode Selector: One-time vs Recurring
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('One-time'),
                    icon: Icon(Icons.flash_on_rounded, size: 16),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Recurring'),
                    icon: Icon(Icons.repeat_rounded, size: 16),
                  ),
                ],
                selected: {draft.isRecurring},
                onSelectionChanged: (Set<bool> newSelection) {
                  final isRec = newSelection.first;
                  onUpdate(
                    draft.copyWith(
                      isRecurring: isRec,
                      frequency: isRec
                          ? (draft.frequency ?? RecurrenceFrequency.monthly)
                          : null,
                      interval: isRec ? draft.interval : 1,
                      startDate: isRec
                          ? (draft.startDate ?? DateTime.now())
                          : null,
                      ruleName: isRec ? (draft.ruleName ?? draft.note) : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Editable Form Fields (Grid)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Category (if not transfer)
                if (!isTransfer)
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue:
                          filteredCategories.any(
                            (c) => c.id == draft.categoryId,
                          )
                          ? draft.categoryId
                          : (filteredCategories.isNotEmpty
                                ? filteredCategories.first.id
                                : null),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: filteredCategories.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          onUpdate(draft.copyWith(categoryId: val));
                        }
                      },
                    ),
                  ),

                // Account (if not transfer)
                if (!isTransfer)
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: accounts.any((a) => a.id == draft.accountId)
                          ? draft.accountId
                          : (accounts.isNotEmpty ? accounts.first.id : null),
                      decoration: const InputDecoration(
                        labelText: 'Account',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: accounts.map((a) {
                        return DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          onUpdate(draft.copyWith(accountId: val));
                        }
                      },
                    ),
                  ),

                // Transfer From Account
                if (isTransfer)
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue:
                          accounts.any((a) => a.id == draft.fromAccountId)
                          ? draft.fromAccountId
                          : (accounts.isNotEmpty ? accounts.first.id : null),
                      decoration: const InputDecoration(
                        labelText: 'From Account',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: accounts.map((a) {
                        return DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          onUpdate(draft.copyWith(fromAccountId: val));
                        }
                      },
                    ),
                  ),

                // Transfer To Account
                if (isTransfer)
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue:
                          accounts.any((a) => a.id == draft.toAccountId)
                          ? draft.toAccountId
                          : (accounts.length > 1 ? accounts[1].id : null),
                      decoration: const InputDecoration(
                        labelText: 'To Account',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: accounts.map((a) {
                        return DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          onUpdate(draft.copyWith(toAccountId: val));
                        }
                      },
                    ),
                  ),

                // Recurring Fields: Frequency & Interval
                if (draft.isRecurring) ...[
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<RecurrenceFrequency>(
                      isExpanded: true,
                      initialValue:
                          draft.frequency ?? RecurrenceFrequency.monthly,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: RecurrenceFrequency.values.map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Text(f.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          onUpdate(draft.copyWith(frequency: val));
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: TextFormField(
                      initialValue: draft.interval.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Interval',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val.trim());
                        if (parsed != null && parsed > 0) {
                          onUpdate(draft.copyWith(interval: parsed));
                        }
                      },
                    ),
                  ),
                  if (draft.frequency != RecurrenceFrequency.weekly)
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue:
                            draft.dayOfMonth ??
                            (draft.startDate?.day ?? DateTime.now().day),
                        decoration: const InputDecoration(
                          labelText: 'Day of Month',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: List.generate(31, (i) => i + 1).map((d) {
                          return DropdownMenuItem(
                            value: d,
                            child: Text('Day $d'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            onUpdate(draft.copyWith(dayOfMonth: val));
                          }
                        },
                      ),
                    ),
                  if (draft.frequency == RecurrenceFrequency.weekly)
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue:
                            draft.dayOfWeek ??
                            (draft.startDate?.weekday ??
                                DateTime.now().weekday),
                        decoration: const InputDecoration(
                          labelText: 'Day of Week',
                          border: OutlineInputBorder(),
                          isDense: true,
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
                        onChanged: (val) {
                          if (val != null) {
                            onUpdate(draft.copyWith(dayOfWeek: val));
                          }
                        },
                      ),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.calendar_today_outlined, size: 14),
                    label: Text(
                      'Start: ${DateFormat('MMM dd, yyyy').format(draft.startDate ?? draft.date)}',
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: draft.startDate ?? draft.date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2040),
                      );
                      if (picked != null) {
                        onUpdate(draft.copyWith(startDate: picked));
                      }
                    },
                  ),
                ],

                // One-Time Date Chip Button
                if (!draft.isRecurring)
                  ActionChip(
                    avatar: const Icon(Icons.calendar_today_outlined, size: 14),
                    label: Text(DateFormat('MMM dd, yyyy').format(draft.date)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: draft.date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        onUpdate(draft.copyWith(date: picked));
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Note / Rule Name line
            TextFormField(
              initialValue: draft.isRecurring
                  ? (draft.ruleName ?? draft.note)
                  : draft.note,
              decoration: InputDecoration(
                labelText: draft.isRecurring
                    ? 'Rule Name / Description'
                    : 'Note / Description',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (val) {
                if (draft.isRecurring) {
                  onUpdate(draft.copyWith(ruleName: val, note: val));
                } else {
                  onUpdate(draft.copyWith(note: val));
                }
              },
            ),
            const SizedBox(height: 12),

            // Action Save Single Button
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: Text(
                  draft.isRecurring ? 'Confirm & Save Rule' : 'Confirm & Save',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
