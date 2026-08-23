import 'package:flutter/material.dart';
import 'package:personal_financial_assistant/core/models/entity.dart';

enum LoanType {
  homeLoan,
  personalLoan,
  carLoan,
  educationLoan,
  creditCardDebt,
  otherLoan,
}

extension LoanTypeX on LoanType {
  String get value {
    switch (this) {
      case LoanType.homeLoan:
        return 'homeLoan';
      case LoanType.personalLoan:
        return 'personalLoan';
      case LoanType.carLoan:
        return 'carLoan';
      case LoanType.educationLoan:
        return 'educationLoan';
      case LoanType.creditCardDebt:
        return 'creditCardDebt';
      case LoanType.otherLoan:
        return 'otherLoan';
    }
  }

  String get displayName {
    switch (this) {
      case LoanType.homeLoan:
        return 'Home Loan';
      case LoanType.personalLoan:
        return 'Personal Loan';
      case LoanType.carLoan:
        return 'Car Loan';
      case LoanType.educationLoan:
        return 'Education Loan';
      case LoanType.creditCardDebt:
        return 'Credit Card Debt';
      case LoanType.otherLoan:
        return 'Other Loan';
    }
  }

  IconData get icon {
    switch (this) {
      case LoanType.homeLoan:
        return Icons.home_work_outlined;
      case LoanType.personalLoan:
        return Icons.person_outline;
      case LoanType.carLoan:
        return Icons.directions_car_outlined;
      case LoanType.educationLoan:
        return Icons.school_outlined;
      case LoanType.creditCardDebt:
        return Icons.credit_card_outlined;
      case LoanType.otherLoan:
        return Icons.account_balance_wallet_outlined;
    }
  }

  Color get color {
    switch (this) {
      case LoanType.homeLoan:
        return Colors.indigo;
      case LoanType.personalLoan:
        return Colors.purple;
      case LoanType.carLoan:
        return Colors.blue;
      case LoanType.educationLoan:
        return Colors.teal;
      case LoanType.creditCardDebt:
        return Colors.orange;
      case LoanType.otherLoan:
        return Colors.blueGrey;
    }
  }

  static LoanType fromString(String val) {
    return LoanType.values.firstWhere(
      (e) => e.value == val || e.name == val,
      orElse: () => LoanType.otherLoan,
    );
  }
}

enum InterestRateType { fixed, floating }

extension InterestRateTypeX on InterestRateType {
  String get value => name;

  String get displayName {
    switch (this) {
      case InterestRateType.fixed:
        return 'Fixed Rate';
      case InterestRateType.floating:
        return 'Floating Rate';
    }
  }

  static InterestRateType fromString(String val) {
    return InterestRateType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => InterestRateType.fixed,
    );
  }
}

class Loan implements Entity {
  @override
  final String id;
  @override
  final String userId;
  final String name;
  final LoanType type;
  final double? originalPrincipal;
  final double? outstandingPrincipal;
  final double? interestRate; // Annual rate percentage, e.g. 7.5
  final InterestRateType interestRateType;
  final double? emiAmount;
  final int? remainingTenureMonths;
  final DateTime? startDate;
  final DateTime? nextEmiDate;
  final DateTime? targetClosureDate;
  final String? linkedAccountId;
  final String? notes;
  final bool active;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  const Loan({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.originalPrincipal,
    this.outstandingPrincipal,
    this.interestRate,
    this.interestRateType = InterestRateType.fixed,
    this.emiAmount,
    this.remainingTenureMonths,
    this.startDate,
    this.nextEmiDate,
    this.targetClosureDate,
    this.linkedAccountId,
    this.notes,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasOutstandingPrincipal =>
      outstandingPrincipal != null && outstandingPrincipal! > 0;

  bool get hasInterestRate => interestRate != null && interestRate! > 0;

  bool get hasEmiAmount => emiAmount != null && emiAmount! > 0;

  bool get hasRemainingTenure =>
      remainingTenureMonths != null && remainingTenureMonths! > 0;

  bool get isCreditCard => type == LoanType.creditCardDebt;

  Loan copyWith({
    String? id,
    String? userId,
    String? name,
    LoanType? type,
    double? originalPrincipal,
    double? outstandingPrincipal,
    double? interestRate,
    InterestRateType? interestRateType,
    double? emiAmount,
    int? remainingTenureMonths,
    DateTime? startDate,
    DateTime? nextEmiDate,
    DateTime? targetClosureDate,
    String? linkedAccountId,
    String? notes,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Loan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      originalPrincipal: originalPrincipal ?? this.originalPrincipal,
      outstandingPrincipal: outstandingPrincipal ?? this.outstandingPrincipal,
      interestRate: interestRate ?? this.interestRate,
      interestRateType: interestRateType ?? this.interestRateType,
      emiAmount: emiAmount ?? this.emiAmount,
      remainingTenureMonths:
          remainingTenureMonths ?? this.remainingTenureMonths,
      startDate: startDate ?? this.startDate,
      nextEmiDate: nextEmiDate ?? this.nextEmiDate,
      targetClosureDate: targetClosureDate ?? this.targetClosureDate,
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
      'originalPrincipal': originalPrincipal,
      'outstandingPrincipal': outstandingPrincipal,
      'interestRate': interestRate,
      'interestRateType': interestRateType.value,
      'emiAmount': emiAmount,
      'remainingTenureMonths': remainingTenureMonths,
      'startDate': startDate?.toIso8601String(),
      'nextEmiDate': nextEmiDate?.toIso8601String(),
      'targetClosureDate': targetClosureDate?.toIso8601String(),
      'linkedAccountId': linkedAccountId,
      'notes': notes,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      type: LoanTypeX.fromString(json['type'] as String? ?? 'otherLoan'),
      originalPrincipal: (json['originalPrincipal'] as num?)?.toDouble(),
      outstandingPrincipal: (json['outstandingPrincipal'] as num?)?.toDouble(),
      interestRate: (json['interestRate'] as num?)?.toDouble(),
      interestRateType: InterestRateTypeX.fromString(
        json['interestRateType'] as String? ?? 'fixed',
      ),
      emiAmount: (json['emiAmount'] as num?)?.toDouble(),
      remainingTenureMonths: json['remainingTenureMonths'] as int?,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      nextEmiDate: json['nextEmiDate'] != null
          ? DateTime.parse(json['nextEmiDate'] as String)
          : null,
      targetClosureDate: json['targetClosureDate'] != null
          ? DateTime.parse(json['targetClosureDate'] as String)
          : null,
      linkedAccountId: json['linkedAccountId'] as String?,
      notes: json['notes'] as String?,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
