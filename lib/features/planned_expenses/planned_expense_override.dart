import 'package:personal_financial_assistant/core/models/entity.dart';

class PlannedExpenseOverride implements Entity {
  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final String planId;
  final int year;
  final int month;
  final double amount;

  const PlannedExpenseOverride({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.planId,
    required this.year,
    required this.month,
    required this.amount,
  });

  factory PlannedExpenseOverride.fromJson(Map<String, dynamic> json) {
    return PlannedExpenseOverride(
      id: json['id'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      planId: json['planId'] as String,
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'planId': planId,
      'year': year,
      'month': month,
      'amount': amount,
    };
  }

  PlannedExpenseOverride copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? planId,
    int? year,
    int? month,
    double? amount,
  }) {
    return PlannedExpenseOverride(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      planId: planId ?? this.planId,
      year: year ?? this.year,
      month: month ?? this.month,
      amount: amount ?? this.amount,
    );
  }

  static String generateId(String planId, int year, int month) {
    return 'ov_${planId}_${year}_$month';
  }
}
