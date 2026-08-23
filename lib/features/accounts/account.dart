import 'package:flutter/material.dart';
import 'package:personal_financial_assistant/core/models/entity.dart';
import 'package:personal_financial_assistant/features/accounts/domain/models/account_type_definition.dart';

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
  final String accountTypeId;
  final AccountNature nature;
  final double openingBalance;
  final String currency;
  final bool active;

  Account({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.type,
    String? accountTypeId,
    AccountNature? nature,
    required this.openingBalance,
    required this.currency,
    required this.active,
  }) : accountTypeId = accountTypeId ?? type.value,
       nature =
           nature ??
           (type == AccountType.creditCard
               ? AccountNature.liability
               : AccountNature.asset);

  factory Account.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String? ?? 'bank';
    final rawTypeId = json['accountTypeId'] as String? ?? rawType;
    final enumType = AccountTypeX.fromString(rawType);
    final rawNature = json['nature'] as String?;
    final natureVal = rawNature != null
        ? AccountNature.fromString(rawNature)
        : (rawTypeId == 'credit_card' || enumType == AccountType.creditCard
              ? AccountNature.liability
              : AccountNature.asset);

    return Account(
      id: json['id'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      name: json['name'] as String,
      type: enumType,
      accountTypeId: rawTypeId,
      nature: natureVal,
      openingBalance: (json['openingBalance'] as num).toDouble(),
      currency: json['currency'] as String,
      active: json['active'] as bool,
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
      'accountTypeId': accountTypeId,
      'nature': nature.value,
      'openingBalance': openingBalance,
      'currency': currency,
      'active': active,
    };
  }

  Account copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    AccountType? type,
    String? accountTypeId,
    AccountNature? nature,
    double? openingBalance,
    String? currency,
    bool? active,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      type: type ?? this.type,
      accountTypeId: accountTypeId ?? this.accountTypeId,
      nature: nature ?? this.nature,
      openingBalance: openingBalance ?? this.openingBalance,
      currency: currency ?? this.currency,
      active: active ?? this.active,
    );
  }
}

enum AccountType {
  bank('bank'),
  cash('cash'),
  creditCard('credit_card'),
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
      case AccountType.other:
        return const Color(0xFF37474F);
    }
  }
}

extension AccountX on Account {
  double get effectiveBalance => openingBalance;

  bool get isCreditAccount =>
      type == AccountType.creditCard || accountTypeId == 'credit_card';

  bool get isLiabilityAccount =>
      nature == AccountNature.liability || isCreditAccount;
}
