import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

enum BlueprintItemStatus {
  confirmed,
  needsReview,
  incomplete,
  ambiguous;

  String get displayName {
    switch (this) {
      case BlueprintItemStatus.confirmed:
        return 'Confirmed';
      case BlueprintItemStatus.needsReview:
        return 'Needs Review';
      case BlueprintItemStatus.incomplete:
        return 'Incomplete Details';
      case BlueprintItemStatus.ambiguous:
        return 'Ambiguous';
    }
  }
}

class BlueprintIncomeItem {
  final String id;
  final String label;
  final double monthlyAmount;
  final String? ownerLabel;
  final String sourceText;
  final BlueprintItemStatus status;

  const BlueprintIncomeItem({
    required this.id,
    required this.label,
    required this.monthlyAmount,
    this.ownerLabel,
    required this.sourceText,
    this.status = BlueprintItemStatus.confirmed,
  });

  BlueprintIncomeItem copyWith({
    String? id,
    String? label,
    double? monthlyAmount,
    String? ownerLabel,
    String? sourceText,
    BlueprintItemStatus? status,
  }) {
    return BlueprintIncomeItem(
      id: id ?? this.id,
      label: label ?? this.label,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      ownerLabel: ownerLabel ?? this.ownerLabel,
      sourceText: sourceText ?? this.sourceText,
      status: status ?? this.status,
    );
  }
}

class BlueprintExpenseItem {
  final String id;
  final String categoryName;
  final String? categoryId;
  final double monthlyAmount;
  final String frequency;
  final String sourceText;
  final BlueprintItemStatus status;

  const BlueprintExpenseItem({
    required this.id,
    required this.categoryName,
    this.categoryId,
    required this.monthlyAmount,
    this.frequency = 'monthly',
    required this.sourceText,
    this.status = BlueprintItemStatus.confirmed,
  });

  BlueprintExpenseItem copyWith({
    String? id,
    String? categoryName,
    String? categoryId,
    double? monthlyAmount,
    String? frequency,
    String? sourceText,
    BlueprintItemStatus? status,
  }) {
    return BlueprintExpenseItem(
      id: id ?? this.id,
      categoryName: categoryName ?? this.categoryName,
      categoryId: categoryId ?? this.categoryId,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      frequency: frequency ?? this.frequency,
      sourceText: sourceText ?? this.sourceText,
      status: status ?? this.status,
    );
  }
}

class BlueprintLoanItem {
  final String id;
  final String loanName;
  final double emiAmount;
  final LoanType loanType;
  final double? outstandingPrincipal;
  final double? interestRate;
  final int? remainingTenureMonths;
  final String? linkedLoanId;
  final bool isExistingLoanPayment;
  final String sourceText;
  final BlueprintItemStatus status;
  final List<String> missingFields;

  const BlueprintLoanItem({
    required this.id,
    required this.loanName,
    required this.emiAmount,
    this.loanType = LoanType.personalLoan,
    this.outstandingPrincipal,
    this.interestRate,
    this.remainingTenureMonths,
    this.linkedLoanId,
    this.isExistingLoanPayment = false,
    required this.sourceText,
    this.status = BlueprintItemStatus.confirmed,
    this.missingFields = const [],
  });

  BlueprintLoanItem copyWith({
    String? id,
    String? loanName,
    double? emiAmount,
    LoanType? loanType,
    double? outstandingPrincipal,
    double? interestRate,
    int? remainingTenureMonths,
    String? linkedLoanId,
    bool? isExistingLoanPayment,
    String? sourceText,
    BlueprintItemStatus? status,
    List<String>? missingFields,
  }) {
    return BlueprintLoanItem(
      id: id ?? this.id,
      loanName: loanName ?? this.loanName,
      emiAmount: emiAmount ?? this.emiAmount,
      loanType: loanType ?? this.loanType,
      outstandingPrincipal: outstandingPrincipal ?? this.outstandingPrincipal,
      interestRate: interestRate ?? this.interestRate,
      remainingTenureMonths:
          remainingTenureMonths ?? this.remainingTenureMonths,
      linkedLoanId: linkedLoanId ?? this.linkedLoanId,
      isExistingLoanPayment:
          isExistingLoanPayment ?? this.isExistingLoanPayment,
      sourceText: sourceText ?? this.sourceText,
      status: status ?? this.status,
      missingFields: missingFields ?? this.missingFields,
    );
  }
}

