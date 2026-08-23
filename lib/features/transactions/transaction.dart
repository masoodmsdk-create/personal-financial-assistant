import 'package:flutter/material.dart';
import 'package:personal_financial_assistant/core/models/entity.dart';

enum TransactionType { income, expense, transfer }

extension TransactionTypeX on TransactionType {
  String get value {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
      case TransactionType.transfer:
        return 'transfer';
    }
  }

  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionType.income:
        return Icons.arrow_downward_rounded;
      case TransactionType.expense:
        return Icons.arrow_upward_rounded;
      case TransactionType.transfer:
        return Icons.swap_horiz_rounded;
    }
  }

  Color get color {
    switch (this) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
    }
  }

  static TransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      case 'transfer':
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }
}

class Transaction implements Entity {
  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  final TransactionType type;
  final double amount;
  final String? accountId;
  final String? categoryId;
  final String? fromAccountId;
  final String? toAccountId;
  final DateTime date;
  final String? note;

  const Transaction({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    required this.amount,
    this.accountId,
    this.categoryId,
    this.fromAccountId,
    this.toAccountId,
    required this.date,
    this.note,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      type: TransactionTypeX.fromString(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      accountId: json['accountId'] as String?,
      categoryId: json['categoryId'] as String?,
      fromAccountId: json['fromAccountId'] as String?,
      toAccountId: json['toAccountId'] as String?,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'type': type.value,
      'amount': amount,
      'accountId': accountId,
      'categoryId': categoryId,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  Transaction copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    TransactionType? type,
    double? amount,
    String? accountId,
    String? categoryId,
    String? fromAccountId,
    String? toAccountId,
    DateTime? date,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
