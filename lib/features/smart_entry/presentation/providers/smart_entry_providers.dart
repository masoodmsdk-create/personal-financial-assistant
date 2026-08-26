import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/smart_entry/domain/models/parsed_draft_transaction.dart';
import 'package:personal_financial_assistant/features/smart_entry/domain/services/smart_parser_service.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

final smartParserServiceProvider = Provider<SmartParserService>((ref) {
  return const SmartParserService();
});

class SmartEntryState {
  final String rawInput;
  final List<ParsedDraftTransaction> drafts;
  final bool isParsing;
  final bool isSaving;
  final String? errorMessage;
  final int savedCount;

  const SmartEntryState({
    this.rawInput = '',
    this.drafts = const [],
    this.isParsing = false,
    this.isSaving = false,
    this.errorMessage,
    this.savedCount = 0,
  });

  SmartEntryState copyWith({
    String? rawInput,
    List<ParsedDraftTransaction>? drafts,
    bool? isParsing,
    bool? isSaving,
    String? errorMessage,
    int? savedCount,
  }) {
    return SmartEntryState(
      rawInput: rawInput ?? this.rawInput,
      drafts: drafts ?? this.drafts,
      isParsing: isParsing ?? this.isParsing,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      savedCount: savedCount ?? this.savedCount,
    );
  }
}

class SmartEntryController extends StateNotifier<SmartEntryState> {
  final SmartParserService _parserService;

  SmartEntryController(this._parserService) : super(const SmartEntryState());

  void setInput(String text) {
    state = state.copyWith(rawInput: text);
  }

  Future<void> parse(List<Account> accounts, List<Category> categories) async {
    if (state.rawInput.trim().isEmpty) {
      state = state.copyWith(
        drafts: [],
        errorMessage: 'Please enter details about your transaction first.',
        isParsing: false,
      );
      return;
    }

    state = state.copyWith(isParsing: true, errorMessage: null);

    // Brief async yield for smooth UI feedback
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final parsed = _parserService.parseText(
      rawText: state.rawInput,
      accounts: accounts,
      categories: categories,
    );

    state = state.copyWith(
      isParsing: false,
      drafts: parsed,
      errorMessage: parsed.isEmpty
          ? 'No transactions could be detected. Please include an amount (e.g. "Lunch 450").'
          : null,
    );
  }

  void updateDraft(int index, ParsedDraftTransaction updated) {
    if (index < 0 || index >= state.drafts.length) return;
    final updatedList = List<ParsedDraftTransaction>.from(state.drafts);
    updatedList[index] = updated;
    state = state.copyWith(drafts: updatedList);
  }

  void removeDraft(int index) {
    if (index < 0 || index >= state.drafts.length) return;
    final updatedList = List<ParsedDraftTransaction>.from(state.drafts)
      ..removeAt(index);
    state = state.copyWith(drafts: updatedList);
  }

  void clearAll() {
    state = const SmartEntryState();
  }

  Future<bool> _saveDraftItem(
    ParsedDraftTransaction draft,
    WidgetRef ref,
  ) async {
    if (draft.isRecurring) {
      if (draft.accountId == null || draft.categoryId == null) {
        return false;
      }
      final user = ref.read(currentUserProvider);
      if (user == null) return false;

      final now = DateTime.now();
      final startDate = draft.startDate ?? now;
      final frequency = draft.frequency ?? RecurrenceFrequency.monthly;
      final interval = draft.interval;
      final dayOfMonth =
          draft.dayOfMonth ??
          (frequency == RecurrenceFrequency.weekly ? null : startDate.day);
      final dayOfWeek =
          draft.dayOfWeek ??
          (frequency == RecurrenceFrequency.weekly ? startDate.weekday : null);

      final service = ref.read(recurringTransactionServiceProvider);
      final initialNext =
          service.calculateNextOccurrence(
            fromDate: startDate.subtract(const Duration(days: 1)),
            frequency: frequency,
            interval: interval,
            dayOfMonth: dayOfMonth,
            dayOfWeek: dayOfWeek,
            endDate: draft.endDate,
          ) ??
          startDate;

      final ruleName =
          (draft.ruleName != null && draft.ruleName!.trim().isNotEmpty)
          ? draft.ruleName!.trim()
          : (draft.note.trim().isNotEmpty
                ? draft.note.trim()
                : '${draft.type.displayName} Commitment');

      final rule = RecurringTransactionRule(
        id: now.millisecondsSinceEpoch.toString(),
        userId: user.uid,
        createdAt: now,
        updatedAt: now,
        type: draft.type,
        name: ruleName,
        amount: draft.amount,
        categoryId: draft.categoryId!,
        accountId: draft.accountId!,
        frequency: frequency,
        interval: interval,
        dayOfMonth: dayOfMonth,
        dayOfWeek: dayOfWeek,
        startDate: startDate,
        endDate: draft.endDate,
        active: true,
        autoGenerate: true,
        nextOccurrence: initialNext,
        note: draft.note.trim().isNotEmpty ? draft.note.trim() : null,
      );

      return ref
          .read(recurringTransactionControllerProvider.notifier)
          .addRule(rule);
    } else {
      final controller = ref.read(transactionControllerProvider.notifier);
      if (draft.type == TransactionType.transfer) {
        if (draft.fromAccountId != null && draft.toAccountId != null) {
          return controller.createTransferTransaction(
            amount: draft.amount,
            fromAccountId: draft.fromAccountId!,
            toAccountId: draft.toAccountId!,
            date: draft.date,
            note: draft.note,
          );
        }
      } else if (draft.type == TransactionType.income) {
        if (draft.accountId != null && draft.categoryId != null) {
          return controller.createIncomeTransaction(
            amount: draft.amount,
            accountId: draft.accountId!,
            categoryId: draft.categoryId!,
            date: draft.date,
            note: draft.note,
          );
        }
      } else {
        if (draft.accountId != null && draft.categoryId != null) {
          return controller.createExpenseTransaction(
            amount: draft.amount,
            accountId: draft.accountId!,
            categoryId: draft.categoryId!,
            date: draft.date,
            note: draft.note,
          );
        }
      }
      return false;
    }
  }

  Future<bool> saveAll(WidgetRef ref) async {
    if (state.drafts.isEmpty) return false;

    state = state.copyWith(isSaving: true, errorMessage: null);

    int saved = 0;
    final remainingDrafts = <ParsedDraftTransaction>[];

    for (final draft in state.drafts) {
      final success = await _saveDraftItem(draft, ref);
      if (success) {
        saved++;
      } else {
        remainingDrafts.add(draft);
      }
    }

    state = state.copyWith(
      isSaving: false,
      drafts: remainingDrafts,
      savedCount: saved,
      rawInput: remainingDrafts.isEmpty ? '' : state.rawInput,
    );

    return saved > 0;
  }

  Future<bool> saveSingle(int index, WidgetRef ref) async {
    if (index < 0 || index >= state.drafts.length) return false;
    final draft = state.drafts[index];

    state = state.copyWith(isSaving: true, errorMessage: null);
    final success = await _saveDraftItem(draft, ref);

    if (success) {
      final updatedList = List<ParsedDraftTransaction>.from(state.drafts)
        ..removeAt(index);
      state = state.copyWith(
        isSaving: false,
        drafts: updatedList,
        savedCount: state.savedCount + 1,
      );
      return true;
    } else {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }
}

final smartEntryControllerProvider =
    StateNotifierProvider<SmartEntryController, SmartEntryState>((ref) {
      final parser = ref.watch(smartParserServiceProvider);
      return SmartEntryController(parser);
    });