class BlueprintSavingsItem {
  final String id;
  final String accountName;
  final double amount;
  final AccountType accountType;
  final String? accountId;
  final String sourceText;
  final BlueprintItemStatus status;

  const BlueprintSavingsItem({
    required this.id,
    required this.accountName,
    required this.amount,
    this.accountType = AccountType.bank,
    this.accountId,
    required this.sourceText,
    this.status = BlueprintItemStatus.confirmed,
  });

  BlueprintSavingsItem copyWith({
    String? id,
    String? accountName,
    double? amount,
    AccountType? accountType,
    String? accountId,
    String? sourceText,
    BlueprintItemStatus? status,
  }) {
    return BlueprintSavingsItem(
      id: id ?? this.id,
      accountName: accountName ?? this.accountName,
      amount: amount ?? this.amount,
      accountType: accountType ?? this.accountType,
      accountId: accountId ?? this.accountId,
      sourceText: sourceText ?? this.sourceText,
      status: status ?? this.status,
    );
  }
}

class BlueprintGoalItem {
  final String id;
  final String goalName;
  final double targetAmount;
  final int? targetMonths;
  final GoalType goalType;
  final String sourceText;
  final BlueprintItemStatus status;

  const BlueprintGoalItem({
    required this.id,
    required this.goalName,
    required this.targetAmount,
    this.targetMonths,
    this.goalType = GoalType.savingsGoal,
    required this.sourceText,
    this.status = BlueprintItemStatus.confirmed,
  });

  BlueprintGoalItem copyWith({
    String? id,
    String? goalName,
    double? targetAmount,
    int? targetMonths,
    GoalType? goalType,
    String? sourceText,
    BlueprintItemStatus? status,
  }) {
    return BlueprintGoalItem(
      id: id ?? this.id,
      goalName: goalName ?? this.goalName,
      targetAmount: targetAmount ?? this.targetAmount,
      targetMonths: targetMonths ?? this.targetMonths,
      goalType: goalType ?? this.goalType,
      sourceText: sourceText ?? this.sourceText,
      status: status ?? this.status,
    );
  }
}

class BlueprintTransactionItem {
  final String id;
  final TransactionType type;
  final double amount;
  final String? categoryName;
  final String? categoryId;
  final String? accountName;
  final String? accountId;
  final DateTime date;
  final String note;
  final String sourceText;
  final BlueprintItemStatus status;

  const BlueprintTransactionItem({
    required this.id,
    required this.type,
    required this.amount,
    this.categoryName,
    this.categoryId,
    this.accountName,
    this.accountId,
    required this.date,
    required this.note,
    required this.sourceText,
    this.status = BlueprintItemStatus.confirmed,
  });

  BlueprintTransactionItem copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? categoryName,
    String? categoryId,
    String? accountName,
    String? accountId,
    DateTime? date,
    String? note,
    String? sourceText,
    BlueprintItemStatus? status,
  }) {
    return BlueprintTransactionItem(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryName: categoryName ?? this.categoryName,
      categoryId: categoryId ?? this.categoryId,
      accountName: accountName ?? this.accountName,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      note: note ?? this.note,
      sourceText: sourceText ?? this.sourceText,
      status: status ?? this.status,
    );
  }
}

class ClarificationOption {
  final String id;
  final String label;
  final String? description;

  const ClarificationOption({
    required this.id,
    required this.label,
    this.description,
  });
}

class ClarificationQuestion {
  final String id;
  final String targetItemId;
  final String question;
  final String? contextSnippet;
  final List<ClarificationOption> options;
  final bool canSkip;
  final String? selectedOptionId;

  const ClarificationQuestion({
    required this.id,
    required this.targetItemId,
    required this.question,
    this.contextSnippet,
    required this.options,
    this.canSkip = true,
    this.selectedOptionId,
  });

  ClarificationQuestion copyWith({
    String? id,
    String? targetItemId,
    String? question,
    String? contextSnippet,
    List<ClarificationOption>? options,
    bool? canSkip,
    String? selectedOptionId,
  }) {
    return ClarificationQuestion(
      id: id ?? this.id,
      targetItemId: targetItemId ?? this.targetItemId,
      question: question ?? this.question,
      contextSnippet: contextSnippet ?? this.contextSnippet,
      options: options ?? this.options,
      canSkip: canSkip ?? this.canSkip,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
    );
  }
}

