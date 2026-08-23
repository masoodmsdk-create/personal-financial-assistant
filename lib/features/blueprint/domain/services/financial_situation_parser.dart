import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/blueprint/domain/models/financial_blueprint.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

/// Pure deterministic natural-language multi-entity situation parsing engine.
class FinancialSituationParser {
  const FinancialSituationParser();

  FinancialBlueprint parseSituation({
    required String rawText,
    String? workspaceContext,
    required List<Account> accounts,
    required List<Category> categories,
    List<Loan> existingLoans = const [],
    List<Goal> existingGoals = const [],
  }) {
    if (rawText.trim().isEmpty) {
      return FinancialBlueprint(
        id: 'bp_${DateTime.now().millisecondsSinceEpoch}',
        rawInput: rawText,
        workspaceContext: workspaceContext,
      );
    }

    final clauses = _segmentClauses(rawText);

    final incomes = <BlueprintIncomeItem>[];
    final loans = <BlueprintLoanItem>[];
    final expenses = <BlueprintExpenseItem>[];
    final savings = <BlueprintSavingsItem>[];
    final goals = <BlueprintGoalItem>[];
    final transactions = <BlueprintTransactionItem>[];
    final clarifications = <ClarificationQuestion>[];
    final assumptions = <String>[];
    final warnings = <String>[];

    int itemCounter = 0;

    for (final clause in clauses) {
      final lower = clause.toLowerCase().trim();
      if (lower.isEmpty) continue;

      final amountMatch = _extractAmount(lower);
      if (amountMatch == null) {
        // Clause has no extractable amount; skip or note
        continue;
      }

      final amount = amountMatch.amount;
      final itemId =
          'item_${DateTime.now().millisecondsSinceEpoch}_${itemCounter++}';

      // 1. GOAL DETECTION
      if (_isGoal(lower)) {
        final goalName = _extractGoalName(lower);
        final goalType = _detectGoalType(lower);
        goals.add(
          BlueprintGoalItem(
            id: itemId,
            goalName: goalName,
            targetAmount: amount,
            goalType: goalType,
            sourceText: clause,
            status: BlueprintItemStatus.confirmed,
          ),
        );
        continue;
      }

      // 2. SAVINGS / ASSET DETECTION
      if (_isSavings(lower)) {
        final accountName = _extractSavingsName(lower);
        savings.add(
          BlueprintSavingsItem(
            id: itemId,
            accountName: accountName,
            amount: amount,
            accountType: AccountType.bank,
            sourceText: clause,
            status: BlueprintItemStatus.confirmed,
          ),
        );
        continue;
      }

      // 3. INCOME DETECTION
      if (_isIncome(lower)) {
        final owner = _detectIncomeOwner(lower);
        final label = _extractIncomeLabel(lower, owner);
        incomes.add(
          BlueprintIncomeItem(
            id: itemId,
            label: label,
            monthlyAmount: amount,
            ownerLabel: owner,
            sourceText: clause,
            status: BlueprintItemStatus.confirmed,
          ),
        );
        continue;
      }

      // 4. LOAN / EMI COMMITMENT DETECTION
      if (_isLoanOrEmi(lower)) {
        final loanName = _extractLoanName(lower);
        final loanType = _detectLoanType(lower);

        // Check if user specifically said "paid emi yesterday" or single transaction phrasing
        if (_isSpecificPaidTransaction(lower)) {
          // Ambiguous: Actual payment vs recurring commitment
          final questionId = 'q_$itemId';
          clarifications.add(
            ClarificationQuestion(
              id: questionId,
              targetItemId: itemId,
              question: 'What does ₹${amount.toStringAsFixed(0)} represent?',
              contextSnippet: clause,
              options: [
                const ClarificationOption(
                  id: 'actual_payment',
                  label: 'Actual EMI payment made',
                  description:
                      'Record as a completed transaction in account history',
                ),
                const ClarificationOption(
                  id: 'recurring_commitment',
                  label: 'Recurring monthly EMI commitment',
                  description: 'Add as a monthly loan obligation in your plan',
                ),
                if (existingLoans.isNotEmpty)
                  const ClarificationOption(
                    id: 'existing_loan',
                    label: 'Payment toward an existing loan',
                    description: 'Link payment to one of your active loans',
                  ),
                const ClarificationOption(
                  id: 'not_sure',
                  label: 'Not sure / Review later',
                  description: 'Keep in draft as needs review',
                ),
              ],
              canSkip: true,
            ),
          );

          loans.add(
            BlueprintLoanItem(
              id: itemId,
              loanName: loanName,
              emiAmount: amount,
              loanType: loanType,
              sourceText: clause,
              status: BlueprintItemStatus.needsReview,
              missingFields: const ['principal', 'interestRate', 'tenure'],
            ),
          );
        } else {
          // Standard recurring loan commitment
          loans.add(
            BlueprintLoanItem(
              id: itemId,
              loanName: loanName,
              emiAmount: amount,
              loanType: loanType,
              sourceText: clause,
              status: BlueprintItemStatus.incomplete,
              missingFields: const ['principal', 'interestRate', 'tenure'],
            ),
          );
        }
        continue;
      }

      // 5. RECURRING LIVING EXPENSES vs ONE-OFF TRANSACTIONS
      final isClearPastTransaction = _isExplicitPastTransaction(lower);

      if (isClearPastTransaction) {
        // Parsed as an actual historical transaction
        final matchedCategory = _matchCategory(
          lower,
          categories,
          CategoryType.expense,
        );
        final matchedAccount = _matchAccount(lower, accounts);
        final date = _extractDate(lower);

        if (matchedAccount == null && _mentionsUnmatchedAccount(lower)) {
          final questionId = 'q_$itemId';
          clarifications.add(
            ClarificationQuestion(
              id: questionId,
              targetItemId: itemId,
              question:
                  'Which account was used for ₹${amount.toStringAsFixed(0)}?',
              contextSnippet: clause,
              options: [
                ...accounts.map(
                  (a) => ClarificationOption(id: a.id, label: a.name),
                ),
                const ClarificationOption(
                  id: 'create_account',
                  label: '+ Create Account',
                ),
                const ClarificationOption(
                  id: 'skip_account',
                  label: 'Record without account / Fix later',
                ),
              ],
              canSkip: true,
            ),
          );
        }

        transactions.add(
          BlueprintTransactionItem(
            id: itemId,
            type: TransactionType.expense,
            amount: amount,
            categoryName: matchedCategory?.name ?? _inferCategoryName(lower),
            categoryId: matchedCategory?.id,
            accountName: matchedAccount?.name,
            accountId: matchedAccount?.id,
            date: date,
            note: clause,
            sourceText: clause,
            status: matchedAccount != null
                ? BlueprintItemStatus.confirmed
                : BlueprintItemStatus.needsReview,
          ),
        );
        continue;
      }

      // Default: Recurring Living Expense (e.g. rent, groceries, petrol, electricity)
      final categoryName = _inferCategoryName(lower);
      final matchedCat = _matchCategory(
        lower,
        categories,
        CategoryType.expense,
      );

      // Check if ambiguous single-word expense e.g. "petrol 3000"
      if (_isAmbiguousExpense(lower)) {
        final questionId = 'q_$itemId';
        clarifications.add(
          ClarificationQuestion(
            id: questionId,
            targetItemId: itemId,
            question:
                'How should ₹${amount.toStringAsFixed(0)} for $categoryName be recorded?',
            contextSnippet: clause,
            options: [
              const ClarificationOption(
                id: 'usual_monthly',
                label: 'My usual monthly expense',
                description: 'Add as a recurring planned living expense',
              ),
              const ClarificationOption(
                id: 'past_expense',
                label: 'A purchase I already made',
                description: 'Record as an actual transaction',
              ),
              const ClarificationOption(id: 'not_sure', label: 'Skip for now'),
            ],
            canSkip: true,
          ),
        );

        expenses.add(
          BlueprintExpenseItem(
            id: itemId,
            categoryName: matchedCat?.name ?? categoryName,
            categoryId: matchedCat?.id,
            monthlyAmount: amount,
            sourceText: clause,
            status: BlueprintItemStatus.needsReview,
          ),
        );
      } else {
        expenses.add(
          BlueprintExpenseItem(
            id: itemId,
            categoryName: matchedCat?.name ?? categoryName,
            categoryId: matchedCat?.id,
            monthlyAmount: amount,
            sourceText: clause,
            status: BlueprintItemStatus.confirmed,
          ),
        );
      }
    }

    if (incomes.isNotEmpty && expenses.isNotEmpty) {
      assumptions.add(
        'Income and living expense figures are treated as monthly amounts.',
      );
    }

    return FinancialBlueprint(
      id: 'bp_${DateTime.now().millisecondsSinceEpoch}',
      rawInput: rawText,
      workspaceContext: workspaceContext,
      incomes: incomes,
      loans: loans,
      recurringExpenses: expenses,
      savings: savings,
      goals: goals,
      transactions: transactions,
      clarifications: clarifications,
      assumptions: assumptions,
      warnings: warnings,
    );
  }

