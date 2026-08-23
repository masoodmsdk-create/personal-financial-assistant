import 'package:flutter/material.dart';

enum SuggestionCategory { loan, goal, cashFlow, budget, account, general }

extension SuggestionCategoryX on SuggestionCategory {
  String get displayName {
    switch (this) {
      case SuggestionCategory.loan:
        return 'Loan Insight';
      case SuggestionCategory.goal:
        return 'Goal Pace';
      case SuggestionCategory.cashFlow:
        return 'Cash Flow';
      case SuggestionCategory.budget:
        return 'Budget Review';
      case SuggestionCategory.account:
        return 'Account Alert';
      case SuggestionCategory.general:
        return 'Financial Tip';
    }
  }

  IconData get icon {
    switch (this) {
      case SuggestionCategory.loan:
        return Icons.account_balance_outlined;
      case SuggestionCategory.goal:
        return Icons.flag_outlined;
      case SuggestionCategory.cashFlow:
        return Icons.savings_outlined;
      case SuggestionCategory.budget:
        return Icons.pie_chart_outline_rounded;
      case SuggestionCategory.account:
        return Icons.account_balance_wallet_outlined;
      case SuggestionCategory.general:
        return Icons.psychology_outlined;
    }
  }
}

enum SuggestionSeverity { info, warning, success }

class HomeAssistantSuggestion {
  final String id;
  final String title;
  final String description;
  final SuggestionCategory category;
  final SuggestionSeverity severity;
  final String actionLabel;
  final String actionRoute;

  const HomeAssistantSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.actionLabel,
    required this.actionRoute,
  });

  Color get color {
    switch (severity) {
      case SuggestionSeverity.info:
        return const Color(0xFF0288D1);
      case SuggestionSeverity.warning:
        return const Color(0xFFED6C02);
      case SuggestionSeverity.success:
        return const Color(0xFF2E7D32);
    }
  }

  IconData get icon {
    switch (severity) {
      case SuggestionSeverity.info:
        return Icons.info_outline_rounded;
      case SuggestionSeverity.warning:
        return Icons.warning_amber_rounded;
      case SuggestionSeverity.success:
        return Icons.check_circle_outline_rounded;
    }
  }
}

class UpcomingPaymentReminder {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime dueDate;
  final int daysRemaining;
  final String actionRoute;
  final bool isEmi;

  const UpcomingPaymentReminder({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.dueDate,
    required this.daysRemaining,
    required this.actionRoute,
    this.isEmi = false,
  });

  IconData get icon =>
      isEmi ? Icons.account_balance_outlined : Icons.calendar_today_outlined;

  Color get color => isEmi ? Colors.purple : Colors.teal;
}

class AccountsSummaryData {
  final int activeAccountsCount;
  final double totalAssets;
  final double totalLiabilities;
  final double netBalance;

  const AccountsSummaryData({
    this.activeAccountsCount = 0,
    this.totalAssets = 0.0,
    this.totalLiabilities = 0.0,
    this.netBalance = 0.0,
  });

  bool get hasAccounts => activeAccountsCount > 0;
}

