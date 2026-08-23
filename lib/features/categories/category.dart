import 'package:flutter/material.dart';
import 'package:personal_financial_assistant/core/models/entity.dart';

enum CategoryType {
  income('income'),
  expense('expense');

  final String value;
  const CategoryType(this.value);
}

extension CategoryTypeX on CategoryType {
  static CategoryType fromString(String val) {
    return CategoryType.values.firstWhere(
      (e) => e.value == val,
      orElse: () => CategoryType.expense,
    );
  }

  String get displayName {
    switch (this) {
      case CategoryType.income:
        return 'Income';
      case CategoryType.expense:
        return 'Expense';
    }
  }

  IconData get icon {
    switch (this) {
      case CategoryType.income:
        return Icons.arrow_downward_rounded;
      case CategoryType.expense:
        return Icons.arrow_upward_rounded;
    }
  }

  Color get color {
    switch (this) {
      case CategoryType.income:
        return const Color(0xFF2E7D32); // Green
      case CategoryType.expense:
        return const Color(0xFFC62828); // Red
    }
  }
}

class Category implements Entity {
  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final String name;
  final CategoryType type;
  final bool active;
  final bool isDefault;
  final int sortOrder;

  const Category({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.type,
    this.active = true,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      name: json['name'] as String,
      type: CategoryTypeX.fromString(json['type'] as String),
      active: json['active'] as bool? ?? true,
      isDefault: json['isDefault'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
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
      'active': active,
      'isDefault': isDefault,
      'sortOrder': sortOrder,
    };
  }

  Category copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    CategoryType? type,
    bool? active,
    bool? isDefault,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      type: type ?? this.type,
      active: active ?? this.active,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  static List<Category> generateDefaults(String userId, {DateTime? now}) {
    final timestamp = now ?? DateTime.now();

    final incomeDefaults = [
      'Salary',
      'Business Income',
      'Freelance',
      'Rental Income',
      'Interest',
      'Other Income',
    ];

    final expenseDefaults = [
      'Food',
      'Groceries',
      'Rent',
      'Utilities',
      'Transport',
      'Healthcare',
      'Education',
      'Shopping',
      'Entertainment',
      'EMI / Loan Payment',
      'Other Expense',
    ];

    final categories = <Category>[];

    for (int i = 0; i < incomeDefaults.length; i++) {
      categories.add(
        Category(
          id: 'default_inc_$i',
          userId: userId,
          name: incomeDefaults[i],
          type: CategoryType.income,
          active: true,
          isDefault: true,
          sortOrder: i,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
    }

    for (int i = 0; i < expenseDefaults.length; i++) {
      categories.add(
        Category(
          id: 'default_exp_$i',
          userId: userId,
          name: expenseDefaults[i],
          type: CategoryType.expense,
          active: true,
          isDefault: true,
          sortOrder: i,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
    }

    return categories;
  }
}
