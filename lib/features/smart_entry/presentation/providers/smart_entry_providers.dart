import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
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

  Future<bool> saveAll(WidgetRef ref) async {
    if (state.drafts.isEmpty) return false;

    state = state.copyWith(isSaving: true, errorMessage: null);
    final controller = ref.read(transactionControllerProvider.notifier);

    int saved = 0;
    final remainingDrafts = <ParsedDraftTransaction>[];

    for (final draft in state.drafts) {
      bool success = false;
      if (draft.type == TransactionType.transfer) {
        if (draft.fromAccountId != null && draft.toAccountId != null) {
          success = await controller.createTransferTransaction(
            amount: draft.amount,
            fromAccountId: draft.fromAccountId!,
            toAccountId: draft.toAccountId!,
            date: draft.date,
            note: draft.note,
          );
        }
      } else if (draft.type == TransactionType.income) {
        if (draft.accountId != null && draft.categoryId != null) {
          success = await controller.createIncomeTransaction(
            amount: draft.amount,
            accountId: draft.accountId!,
            categoryId: draft.categoryId!,
            date: draft.date,
            note: draft.note,
          );
        }
      } else {
        if (draft.accountId != null && draft.categoryId != null) {
          success = await controller.createExpenseTransaction(
            amount: draft.amount,
            accountId: draft.accountId!,
            categoryId: draft.categoryId!,
            date: draft.date,
            note: draft.note,
          );
        }
      }

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
    final controller = ref.read(transactionControllerProvider.notifier);

    bool success = false;
    if (draft.type == TransactionType.transfer) {
      if (draft.fromAccountId != null && draft.toAccountId != null) {
        success = await controller.createTransferTransaction(
          amount: draft.amount,
          fromAccountId: draft.fromAccountId!,
          toAccountId: draft.toAccountId!,
          date: draft.date,
          note: draft.note,
        );
      }
    } else if (draft.type == TransactionType.income) {
      if (draft.accountId != null && draft.categoryId != null) {
        success = await controller.createIncomeTransaction(
          amount: draft.amount,
          accountId: draft.accountId!,
          categoryId: draft.categoryId!,
          date: draft.date,
          note: draft.note,
        );
      }
    } else {
      if (draft.accountId != null && draft.categoryId != null) {
        success = await controller.createExpenseTransaction(
          amount: draft.amount,
          accountId: draft.accountId!,
          categoryId: draft.categoryId!,
          date: draft.date,
          note: draft.note,
        );
      }
    }

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