  // --- CLAUSE SEGMENTATION ---
  List<String> _segmentClauses(String rawText) {
    final rawLines = rawText.split(RegExp(r'[\n;]+'));
    final results = <String>[];

    for (final line in rawLines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Split by sentence periods, commas with spaces or followed by letters, or 'and' followed by words
      final splitParts = trimmed.split(
        RegExp(r'\.\s+|\.$|,\s+|,(?=[a-zA-Z])|\s+and\s+(?=[a-zA-Z])'),
      );

      for (final part in splitParts) {
        final p = part.trim();
        if (p.isNotEmpty) {
          results.add(p);
        }
      }
    }

    return results;
  }

  // --- AMOUNT EXTRACTION ---
  _AmountMatch? _extractAmount(String text) {
    // 1. Lakhs (e.g. 1.5 lakh, 2L, 50 lakhs, 1.5 lac)
    final lakhRegex = RegExp(
      r'(?:(?:rs\.?|inr|₹)\s*)?(\d+(?:\.\d+)?)\s*(?:lakhs?|lacs?|lac)\b|(?:(?:rs\.?|inr|₹)\s*)?(\d+(?:\.\d+)?)\s*l\b',
      caseSensitive: false,
    );
    final lakhMatch = lakhRegex.firstMatch(text);
    if (lakhMatch != null) {
      final rawNum = lakhMatch.group(1) ?? lakhMatch.group(2);
      if (rawNum != null) {
        final val = double.tryParse(rawNum);
        if (val != null && val > 0) {
          return _AmountMatch(
            amount: val * 100000.0,
            rawMatch: lakhMatch.group(0)!,
          );
        }
      }
    }

    // 2. Thousands with k (e.g. 45k, 60k, 8.5k)
    final kRegex = RegExp(
      r'(?:(?:rs\.?|inr|₹)\s*)?(\d+(?:\.\d+)?)\s*k\b',
      caseSensitive: false,
    );
    final kMatch = kRegex.firstMatch(text);
    if (kMatch != null) {
      final val = double.tryParse(kMatch.group(1)!);
      if (val != null && val > 0) {
        return _AmountMatch(amount: val * 1000.0, rawMatch: kMatch.group(0)!);
      }
    }

    // 3. Indian format commas or plain digits (e.g. ₹1,00,000, 45000, Rs. 1200, 100000)
    final standardRegex = RegExp(
      r'(?:(?:rs\.?|inr|₹)\s*)?(\d{1,3}(?:,\d{2,3})+(?:\.\d+)?|\d+(?:\.\d+)?)',
      caseSensitive: false,
    );
    final allMatches = standardRegex.allMatches(text);
    for (final match in allMatches) {
      final rawStr = match.group(1)?.replaceAll(',', '');
      if (rawStr != null) {
        final val = double.tryParse(rawStr);
        if (val != null && val > 0) {
          return _AmountMatch(amount: val, rawMatch: match.group(0)!);
        }
      }
    }

    return null;
  }

