import 'package:personal_financial_assistant/core/models/entity.dart';

class Budget implements Entity {
  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  final int year;
  final int month;
  final String categoryId;
  final double plannedAmount;
  final String? note;
  final bool active;

  const Budget({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.year,
    required this.month,
    required this.categoryId,
    required this.plannedAmount,
    this.note,
    this.active = true,
  });

  Budget copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? year,
    int? month,
    String? categoryId,
    double? plannedAmount,
    String? note,
    bool? active,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      year: year ?? this.year,
      month: month ?? this.month,
      categoryId: categoryId ?? this.categoryId,
      plannedAmount: plannedAmount ?? this.plannedAmount,
      note: note ?? this.note,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'year': year,
      'month': month,
      'categoryId': categoryId,
      'plannedAmount': plannedAmount,
      'note': note,
      'active': active,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map, String documentId) {
    return Budget(
      id: documentId,
      userId: map['userId'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      year: map['year'] as int? ?? DateTime.now().year,
      month: map['month'] as int? ?? DateTime.now().month,
      categoryId: map['categoryId'] as String? ?? '',
      plannedAmount: (map['plannedAmount'] as num?)?.toDouble() ?? 0.0,
      note: map['note'] as String?,
      active: map['active'] as bool? ?? true,
    );
  }
}
