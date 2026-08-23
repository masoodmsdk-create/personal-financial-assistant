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
    );
  }
}