  // --- ENTITY DETECTORS ---
  bool _isGoal(String text) {
    return text.contains('goal') ||
        text.contains('emergency fund') ||
        text.contains('saving for') ||
        text.contains('vacation fund') ||
        text.contains('target') ||
        text.contains('fund of');
  }

  bool _isSavings(String text) {
    return (text.contains('saving') ||
            text.contains('saved') ||
            text.contains('savings') ||
            text.contains('bank balance') ||
            text.contains('cash in hand') ||
            text.contains('reserve') ||
            text.contains('fixed deposit') ||
            text.contains('fd')) &&
        !text.contains('goal') &&
        !text.contains('emergency fund');
  }

  bool _isIncome(String text) {
    return text.contains('salary') ||
        text.contains('earn') ||
        text.contains('earns') ||
        text.contains('income') ||
        text.contains('credited') ||
        text.contains('freelance') ||
        text.contains('stipend') ||
        text.contains('bonus') ||
        text.contains('dividend');
  }

  bool _isLoanOrEmi(String text) {
    return text.contains('emi') ||
        text.contains('home loan') ||
        text.contains('car loan') ||
        text.contains('personal loan') ||
        text.contains('education loan') ||
        text.contains('loan');
  }

  bool _isSpecificPaidTransaction(String text) {
    return text.contains('paid') ||
        text.contains('yesterday') ||
        text.contains('today') ||
        text.contains('debited') ||
        text.contains('spent');
  }

  bool _isExplicitPastTransaction(String text) {
    return (text.contains('spent') ||
            text.contains('paid') ||
            text.contains('bought') ||
            text.contains('yesterday') ||
            text.contains('today') ||
            text.contains('debited')) &&
        !text.contains('salary') &&
        !text.contains('earn');
  }

