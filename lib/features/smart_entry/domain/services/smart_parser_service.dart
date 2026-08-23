import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/smart_entry/domain/models/parsed_draft_transaction.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

/// Pure deterministic natural-language parsing engine for free-form financial entries.
class SmartParserService {
  const SmartParserService();

  /// Parses unstructured multi-line or single-line text into a list of draft transactions.
  List<ParsedDraftTransaction> parseText({
    required String rawText,
    required List<Account> accounts,
    required List<Category> categories,
  }) {
    if (rawText.trim().isEmpty) return [];

    final lines = rawText
        .split(RegExp(r'[\n;]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final drafts = <ParsedDraftTransaction>[];
    int counter = 0;

    for (final line in lines) {
      final draft = _parseSingleLine(
        id: 'draft_${DateTime.now().millisecondsSinceEpoch}_${counter++}',
        line: line,
        accounts: accounts,
        categories: categories,
      );
      if (draft != null) {
        drafts.add(draft);
      }
    }

    return drafts;
  }

  ParsedDraftTransaction? _parseSingleLine({
    required String id,
    required String line,
    required List<Account> accounts,
    required List<Category> categories,
  }) {
    final lower = line.toLowerCase();

    // 1. Extract Amount
    final amountResult = _extractAmount(lower);
    if (amountResult == null) {
      return null; // A transaction must have an amount
    }
    final amount = amountResult.amount;

    // 2. Extract Date
    final dateResult = _extractDate(lower);
    final date = dateResult.date;

    // 3. Detect Transaction Type
    final isTransfer = _isTransfer(lower);
    final isIncome = !isTransfer && _isIncome(lower);
    final type = isTransfer
        ? TransactionType.transfer
        : (isIncome ? TransactionType.income : TransactionType.expense);

    // 4. Match Accounts
    String? accountId;
    String? fromAccountId;
    String? toAccountId;

    if (type == TransactionType.transfer) {
      final transferAccounts = _matchTransferAccounts(lower, accounts);
      fromAccountId = transferAccounts.fromId;
      toAccountId = transferAccounts.toId;
    } else {
      accountId = _matchSingleAccount(lower, accounts, type);
    }

    // 5. Match Category (only for Income / Expense)
    String? categoryId;
    if (type != TransactionType.transfer) {
      final catType = type == TransactionType.income
          ? CategoryType.income
          : CategoryType.expense;
      categoryId = _matchCategory(lower, categories, catType);
    }

    // 6. Generate Clean Note
    final note = _generateCleanNote(
      line,
      amountResult.rawMatch,
      dateResult.rawMatch,
    );

    return ParsedDraftTransaction(
      id: id,
      type: type,
      amount: amount,
      accountId: accountId,
      categoryId: categoryId,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      date: date,
      note: note,
      rawText: line,
    );
  }

  _AmountResult? _extractAmount(String text) {
    // Matches: ₹ 450, 450.50, rs 1200, 5k, 1.5l, inr 5000, 10,000
    final regExp = RegExp(
      r'(?:₹|rs\.?|inr)?\s*([0-9]+(?:,[0-9]+)*(?:\.[0-9]{1,2})?)\s*(k|lakhs?|l)?\b',
      caseSensitive: false,
    );

    final match = regExp.firstMatch(text);
    if (match == null) return null;

    final numStr = match.group(1)?.replaceAll(',', '') ?? '';
    final multiplierStr = match.group(2)?.toLowerCase();
    double? parsedNum = double.tryParse(numStr);
    if (parsedNum == null || parsedNum <= 0) return null;

    if (multiplierStr == 'k') {
      parsedNum *= 1000;
    } else if (multiplierStr == 'l' ||
        multiplierStr == 'lakh' ||
        multiplierStr == 'lakhs') {
      parsedNum *= 100000;
    }

    return _AmountResult(amount: parsedNum, rawMatch: match.group(0) ?? '');
  }

  _DateResult _extractDate(String text) {
    final now = DateTime.now();

    if (text.contains('day before yesterday')) {
      return _DateResult(
        date: now.subtract(const Duration(days: 2)),
        rawMatch: 'day before yesterday',
      );
    }
    if (text.contains('yesterday')) {
      return _DateResult(
        date: now.subtract(const Duration(days: 1)),
        rawMatch: 'yesterday',
      );
    }
    if (text.contains('today')) {
      return _DateResult(date: now, rawMatch: 'today');
    }

    // Check for "X days ago"
    final daysAgoMatch = RegExp(r'(\d+)\s+days?\s+ago').firstMatch(text);
    if (daysAgoMatch != null) {
      final days = int.tryParse(daysAgoMatch.group(1) ?? '0') ?? 0;
      return _DateResult(
        date: now.subtract(Duration(days: days)),
        rawMatch: daysAgoMatch.group(0) ?? '',
      );
    }

    // Default to today
    return _DateResult(date: now, rawMatch: '');
  }

  bool _isTransfer(String text) {
    final transferKeywords = [
      'transfer',
      'transferred',
      'sent to',
      'moved to',
      'paid to card',
      'to credit card',
      'to bank',
      'from sbi to',
      'from hdfc to',
      'from icici to',
      'from cash to',
    ];
    return transferKeywords.any((kw) => text.contains(kw));
  }

  bool _isIncome(String text) {
    final incomeKeywords = [
      'salary',
      'credited',
      'received',
      'refund',
      'dividend',
      'cashback',
      'bonus',
      'freelance',
      'earned',
      'stipend',
      'interest received',
      'income',
      'gift received',
      'sold',
    ];
    return incomeKeywords.any((kw) => text.contains(kw));
  }

  _TransferAccountsResult _matchTransferAccounts(
    String text,
    List<Account> accounts,
  ) {
    if (accounts.isEmpty) return const _TransferAccountsResult();

    String? fromId;
    String? toId;

    // Pattern: from [Account] to [Account]
    for (final acc in accounts) {
      final accName = acc.name.toLowerCase();
      if (text.contains('from $accName')) {
        fromId = acc.id;
      }
      if (text.contains('to $accName') ||
          text.contains('into $accName') ||
          text.contains('for $accName')) {
        toId = acc.id;
      }
    }

    // If not matched by explicit "from/to", match by name mention
    if (fromId == null || toId == null) {
      for (final acc in accounts) {
        final accName = acc.name.toLowerCase();
        if (text.contains(accName)) {
          if (fromId == null) {
            fromId = acc.id;
          } else if (toId == null && acc.id != fromId) {
            toId = acc.id;
          }
        }
      }
    }

    // Fallbacks
    if (fromId == null && accounts.isNotEmpty) {
      fromId = accounts.first.id;
    }
    if (toId == null && accounts.length > 1) {
      toId = accounts.firstWhere((a) => a.id != fromId).id;
    }

    return _TransferAccountsResult(fromId: fromId, toId: toId);
  }

  String? _matchSingleAccount(
    String text,
    List<Account> accounts,
    TransactionType type,
  ) {
    if (accounts.isEmpty) return null;

    // 1. Direct name match or distinctive word match (e.g. "hdfc", "sbi", "icici")
    for (final acc in accounts) {
      final nameLower = acc.name.toLowerCase();
      if (text.contains(nameLower)) {
        return acc.id;
      }
      final words = nameLower.split(RegExp(r'\s+')).where((w) => w.length >= 3);
      for (final word in words) {
        if (word != 'bank' &&
            word != 'card' &&
            word != 'credit' &&
            word != 'account' &&
            word != 'wallet' &&
            text.contains(word)) {
          return acc.id;
        }
      }
    }

    // 2. Generic keyword match (card, credit, cash, bank, upi, wallet)
    if (text.contains('credit card') ||
        text.contains('card') ||
        text.contains('cc')) {
      final cc = accounts
          .where((a) => a.type == AccountType.creditCard)
          .firstOrNull;
      if (cc != null) return cc.id;
    }

    if (text.contains('cash')) {
      final cash = accounts
          .where((a) => a.type == AccountType.cash)
          .firstOrNull;
      if (cash != null) return cash.id;
    }

    if (text.contains('bank') ||
        text.contains('upi') ||
        text.contains('gpay') ||
        text.contains('paytm')) {
      final bank = accounts
          .where((a) => a.type == AccountType.bank)
          .firstOrNull;
      if (bank != null) return bank.id;
    }

    // Default to first active account
    return accounts.first.id;
  }

  String? _matchCategory(
    String text,
    List<Category> categories,
    CategoryType targetType,
  ) {
    final filteredCategories = categories
        .where((c) => c.type == targetType && c.active)
        .toList();
    if (filteredCategories.isEmpty) return null;

    // 1. Direct category name match
    for (final cat in filteredCategories) {
      if (text.contains(cat.name.toLowerCase())) {
        return cat.id;
      }
    }

    // 2. Semantic Dictionary
    final categoryKeywords = {
      'Food & Dining': [
        'lunch',
        'dinner',
        'breakfast',
        'coffee',
        'tea',
        'zomato',
        'swiggy',
        'restaurant',
        'cafe',
        'snack',
        'burger',
        'pizza',
        'food',
        'mcdonalds',
        'starbucks',
        'kfc',
        'dominos',
        'eat',
        'dining',
        'biryani',
        'chai',
      ],
      'Groceries': [
        'grocery',
        'groceries',
        'supermarket',
        'vegetables',
        'fruits',
        'milk',
        'zepto',
        'blinkit',
        'instamart',
        'dmart',
        'ration',
        'veggies',
        'bread',
        'eggs',
        'meat',
        'chicken',
        'curd',
        'sabzi',
      ],
      'Transportation': [
        'fuel',
        'petrol',
        'diesel',
        'cng',
        'uber',
        'ola',
        'auto',
        'cab',
        'metro',
        'bus',
        'train',
        'flight',
        'ticket',
        'toll',
        'fastag',
        'parking',
        'rapido',
        'travel',
      ],
      'Bills & Utilities': [
        'electricity',
        'power',
        'water',
        'wifi',
        'internet',
        'broadband',
        'mobile',
        'recharge',
        'bill',
        'dth',
        'gas',
        'cylinder',
        'rent',
        'maintenance',
        'jio',
        'airtel',
        'vi',
      ],
      'Shopping': [
        'amazon',
        'flipkart',
        'myntra',
        'clothes',
        'shoes',
        'electronics',
        'mall',
        'shopping',
        'purchase',
        'dress',
        'shirt',
        'pants',
        'tshirt',
        'bought',
        'order',
      ],
      'Entertainment': [
        'movie',
        'cinema',
        'theatre',
        'netflix',
        'spotify',
        'hotstar',
        'prime',
        'concert',
        'game',
        'outing',
        'pub',
        'club',
        'party',
        'show',
      ],
      'Healthcare': [
        'doctor',
        'medicine',
        'medicines',
        'hospital',
        'clinic',
        'pharmacy',
        'medical',
        'test',
        'gym',
        'fitness',
        'consultation',
        'tablets',
        'apollo',
      ],
      'Salary': ['salary', 'stipend', 'wages', 'paycheck'],
      'Investment': [
        'mutual fund',
        'sip',
        'stock',
        'share',
        'fd',
        'fixed deposit',
        'gold',
      ],
    };

    for (final entry in categoryKeywords.entries) {
      final categoryKey = entry.key.toLowerCase();
      final keywords = entry.value;

      final matched = keywords.any((kw) => text.contains(kw));
      if (matched) {
        // Find user category matching categoryKey
        final matchedCat = filteredCategories.firstWhere(
          (c) =>
              c.name.toLowerCase().contains(categoryKey) ||
              categoryKey.contains(c.name.toLowerCase()),
          orElse: () => filteredCategories.first,
        );
        return matchedCat.id;
      }
    }

    // Default to first available category of the target type
    return filteredCategories.first.id;
  }

  String _generateCleanNote(
    String originalLine,
    String rawAmount,
    String rawDate,
  ) {
    var clean = originalLine;
    if (rawAmount.isNotEmpty) {
      clean = clean.replaceAll(
        RegExp(RegExp.escape(rawAmount), caseSensitive: false),
        ' ',
      );
    }
    if (rawDate.isNotEmpty) {
      clean = clean.replaceAll(
        RegExp(RegExp.escape(rawDate), caseSensitive: false),
        ' ',
      );
    }

    // Remove common connecting noise words
    clean = clean.replaceAll(
      RegExp(
        r'\b(paid|spent|bought|for|using|via|on|from|to|in|with|of|at|rs\.?|inr|₹|yesterday|today|credited|transferred)\b',
        caseSensitive: false,
      ),
      ' ',
    );
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (clean.isEmpty) {
      return originalLine.trim();
    }

    // Capitalize first letter
    return clean[0].toUpperCase() + clean.substring(1);
  }
}

class _AmountResult {
  final double amount;
  final String rawMatch;
  const _AmountResult({required this.amount, required this.rawMatch});
}

class _DateResult {
  final DateTime date;
  final String rawMatch;
  const _DateResult({required this.date, required this.rawMatch});
}

class _TransferAccountsResult {
  final String? fromId;
  final String? toId;
  const _TransferAccountsResult({this.fromId, this.toId});
}
