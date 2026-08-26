import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/models/financial_blueprint.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/services/blueprint_persistence_service.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/services/financial_situation_parser.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';

final financialSituationParserProvider = Provider<FinancialSituationParser>((
  ref,
) {
  return const FinancialSituationParser();
});

final blueprintPersistenceServiceProvider =
    Provider<BlueprintPersistenceService>((ref) {
      return BlueprintPersistenceService(
        plannedExpenseRepo: ref.watch(plannedExpenseRepositoryProvider),
        loanRepo: ref.watch(loanRepositoryProvider),
        accountRepo: ref.watch(accountRepositoryProvider),
        goalRepo: ref.watch(goalRepositoryProvider),
        transactionRepo: ref.watch(transactionRepositoryProvider),
        recurringRepo: ref.watch(recurringTransactionRepositoryProvider),
      );
    });

class BlueprintState {
  final String rawInput;
  final FinancialBlueprint? blueprint;
  final bool isParsing;
  final bool isPersisting;
  final BlueprintPersistenceResult? persistenceResult;
  final int activeQuestionIndex;
  final String? errorMessage;
  final bool isConfirmed;

  const BlueprintState({
    this.rawInput = '',
    this.blueprint,
    this.isParsing = false,
    this.isPersisting = false,
    this.persistenceResult,
    this.activeQuestionIndex = 0,
    this.errorMessage,
    this.isConfirmed = false,
  });

  BlueprintState copyWith({
    String? rawInput,
    FinancialBlueprint? blueprint,
    bool? isParsing,
    bool? isPersisting,
    BlueprintPersistenceResult? persistenceResult,
    int? activeQuestionIndex,
    String? errorMessage,
    bool? isConfirmed,
  }) {
    return BlueprintState(
      rawInput: rawInput ?? this.rawInput,
      blueprint: blueprint ?? this.blueprint,
      isParsing: isParsing ?? this.isParsing,
      isPersisting: isPersisting ?? this.isPersisting,
      persistenceResult: persistenceResult ?? this.persistenceResult,
      activeQuestionIndex: activeQuestionIndex ?? this.activeQuestionIndex,
      errorMessage: errorMessage,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }
}

class BlueprintController extends StateNotifier<BlueprintState> {
  final FinancialSituationParser _parser;
  final BlueprintPersistenceService _persistenceService;

  BlueprintController(this._parser, this._persistenceService)
    : super(const BlueprintState());

  void setInput(String text) {
    state = state.copyWith(rawInput: text);
  }

  void parseSituation({
    required List<Account> accounts,
    required List<Category> categories,
    List<Loan> existingLoans = const [],
    List<Goal> existingGoals = const [],
    String? workspaceContext,
  }) {
    if (state.rawInput.trim().isEmpty) {
      state = state.copyWith(
        blueprint: null,
        errorMessage: 'Please enter your financial information above.',
      );
      return;
    }

    state = state.copyWith(isParsing: true, errorMessage: null);

    final result = _parser.parseSituation(
      rawText: state.rawInput,
      workspaceContext: workspaceContext,
      accounts: accounts,
      categories: categories,
      existingLoans: existingLoans,
      existingGoals: existingGoals,
    );

    state = state.copyWith(
      blueprint: result,
      isParsing: false,
      activeQuestionIndex: 0,
      isConfirmed: false,
      persistenceResult: null,
      errorMessage: result.totalEntitiesCount == 0
          ? 'Could not extract financial entities. Try mentioning salary, rent, EMI, or savings.'
          : null,
    );
  }

