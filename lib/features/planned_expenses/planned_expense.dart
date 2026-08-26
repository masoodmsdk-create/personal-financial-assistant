import 'package:flutter/material.dart';
import 'package:personal_financial_assistant/core/models/entity.dart';

enum RecurrenceFrequency {
  daily('daily'),
  monthly('monthly'),
  weekly('weekly'),
  quarterly('quarterly'),
  halfYearly('half_yearly'),
  yearly('yearly'),
  oneTime('one_time');

  final String value;
  const RecurrenceFrequency(this.value);
}

extension RecurrenceFrequencyX on RecurrenceFrequency {
  static RecurrenceFrequency fromString(String val) {
    return RecurrenceFrequency.values.firstWhere(
      (e) => e.value == val,
      orElse: () => RecurrenceFrequency.monthly,
    );
  }

  String get displayName {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.quarterly:
        return 'Quarterly';
      case RecurrenceFrequency.halfYearly:
        return 'Half-Yearly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
      case RecurrenceFrequency.oneTime:
        return 'One-Time';
    }
  }

  IconData get icon {
    switch (this) {
      case RecurrenceFrequency.daily:
        return Icons.today_rounded;
      case RecurrenceFrequency.monthly:
        return Icons.calendar_month_rounded;
      case RecurrenceFrequency.weekly:
        return Icons.calendar_view_week_rounded;
      case RecurrenceFrequency.quarterly:
        return Icons.pie_chart_outline_rounded;
      case RecurrenceFrequency.halfYearly:
        return Icons.date_range_rounded;
      case RecurrenceFrequency.yearly:
        return Icons.event_repeat_rounded;
      case RecurrenceFrequency.oneTime:
        return Icons.event_rounded;
    }
  }
}

class PlannedExpense implements Entity {
  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final String name;
  final String categoryId;
  final double defaultAmount;
  final RecurrenceFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final bool active;
  final String? accountId;

  const PlannedExpense({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.categoryId,
    required this.defaultAmount,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.active = true,
    this.accountId,
  });

  factory PlannedExpense.fromJson(Map<String, dynamic> json) {
    return PlannedExpense(
      id: json['id'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      name: json['name'] as String,
      categoryId: json['categoryId'] as String,
      defaultAmount: (json['defaultAmount'] as num).toDouble(),
      frequency: RecurrenceFrequencyX.fromString(json['frequency'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      active: json['active'] as bool? ?? true,
      accountId: json['accountId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'name': name,
      'categoryId': categoryId,
      'defaultAmount': defaultAmount,
      'frequency': frequency.value,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'active': active,
      'accountId': accountId,
    };
  }

  PlannedExpense copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? categoryId,
    double? defaultAmount,
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
    String? accountId,
  }) {
    return PlannedExpense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      defaultAmount: defaultAmount ?? this.defaultAmount,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      active: active ?? this.active,
      accountId: accountId ?? this.accountId,
    );
  }

  /// Helper to check if this planned expense applies to a specific year & month.
  bool appliesToMonth(int year, int month) {
    if (!active) return false;

    final targetStart = DateTime(year, month, 1);
    final targetEnd = DateTime(year, month + 1, 0, 23, 59, 59);

    // If start date is after the month end, it does not apply
    if (startDate.isAfter(targetEnd)) return false;

    // If end date is specified and before the month start, it does not apply
    if (endDate != null && endDate!.isBefore(targetStart)) return false;

    switch (frequency) {
      case RecurrenceFrequency.daily:
      case RecurrenceFrequency.monthly:
      case RecurrenceFrequency.weekly:
        return true;
      case RecurrenceFrequency.quarterly:
        // Quarterly: matches starting month and every 3 months
        final monthsDiff =
            (year - startDate.year) * 12 + (month - startDate.month);
        return monthsDiff >= 0 && monthsDiff % 3 == 0;
      case RecurrenceFrequency.halfYearly:
        // Half-yearly: matches starting month and 6 months later
        final monthsDiff =
            (year - startDate.year) * 12 + (month - startDate.month);
        return monthsDiff >= 0 && monthsDiff % 6 == 0;
      case RecurrenceFrequency.yearly:
        return month == startDate.month;
      case RecurrenceFrequency.oneTime:
        return startDate.year == year && startDate.month == month;
    }
  }
}
