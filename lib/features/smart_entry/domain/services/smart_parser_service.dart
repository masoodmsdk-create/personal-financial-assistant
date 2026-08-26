import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/smart_entry/domain/models/parsed_draft_transaction.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

/// Pure deterministic natural-language parsing engine for free-form financial entries and recurring commitments.
class SmartParserService {
  const SmartParserService();

  /// Parses unstructured multi-line or single-line text into a list of draft transactions or recurring rules.
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
      return null; // A financial entry must have an amount
    }
    final amount = amountResult.amount;

    // 2. Detect Recurrence Intent BEFORE One-Time Date Fallback
    final recurrence = _extractRecurrence(lower);
    final isRecurring = recurrence.isRecurring;

    // 3. Extract Date (only used when not recurring or as start date)
    final dateResult = _extractDate(lower);
    final now = DateTime.now();
    final date = isRecurring ? now : dateResult.date;

    // 4. Detect Transaction Type
    final isTransfer = !isRecurring && _isTransfer(lower);
    final isIncome = !isTransfer && _isIncome(lower);
    final type = isTransfer
        ? TransactionType.transfer
        : (isIncome ? TransactionType.income : TransactionType.expense);

    // 5. Match Accounts
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

    // 6. Match Category (only for Income / Expense)
    String? categoryId;
    if (type != TransactionType.transfer) {
      final catType = type == TransactionType.income
          ? CategoryType.income
          : CategoryType.expense;
      categoryId = _matchCategory(lower, categories, catType);
    }

    // 7. Generate Clean Note / Rule Name
    final note = _generateCleanNote(
      line,
      amountResult.rawMatch,
      dateResult.rawMatch,
      recurrence.rawMatch,
    );

    final ruleName = isRecurring
        ? _generateRuleName(note, type, recurrence.frequency)
        : null;

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
      isRecurring: isRecurring,
      frequency: recurrence.frequency,
      interval: recurrence.interval,
      dayOfMonth: recurrence.dayOfMonth,
      dayOfWeek: recurrence.dayOfWeek,
      startDate: isRecurring ? now : null,
      ruleName: ruleName,
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

  _RecurrenceResult _extractRecurrence(String text) {
    // 1. Check for specific interval patterns: "every N (days|weeks|months|years|quarters)"
    final everyNMatch = RegExp(
      r'\bevery\s+(\d+)\s*(days?|weeks?|months?|years?|quarters?)\b',
      caseSensitive: false,
    ).firstMatch(text);

    if (everyNMatch != null) {
      final interval = int.tryParse(everyNMatch.group(1) ?? '1') ?? 1;
      final unit = everyNMatch.group(2)!.toLowerCase();
      RecurrenceFrequency freq = RecurrenceFrequency.monthly;
      if (unit.startsWith('day')) {
        freq = RecurrenceFrequency.daily;
      } else if (unit.startsWith('week')) {
        freq = RecurrenceFrequency.weekly;
      } else if (unit.startsWith('month')) {
        freq = RecurrenceFrequency.monthly;
      } else if (unit.startsWith('year')) {
        freq = RecurrenceFrequency.yearly;
      } else if (unit.startsWith('quarter')) {
        freq = RecurrenceFrequency.quarterly;
      }

      return _RecurrenceResult(
        isRecurring: true,
        frequency: freq,
        interval: interval,
        dayOfMonth: _extractDayOfMonth(text),
        dayOfWeek: _extractDayOfWeek(text),
        rawMatch: everyNMatch.group(0) ?? '',
      );
    }

    // 2. Multi-month/year phrase variations
    // Every 2 months / Bi-monthly
    if (RegExp(
      r'\b(?:every\s+2\s+months?|every\s+two\s+months?|bimonthly|bi-monthly)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return _RecurrenceResult(
        isRecurring: true,
        frequency: RecurrenceFrequency.monthly,
        interval: 2,
        dayOfMonth: _extractDayOfMonth(text),
        rawMatch: 'every 2 months',
      );
    }

    // Every 3 months / Quarterly
    if (RegExp(
      r'\b(?:every\s+3\s+months?|every\s+three\s+months?|every\s+quarter|quarterly|each\s+quarter)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return _RecurrenceResult(
        isRecurring: true,
        frequency: RecurrenceFrequency.quarterly,
        interval: 1,
        dayOfMonth: _extractDayOfMonth(text),
        rawMatch: 'quarterly',
      );
    }

    // Every 6 months / Half-yearly
    if (RegExp(
      r'\b(?:every\s+6\s+months?|every\s+six\s+months?|half-yearly|half\s+yearly|semi-annually|semi\s+annually|biannually)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return _RecurrenceResult(
        isRecurring: true,
        frequency: RecurrenceFrequency.halfYearly,
        interval: 1,
        dayOfMonth: _extractDayOfMonth(text),
        rawMatch: 'half-yearly',
      );
    }

    // Every Fortnight / 2 Weeks
    if (RegExp(
      r'\b(?:every\s+fortnight|fortnightly|every\s+2\s+weeks?|every\s+two\s+weeks?)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return _RecurrenceResult(
        isRecurring: true,
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
        dayOfWeek: _extractDayOfWeek(text),
        rawMatch: 'fortnightly',
      );
    }

    // 3. Daily / Weekly / Monthly / Yearly base phrases
    // Daily
    if (RegExp(
      r'\b(?:every\s+day|each\s+day|daily|per\s+day)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return const _RecurrenceResult(
        isRecurring: true,
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        rawMatch: 'daily',
      );
    }

    // Weekly
    if (RegExp(
      r'\b(?:every\s+week|each\s+week|weekly|per\s+week)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return _RecurrenceResult(
        isRecurring: true,
        frequency: RecurrenceFrequency.weekly,
        interval: 1,
        dayOfWeek: _extractDayOfWeek(text),
        rawMatch: 'weekly',
      );
    }

    // Specific weekdays: "every monday", "every week on friday", "weekly on tuesday"
    final dowMatch = _extractDayOfWeek(text);
    if (dowMatch != null &&
        RegExp(
          r'\b(?:every|each|weekly\s+on)\s+(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun)\b',
          caseSensitive: false,
        ).hasMatch(text)) {
      return _RecurrenceResult(
        isRecurring: true,
        frequency: RecurrenceFrequency.weekly,
        interval: 1,
        dayOfWeek: dowMatch,
        rawMatch: 'weekly',
      );
    }

    // Monthly
    if (RegExp(
      r'\b(?:every\s+month|each\s+month|monthly|per\s+month|a\s+month)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return _RecurrenceResult(
        isRecurring: true,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        dayOfMonth: _extractDayOfMonth(text),
        rawMatch: 'monthly',
      );
    }

    // Yearly / Annually
    if (RegExp(
      r'\b(?:every\s+year|each\s+year|yearly|annually|annual|per\s+year|a\s+year)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return _RecurrenceResult(
        isRecurring: true,
        frequency: RecurrenceFrequency.yearly,
        interval: 1,
        dayOfMonth: _extractDayOfMonth(text),
        rawMatch: 'yearly',
      );
    }

    // 4. Contextual & Explicit "recurring" keywords
    // e.g. "salary credited monthly", "salary comes every month", "rent paid every month", "recurring 5000 sip"
    if (RegExp(
      r'\b(?:recurring|subscription\s+monthly|sip\s+monthly|emi\s+monthly)\b',
      caseSensitive: false,
    ).hasMatch(text)) {
      return _RecurrenceResult(
        isRecurring: true,
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        dayOfMonth: _extractDayOfMonth(text),
        rawMatch: 'recurring',
      );
    }

    return const _RecurrenceResult(isRecurring: false);
  }

  int? _extractDayOfMonth(String text) {
    // Matches patterns like:
    // "on the 1st every month", "every month on the 1st", "on 1st of every month", "on 5th of each month", "15th of every month", "every month 1st", "monthly on the 1st", "on the 5th"
    final match = RegExp(
      r'(?:on\s+(?:the\s+)?)?(\d{1,2})(?:st|nd|rd|th)?\s+(?:of\s+)?(?:every\s+month|each\s+month|monthly|every\s+year|yearly)|\b(?:every\s+month|each\s+month|monthly|every\s+year|yearly)\s+(?:on\s+(?:the\s+)?)?(\d{1,2})(?:st|nd|rd|th)?|\bon\s+(?:the\s+)?(\d{1,2})(?:st|nd|rd|th)?\b',
      caseSensitive: false,
    ).firstMatch(text);

    if (match != null) {
      final dayStr = match.group(1) ?? match.group(2) ?? match.group(3);
      if (dayStr != null) {
        final day = int.tryParse(dayStr);
        if (day != null && day >= 1 && day <= 31) {
          return day;
        }
      }
    }
    return null;
  }

  int? _extractDayOfWeek(String text) {
    final days = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
      'mon': 1,
      'tue': 2,
      'wed': 3,
      'thu': 4,
      'fri': 5,
      'sat': 6,
      'sun': 7,
    };
    for (final entry in days.entries) {
      if (RegExp('\\b${entry.key}\\b', caseSensitive: false).hasMatch(text)) {
        return entry.value;
      }
    }
    return null;
  }

  String _generateRuleName(
    String cleanNote,
    TransactionType type,
    RecurrenceFrequency? frequency,
  ) {
    if (cleanNote.isNotEmpty && cleanNote != 'Transaction') {
      return cleanNote;
    }
    final freqName = frequency?.displayName ?? 'Recurring';
    return '$freqName ${type.displayName}';
  }

  String _generateCleanNote(
    String originalLine,
    String rawAmount,
    String rawDate,
    String rawRecurrence,
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
    if (rawRecurrence.isNotEmpty) {
      clean = clean.replaceAll(
        RegExp(RegExp.escape(rawRecurrence), caseSensitive: false),
        ' ',
      );
    }

    // Remove common recurrence words & noise words
    clean = clean.replaceAll(
      RegExp(
        r'\b(every\s+\d+\s*(?:days?|weeks?|months?|years?)|every\s+(?:day|week|month|year|fortnight|quarter|two\s+months|2\s+months)|each\s+(?:day|week|month|year)|daily|weekly|monthly|yearly|annually|quarterly|half-yearly|recurring|on\s+the\s+\d+(?:st|nd|rd|th)?|on\s+\d+(?:st|nd|rd|th)?|\d+(?:st|nd|rd|th)?\s+of\s+every\s+month|per\s+month|per\s+year|a\s+month|a\s+year|paid|spent|bought|for|using|via|on|from|to|in|with|of|at|rs\.?|inr|₹|yesterday|today|credited|transferred)\b',
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

class _RecurrenceResult {
  final bool isRecurring;
  final RecurrenceFrequency? frequency;
  final int interval;
  final int? dayOfMonth;
  final int? dayOfWeek;
  final String rawMatch;

  const _RecurrenceResult({
    required this.isRecurring,
    this.frequency,
    this.interval = 1,
    this.dayOfMonth,
    this.dayOfWeek,
    this.rawMatch = '',
  });
}

class _TransferAccountsResult {
  final String? fromId;
  final String? toId;
  const _TransferAccountsResult({this.fromId, this.toId});
}