  void answerClarification({
    required String questionId,
    required String optionId,
  }) {
    final bp = state.blueprint;
    if (bp == null) return;

    final questionIndex = bp.clarifications.indexWhere(
      (q) => q.id == questionId,
    );
    if (questionIndex == -1) return;

    final question = bp.clarifications[questionIndex];
    final updatedQuestions = List<ClarificationQuestion>.from(
      bp.clarifications,
    );
    updatedQuestions[questionIndex] = question.copyWith(
      selectedOptionId: optionId,
    );

    // Reactively update the affected Blueprint item
    final targetItemId = question.targetItemId;

    var updatedIncomes = List<BlueprintIncomeItem>.from(bp.incomes);
    var updatedLoans = List<BlueprintLoanItem>.from(bp.loans);
    var updatedExpenses = List<BlueprintExpenseItem>.from(bp.recurringExpenses);
    var updatedSavings = List<BlueprintSavingsItem>.from(bp.savings);
    var updatedGoals = List<BlueprintGoalItem>.from(bp.goals);
    var updatedTransactions = List<BlueprintTransactionItem>.from(
      bp.transactions,
    );

    // Check if target item is in Loans
    final loanIdx = updatedLoans.indexWhere((l) => l.id == targetItemId);
    if (loanIdx != -1) {
      final loanItem = updatedLoans[loanIdx];
      if (optionId == 'actual_payment') {
        // Move to Transactions
        updatedLoans.removeAt(loanIdx);
        updatedTransactions.add(
          BlueprintTransactionItem(
            id: loanItem.id,
            type: TransactionType.expense,
            amount: loanItem.emiAmount,
            categoryName: 'Loan EMI',
            date: DateTime.now(),
            note: loanItem.sourceText,
            sourceText: loanItem.sourceText,
            status: BlueprintItemStatus.confirmed,
          ),
        );
      } else if (optionId == 'recurring_commitment') {
        updatedLoans[loanIdx] = loanItem.copyWith(
          status: BlueprintItemStatus.confirmed,
        );
      } else if (optionId == 'existing_loan') {
        updatedLoans[loanIdx] = loanItem.copyWith(
          isExistingLoanPayment: true,
          status: BlueprintItemStatus.confirmed,
        );
      } else {
        // Not sure / skip
        updatedLoans[loanIdx] = loanItem.copyWith(
          status: BlueprintItemStatus.needsReview,
        );
      }
    }

    // Check if target item is in Expenses
    final expIdx = updatedExpenses.indexWhere((e) => e.id == targetItemId);
    if (expIdx != -1) {
      final expItem = updatedExpenses[expIdx];
      if (optionId == 'past_expense') {
        // Move to Transactions
        updatedExpenses.removeAt(expIdx);
        updatedTransactions.add(
          BlueprintTransactionItem(
            id: expItem.id,
            type: TransactionType.expense,
            amount: expItem.monthlyAmount,
            categoryName: expItem.categoryName,
            categoryId: expItem.categoryId,
            date: DateTime.now(),
            note: expItem.sourceText,
            sourceText: expItem.sourceText,
            status: BlueprintItemStatus.confirmed,
          ),
        );
      } else if (optionId == 'usual_monthly') {
        updatedExpenses[expIdx] = expItem.copyWith(
          status: BlueprintItemStatus.confirmed,
        );
      } else {
        updatedExpenses[expIdx] = expItem.copyWith(
          status: BlueprintItemStatus.needsReview,
        );
      }
    }

    // Check if target item is in Transactions (Account question)
    final txIdx = updatedTransactions.indexWhere((t) => t.id == targetItemId);
    if (txIdx != -1) {
      final txItem = updatedTransactions[txIdx];
      if (optionId != 'create_account' && optionId != 'skip_account') {
        updatedTransactions[txIdx] = txItem.copyWith(
          accountId: optionId,
          status: BlueprintItemStatus.confirmed,
        );
      }
    }

    final updatedBlueprint = bp.copyWith(
      incomes: updatedIncomes,
      loans: updatedLoans,
      recurringExpenses: updatedExpenses,
      savings: updatedSavings,
      goals: updatedGoals,
      transactions: updatedTransactions,
      clarifications: updatedQuestions,
    );

    state = state.copyWith(
      blueprint: updatedBlueprint,
      activeQuestionIndex: state.activeQuestionIndex + 1,
    );
  }

  void skipClarification(String questionId) {
    answerClarification(questionId: questionId, optionId: 'skip');
  }

  // --- ITEM MUTATION METHODS ---
  void updateIncomeItem(int index, BlueprintIncomeItem updated) {
    final bp = state.blueprint;
    if (bp == null || index < 0 || index >= bp.incomes.length) return;
    final list = List<BlueprintIncomeItem>.from(bp.incomes)..[index] = updated;
    state = state.copyWith(blueprint: bp.copyWith(incomes: list));
  }

  void removeIncomeItem(int index) {
    final bp = state.blueprint;
    if (bp == null || index < 0 || index >= bp.incomes.length) return;
    final list = List<BlueprintIncomeItem>.from(bp.incomes)..removeAt(index);
    state = state.copyWith(blueprint: bp.copyWith(incomes: list));
  }

