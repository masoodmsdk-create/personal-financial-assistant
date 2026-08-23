import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/core/widgets/responsive_center.dart';

import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
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
    'Salary 75000 credited to SBI today',
    'Transferred 5000 from SBI to HDFC',
    'Bought groceries 1400 cash',
    'Electricity bill 2350 paid via ICICI',
  ];

  @override
  void initState() {
    super.initState();
    final initialText = ref.read(smartEntryControllerProvider).rawInput;
    _textController = TextEditingController(text: initialText);
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
              const PageHeader(
                title: 'Smart Assistant Entry',
                subtitle: 'Type or paste free-form notes. The assistant automatically detects amounts, categories, accounts, and types.',
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
                        decoration: InputDecoration(
                          hintText: 'Enter one or multiple lines, e.g.:\n• Lunch 350 at cafe yesterday\n• Salary 80000 into SBI\n• Transferred 2000 from SBI to HDFC\n• Bought groceries 850 cash',
                          border: InputBorder.none,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_textController.text.isNotEmpty)
                            TextButton.icon(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              label: const Text('Clear'),
                              onPressed: () {
                                _textController.clear();
                                ref
                                    .read(smartEntryControllerProvider.notifier)
                                    .clearAll();
                              },
                            ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _triggerParse,
                            icon: const Icon(Icons.auto_awesome_rounded),
                            label: const Text('Analyze & Parse'),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detected Transactions (${state.drafts.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: state.isSaving ? null : _recordAll,
                      icon: state.isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.done_all_rounded),
                      label: Text('Record All (${state.drafts.length})'),
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
          color: draft.type.color.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Type Badge + Amount + Delete button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: draft.type.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(draft.type.icon, size: 16, color: draft.type.color),
                      const SizedBox(width: 6),
                      Text(
                        draft.type.displayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: draft.type.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '₹ ${draft.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: draft.type.color,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Remove',
                  onPressed: onDelete,
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

                // Date Chip Button
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

            // Note line
            TextFormField(
              initialValue: draft.note,
              decoration: const InputDecoration(
                labelText: 'Note / Description',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (val) {
                onUpdate(draft.copyWith(note: val));
              },
            ),
            const SizedBox(height: 12),

            // Action Save Single Button
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Record Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
