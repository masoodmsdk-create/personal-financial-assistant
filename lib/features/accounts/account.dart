import 'package:flutter/material.dart';
import 'package:personal_financial_assistant/core/models/entity.dart';

class Account implements Entity {
  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final String name;
  final AccountType type;
  final double openingBalance;
  final String currency;
  final bool active;
  final double? currentBalance;

  const Account({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.currency,
    required this.active,
    this.currentBalance,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      name: json['name'] as String,
      type: AccountTypeX.fromString(json['type'] as String),
      openingBalance: (json['openingBalance'] as num).toDouble(),
      currency: json['currency'] as String,
      active: json['active'] as bool,
      currentBalance: json['currentBalance'] != null
          ? (json['currentBalance'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'name': name,
      'type': type.value,
      'openingBalance': openingBalance,
      'currency': currency,
      'active': active,
      'currentBalance': currentBalance,
    };
  }

  Account copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    AccountType? type,
    double? openingBalance,
    String? currency,
    bool? active,
    double? currentBalance,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      currency: currency ?? this.currency,
      active: active ?? this.active,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }
}

enum AccountType {
  bank('bank'),
  cash('cash'),
  creditCard('credit_card'),
  wallet('wallet'),
  other('other');

  final String value;
  const AccountType(this.value);
}

extension AccountTypeX on AccountType {
  static AccountType fromString(String val) {
    return AccountType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => AccountType.other,
    );
  }

  String get displayName {
    switch (this) {
      case AccountType.bank:
        return 'Bank Account';
      case AccountType.cash:
        return 'Cash';
      case AccountType.creditCard:
        return 'Credit Card';
      case AccountType.wallet:
        return 'Wallet';
      case AccountType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case AccountType.bank:
        return Icons.account_balance;
      case AccountType.cash:
        return Icons.money;
      case AccountType.creditCard:
        return Icons.credit_card;
      case AccountType.wallet:
        return Icons.wallet;
      case AccountType.other:
        return Icons.category;
    }
  }

  Color get color {
    switch (this) {
      case AccountType.bank:
        return const Color(0xFF1B5E20);
      case AccountType.cash:
        return const Color(0xFFE65100);
      case AccountType.creditCard:
        return const Color(0xFF0D47A1);
      case AccountType.wallet:
        return const Color(0xFF4A148C);
      case AccountType.other:
        return const Color(0xFF37474F);
    }
  }
}

extension AccountX on Account {
  double get effectiveBalance => currentBalance ?? openingBalance;

  bool get isCreditAccount => type == AccountType.creditCard;

  Account copyWithUpdatedBalance(double newBalance) {
    return copyWith(currentBalance: newBalance, updatedAt: DateTime.now());
  }
}