  void updateExpenseItem(int index, BlueprintExpenseItem updated) {
    final bp = state.blueprint;
    if (bp == null || index < 0 || index >= bp.recurringExpenses.length) return;
    final list = List<BlueprintExpenseItem>.from(bp.recurringExpenses)
      ..[index] = updated;
    state = state.copyWith(blueprint: bp.copyWith(recurringExpenses: list));
  }

  void removeExpenseItem(int index) {
    final bp = state.blueprint;
    if (bp == null || index < 0 || index >= bp.recurringExpenses.length) return;
    final list = List<BlueprintExpenseItem>.from(bp.recurringExpenses)
      ..removeAt(index);
    state = state.copyWith(blueprint: bp.copyWith(recurringExpenses: list));
  }

  void updateLoanItem(int index, BlueprintLoanItem updated) {
    final bp = state.blueprint;
    if (bp == null || index < 0 || index >= bp.loans.length) return;
    final list = List<BlueprintLoanItem>.from(bp.loans)..[index] = updated;
    state = state.copyWith(blueprint: bp.copyWith(loans: list));
  }

  void removeLoanItem(int index) {
    final bp = state.blueprint;
    if (bp == null || index < 0 || index >= bp.loans.length) return;
    final list = List<BlueprintLoanItem>.from(bp.loans)..removeAt(index);
    state = state.copyWith(blueprint: bp.copyWith(loans: list));
  }

  void updateSavingsItem(int index, BlueprintSavingsItem updated) {
    final bp = state.blueprint;
    if (bp == null || index < 0 || index >= bp.savings.length) return;
    final list = List<BlueprintSavingsItem>.from(bp.savings)..[index] = updated;
    state = state.copyWith(blueprint: bp.copyWith(savings: list));
  }

  void removeSavingsItem(int index) {
    final bp = state.blueprint;
    if (bp == null || index < 0 || index >= bp.savings.length) return;
    final list = List<BlueprintSavingsItem>.from(bp.savings)..removeAt(index);
    state = state.copyWith(blueprint: bp.copyWith(savings: list));
  }

  void updateGoalItem(int index, BlueprintGoalItem updated) {
    final bp = state.blueprint;
    if (bp == null || index < 0 || index >= bp.goals.length) return;
    final list = List<BlueprintGoalItem>.from(bp.goals)..[index] = updated;
    state = state.copyWith(blueprint: bp.copyWith(goals: list));
  }

  void removeGoalItem(int index) {
    final bp = state.blueprint;
    if (bp == null || index < 0 || index >= bp.goals.length) return;
    final list = List<BlueprintGoalItem>.from(bp.goals)..removeAt(index);
    state = state.copyWith(blueprint: bp.copyWith(goals: list));
  }

  void updateTransactionItem(int index, BlueprintTransactionItem updated) {
    final bp = state.blueprint;
    if (bp == null || index < 0 || index >= bp.transactions.length) return;
    final list = List<BlueprintTransactionItem>.from(bp.transactions)
      ..[index] = updated;
    state = state.copyWith(blueprint: bp.copyWith(transactions: list));
  }

  void removeTransactionItem(int index) {
    final bp = state.blueprint;
    if (bp == null || index < 0 || index >= bp.transactions.length) return;
    final list = List<BlueprintTransactionItem>.from(bp.transactions)
      ..removeAt(index);
    state = state.copyWith(blueprint: bp.copyWith(transactions: list));
  }

  void clearBlueprint() {
    state = const BlueprintState();
  }

  // --- PERSISTENCE CONFIRMATION ---
  Future<bool> confirmAndPersist(String userId) async {
    final bp = state.blueprint;
    if (bp == null) return false;

    state = state.copyWith(isPersisting: true, errorMessage: null);
    try {
      final result = await _persistenceService.persistBlueprint(
        blueprint: bp,
        userId: userId,
      );
      state = state.copyWith(
        isPersisting: false,
        isConfirmed: true,
        persistenceResult: result,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isPersisting: false,
        errorMessage: 'Failed to create financial records: $e',
      );
      return false;
    }
  }
}

final blueprintControllerProvider =
    StateNotifierProvider<BlueprintController, BlueprintState>((ref) {
      final parser = ref.watch(financialSituationParserProvider);
      final persistence = ref.watch(blueprintPersistenceServiceProvider);
      return BlueprintController(parser, persistence);
    });
