// ignore_for_file: non_const_argument_for_const_parameter

import 'package:flutter/material.dart';
import 'package:personal_financial_assistant/core/models/entity.dart';

enum AccountNature {
  asset('asset'),
  liability('liability');

  final String value;
  const AccountNature(this.value);

  static AccountNature fromString(String val) {
    return AccountNature.values.firstWhere(
      (e) => e.value == val,
      orElse: () => AccountNature.asset,
    );
  }

  String get displayName {
    switch (this) {
      case AccountNature.asset:
        return 'Asset';
      case AccountNature.liability:
        return 'Liability';
    }
  }

  String get explanation {
    switch (this) {
      case AccountNature.asset:
        return 'Asset increases your net worth.';
      case AccountNature.liability:
        return 'Liability reduces your net worth.';
    }
  }
}

class AccountTypeDefinition implements Entity {
  @override
  final String id;
  @override
  final String userId; // 'system' for defaults, uid for custom
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final String name;
  final AccountNature nature;
  final IconData icon;
  final Color color;
  final bool active;
  final bool isDefault;
  final int sortOrder;

  const AccountTypeDefinition({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.nature,
    required this.icon,
    required this.color,
    required this.active,
    required this.isDefault,
    required this.sortOrder,
  });

  factory AccountTypeDefinition.fromJson(Map<String, dynamic> json) {
    return AccountTypeDefinition(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? 'system',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      name: json['name'] as String,
      nature: AccountNature.fromString(json['nature'] as String),
      icon: _iconFromCode(json['iconCode'] as int?),
      color: Color(json['colorValue'] as int? ?? 0xFF1B5E20),
      active: json['active'] as bool? ?? true,
      isDefault: json['isDefault'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'name': name,
      'nature': nature.value,
      'iconCode': icon.codePoint,
      'colorValue': color.toARGB32(),
      'active': active,
      'isDefault': isDefault,
      'sortOrder': sortOrder,
    };
  }

  AccountTypeDefinition copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    AccountNature? nature,
    IconData? icon,
    Color? color,
    bool? active,
    bool? isDefault,
    int? sortOrder,
  }) {
    return AccountTypeDefinition(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      nature: nature ?? this.nature,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      active: active ?? this.active,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  static IconData _iconFromCode(int? code) {
    if (code == null) return Icons.account_balance_wallet;
    // Map common icon codePoints to const IconData for Flutter Web tree shaking
    const map = <int, IconData>{
      0xe040: Icons.account_balance,
      0xe041: Icons.account_balance_wallet,
      0xe19f: Icons.credit_card,
      0xe154: Icons.category,
      0xe5d0: Icons.savings,
      0xe39d: Icons.monetization_on,
      0xe57f: Icons.shield,
      0xe6e4: Icons.work,
      0xe425: Icons.people,
      0xe1d7: Icons.store,
    };
    return map[code] ?? Icons.account_balance_wallet;
  }

  // System Default Account Types
  static final List<AccountTypeDefinition> defaultTypes = [
    AccountTypeDefinition(
      id: 'bank',
      userId: 'system',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      name: 'Bank Account',
      nature: AccountNature.asset,
      icon: Icons.account_balance,
      color: const Color(0xFF1B5E20),
      active: true,
      isDefault: true,
      sortOrder: 1,
    ),
    AccountTypeDefinition(
      id: 'cash',
      userId: 'system',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      name: 'Cash',
      nature: AccountNature.asset,
      icon: Icons.money,
      color: const Color(0xFFE65100),
      active: true,
      isDefault: true,
      sortOrder: 2,
    ),
    AccountTypeDefinition(
      id: 'credit_card',
      userId: 'system',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      name: 'Credit Card',
      nature: AccountNature.liability,
      icon: Icons.credit_card,
      color: const Color(0xFF0D47A1),
      active: true,
      isDefault: true,
      sortOrder: 3,
    ),
    AccountTypeDefinition(
      id: 'other',
      userId: 'system',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      name: 'Other',
      nature: AccountNature.asset,
      icon: Icons.category,
      color: const Color(0xFF37474F),
      active: true,
      isDefault: true,
      sortOrder: 4,
    ),
  ];
}
