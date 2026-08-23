import 'package:flutter/material.dart';

enum InsightType {
  missingPlannedExpense,
  abovePlan,
  belowPlan,
  upcomingPlannedExpense,
}

enum InsightSeverity { info, warning, success }

class FinancialInsight {
  final String id;
  final InsightType type;
  final String title;
  final String description;
  final InsightSeverity severity;
  final String? categoryId;
  final double? amount;
  final DateTime createdAt;

  const FinancialInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.severity,
    this.categoryId,
    this.amount,
    required this.createdAt,
  });

  IconData get icon {
    switch (severity) {
      case InsightSeverity.info:
        return Icons.info_outline_rounded;
      case InsightSeverity.warning:
        return Icons.warning_amber_rounded;
      case InsightSeverity.success:
        return Icons.check_circle_outline_rounded;
    }
  }

  Color get color {
    switch (severity) {
      case InsightSeverity.info:
        return const Color(0xFF0288D1);
      case InsightSeverity.warning:
        return const Color(0xFFED6C02);
      case InsightSeverity.success:
        return const Color(0xFF2E7D32);
    }
  }
}