/// Represents the in-memory, live, pre-persistence Financial Blueprint draft.
class FinancialBlueprint {
  final String id;
  final String rawInput;
  final String? workspaceContext;
  final List<BlueprintIncomeItem> incomes;
  final List<BlueprintLoanItem> loans;
  final List<BlueprintExpenseItem> recurringExpenses;
  final List<BlueprintSavingsItem> savings;
  final List<BlueprintGoalItem> goals;
  final List<BlueprintTransactionItem> transactions;
  final List<ClarificationQuestion> clarifications;
  final List<String> assumptions;
  final List<String> warnings;

  const FinancialBlueprint({
    required this.id,
    required this.rawInput,
    this.workspaceContext,
    this.incomes = const [],
    this.loans = const [],
    this.recurringExpenses = const [],
    this.savings = const [],
    this.goals = const [],
    this.transactions = const [],
    this.clarifications = const [],
    this.assumptions = const [],
    this.warnings = const [],
  });

  // Pure Deterministic Aggregation Getters
  double get totalMonthlyIncome =>
      incomes.fold(0.0, (sum, item) => sum + item.monthlyAmount);

  double get totalMonthlyExpenses =>
      recurringExpenses.fold(0.0, (sum, item) => sum + item.monthlyAmount);

  double get totalMonthlyEmi =>
      loans.fold(0.0, (sum, item) => sum + item.emiAmount);

  double get totalMonthlyCommitments => totalMonthlyExpenses + totalMonthlyEmi;

  double get knownRemainingMonthlyCashFlow =>
      totalMonthlyIncome - totalMonthlyCommitments;

  double get totalSavings =>
      savings.fold(0.0, (sum, item) => sum + item.amount);

  double get totalGoalTargets =>
      goals.fold(0.0, (sum, item) => sum + item.targetAmount);

  int get totalEntitiesCount =>
      incomes.length +
      loans.length +
      recurringExpenses.length +
      savings.length +
      goals.length +
      transactions.length;

  List<ClarificationQuestion> get unresolvedQuestions =>
      clarifications.where((q) => q.selectedOptionId == null).toList();

  bool get hasUnresolvedClarifications => unresolvedQuestions.isNotEmpty;

  int get itemsRequiringReviewCount {
    int count = 0;
    count += incomes
        .where((i) => i.status != BlueprintItemStatus.confirmed)
        .length;
    count += loans
        .where((l) => l.status != BlueprintItemStatus.confirmed)
        .length;
    count += recurringExpenses
        .where((e) => e.status != BlueprintItemStatus.confirmed)
        .length;
    count += savings
        .where((s) => s.status != BlueprintItemStatus.confirmed)
        .length;
    count += goals
        .where((g) => g.status != BlueprintItemStatus.confirmed)
        .length;
    count += transactions
        .where((t) => t.status != BlueprintItemStatus.confirmed)
        .length;
    return count;
  }

  FinancialBlueprint copyWith({
    String? id,
    String? rawInput,
    String? workspaceContext,
    List<BlueprintIncomeItem>? incomes,
    List<BlueprintLoanItem>? loans,
    List<BlueprintExpenseItem>? recurringExpenses,
    List<BlueprintSavingsItem>? savings,
    List<BlueprintGoalItem>? goals,
    List<BlueprintTransactionItem>? transactions,
    List<ClarificationQuestion>? clarifications,
    List<String>? assumptions,
    List<String>? warnings,
  }) {
    return FinancialBlueprint(
      id: id ?? this.id,
      rawInput: rawInput ?? this.rawInput,
      workspaceContext: workspaceContext ?? this.workspaceContext,
      incomes: incomes ?? this.incomes,
      loans: loans ?? this.loans,
      recurringExpenses: recurringExpenses ?? this.recurringExpenses,
      savings: savings ?? this.savings,
      goals: goals ?? this.goals,
      transactions: transactions ?? this.transactions,
      clarifications: clarifications ?? this.clarifications,
      assumptions: assumptions ?? this.assumptions,
      warnings: warnings ?? this.warnings,
    );
  }
}
