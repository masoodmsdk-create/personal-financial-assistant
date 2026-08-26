import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

/// Represents an uncommitted parsed transaction draft extracted from free-form natural language text.
class ParsedDraftTransaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String? accountId;
  final String? categoryId;
  final String? fromAccountId;
  final String? toAccountId;
  final DateTime date;
  final String note;
  final String rawText;
  final double confidence;

  // Recurrence properties
  final bool isRecurring;
  final RecurrenceFrequency? frequency;
  final int interval;
  final int? dayOfMonth;
  final int? dayOfWeek;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? ruleName;

  const ParsedDraftTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.accountId,
    this.categoryId,
    this.fromAccountId,
    this.toAccountId,
    required this.date,
    required this.note,
    required this.rawText,
    this.confidence = 1.0,
    this.isRecurring = false,
    this.frequency,
    this.interval = 1,
    this.dayOfMonth,
    this.dayOfWeek,
    this.startDate,
    this.endDate,
    this.ruleName,
  });

  ParsedDraftTransaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    String? accountId,
    String? categoryId,
    String? fromAccountId,
    String? toAccountId,
    DateTime? date,
    String? note,
    String? rawText,
    double? confidence,
    bool? isRecurring,
    RecurrenceFrequency? frequency,
    int? interval,
    int? dayOfMonth,
    int? dayOfWeek,
    DateTime? startDate,
    DateTime? endDate,
    String? ruleName,
  }) {
    return ParsedDraftTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      date: date ?? this.date,
      note: note ?? this.note,
      rawText: rawText ?? this.rawText,
      confidence: confidence ?? this.confidence,
      isRecurring: isRecurring ?? this.isRecurring,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      ruleName: ruleName ?? this.ruleName,
    );
  }
}