  bool _isAmbiguousExpense(String text) {
    // If only category + amount e.g. "petrol 3000" or "groceries 5000" without "monthly", "spent", "rent"
    if (text.contains('rent') ||
        text.contains('monthly') ||
        text.contains('every month')) {
      return false;
    }
    return !text.contains('spent') &&
        !text.contains('paid') &&
        !text.contains('yesterday');
  }

  // --- LABEL & NAME EXTRACTORS ---
  String _detectIncomeOwner(String text) {
    if (text.contains('wife')) {
      return 'Wife Salary';
    }
    if (text.contains('husband') || text.contains('spouse')) {
      return 'Spouse Salary';
    }
    if (text.contains('freelance')) {
      return 'Freelance Income';
    }
    return 'My Salary';
  }

  String _extractIncomeLabel(String text, String owner) {
    if (text.contains('wife')) {
      return 'Wife Salary';
    }
    if (text.contains('freelance')) {
      return 'Freelance Income';
    }
    if (text.contains('bonus')) {
      return 'Annual Bonus';
    }
    return owner;
  }

  String _extractLoanName(String text) {
    if (text.contains('home loan') || text.contains('home')) {
      return 'Home Loan';
    }
    if (text.contains('car loan') || text.contains('car')) {
      return 'Car Loan';
    }
    if (text.contains('education')) {
      return 'Education Loan';
    }
    if (text.contains('personal loan')) {
      return 'Personal Loan';
    }
    return 'Loan EMI';
  }

  LoanType _detectLoanType(String text) {
    if (text.contains('home')) {
      return LoanType.homeLoan;
    }
    if (text.contains('car') || text.contains('vehicle')) {
      return LoanType.carLoan;
    }
    if (text.contains('education')) {
      return LoanType.educationLoan;
    }
    return LoanType.personalLoan;
  }

  String _extractSavingsName(String text) {
    if (text.contains('cash')) {
      return 'Cash Reserve';
    }
    if (text.contains('fixed deposit') || text.contains('fd')) {
      return 'Fixed Deposit';
    }
    return 'Existing Savings';
  }

  String _extractGoalName(String text) {
    if (text.contains('emergency fund') || text.contains('emergency')) {
      return 'Emergency Fund';
    }
    if (text.contains('vacation')) {
      return 'Vacation Goal';
    }
    if (text.contains('car')) {
      return 'Car Down Payment';
    }
    if (text.contains('home') || text.contains('house')) {
      return 'House Down Payment';
    }
    return 'Savings Goal';
  }

  GoalType _detectGoalType(String text) {
    if (text.contains('emergency')) {
      return GoalType.emergencyFund;
    }
    if (text.contains('debt') || text.contains('payoff')) {
      return GoalType.debtGoal;
    }
    return GoalType.savingsGoal;
  }

  String _inferCategoryName(String text) {
    if (text.contains('rent')) return 'Rent';
    if (text.contains('grocer')) return 'Groceries';
    if (text.contains('petrol') || text.contains('fuel')) return 'Fuel';
    if (text.contains('electric') ||
        text.contains('utility') ||
        text.contains('bill')) {
      return 'Utilities';
    }
    if (text.contains('food') ||
        text.contains('dining') ||
        text.contains('lunch') ||
        text.contains('dinner')) {
      return 'Dining Out';
    }
    if (text.contains('maid') ||
        text.contains('cook') ||
        text.contains('maintenance')) {
      return 'Home Maintenance';
    }
    if (text.contains('school') ||
        text.contains('fee') ||
        text.contains('tuition')) {
      return 'Education';
    }
    if (text.contains('personal')) return 'Personal Care';
    return 'Living Expense';
  }

  Category? _matchCategory(
    String text,
    List<Category> categories,
    CategoryType type,
  ) {
    for (final cat in categories) {
      if (cat.type == type && text.contains(cat.name.toLowerCase())) {
        return cat;
      }
    }
    return null;
  }

  Account? _matchAccount(String text, List<Account> accounts) {
    for (final acc in accounts) {
      if (text.contains(acc.name.toLowerCase())) {
        return acc;
      }
    }
    return null;
  }

  bool _mentionsUnmatchedAccount(String text) {
    final keywords = [
      'hdfc',
      'sbi',
      'icici',
      'axis',
      'kotak',
      'bank',
      'card',
      'cash',
    ];
    return keywords.any((k) => text.contains(k));
  }

  DateTime _extractDate(String text) {
    final now = DateTime.now();
    if (text.contains('yesterday')) {
      return now.subtract(const Duration(days: 1));
    }
    return now;
  }
}

class _AmountMatch {
  final double amount;
  final String rawMatch;

  const _AmountMatch({required this.amount, required this.rawMatch});
}
