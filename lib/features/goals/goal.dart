import 'package:flutter/material.dart';
import 'package:personal_financial_assistant/core/models/entity.dart';

enum GoalType { savingsGoal, debtGoal, emergencyFund, customGoal }

extension GoalTypeX on GoalType {
  String get value {
    switch (this) {
      case GoalType.savingsGoal:
        return 'savingsGoal';
      case GoalType.debtGoal:
        return 'debtGoal';
      case GoalType.emergencyFund:
        return 'emergencyFund';
      case GoalType.customGoal:
        return 'customGoal';
    }
  }

  String get displayName {
    switch (this) {
      case GoalType.savingsGoal:
        return 'Savings Goal';
      case GoalType.debtGoal:
        return 'Debt Payoff Goal';
      case GoalType.emergencyFund:
        return 'Emergency Reserve';
      case GoalType.customGoal:
        return 'Custom Goal';
    }
  }

  IconData get icon {
    switch (this) {
      case GoalType.savingsGoal:
        return Icons.savings_outlined;
      case GoalType.debtGoal:
        return Icons.money_off_outlined;
      case GoalType.emergencyFund:
        return Icons.health_and_safety_outlined;
      case GoalType.customGoal:
        return Icons.flag_outlined;
    }
  }

  Color get color {
    switch (this) {
      case GoalType.savingsGoal:
        return Colors.green;
      case GoalType.debtGoal:
        return Colors.orange;
      case GoalType.emergencyFund:
        return Colors.teal;
      case GoalType.customGoal:
        return Colors.blue;
    }
  }

  static GoalType fromString(String val) {
    return GoalType.values.firstWhere(
      (e) => e.value == val || e.name == val,
      orElse: () => GoalType.customGoal,
    );
  }
}

class Goal implements Entity {
  @override
  final String id;
  @override
  final String userId;
  final String name;
  final GoalType type;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String? linkedLoanId;
  final String? linkedAccountId;
  final String? notes;
  final bool active;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  const Goal({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    this.linkedLoanId,
    this.linkedAccountId,
    this.notes,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return ((currentAmount / targetAmount) * 100.0).clamp(0.0, 100.0);
  }

  double get remainingAmount {
    final diff = targetAmount - currentAmount;
    return diff > 0 ? diff : 0.0;
  }

  bool get isCompleted => currentAmount >= targetAmount;

  Goal copyWith({
    String? id,
    String? userId,
    String? name,
    GoalType? type,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? linkedLoanId,
    String? linkedAccountId,
    String? notes,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      linkedLoanId: linkedLoanId ?? this.linkedLoanId,
      linkedAccountId: linkedAccountId ?? this.linkedAccountId,
      notes: notes ?? this.notes,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type.value,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate?.toIso8601String(),
      'linkedLoanId': linkedLoanId,
      'linkedAccountId': linkedAccountId,
      'notes': notes,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      type: GoalTypeX.fromString(json['type'] as String? ?? 'customGoal'),
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num? ?? 0.0).toDouble(),
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      linkedLoanId: json['linkedLoanId'] as String?,
      linkedAccountId: json['linkedAccountId'] as String?,
      notes: json['notes'] as String?,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
