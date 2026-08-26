import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/domain/models/account_type_definition.dart';
import 'package:personal_financial_assistant/features/analytics/domain/models/financial_insight.dart';
import 'package:personal_financial_assistant/features/analytics/domain/services/financial_insights_service.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/dashboard/domain/models/command_center_models.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense.dart';
import 'package:personal_financial_assistant/features/planned_expenses/planned_expense_override.dart';
import 'package:personal_financial_assistant/features/plans_progress/domain/models/plan_progress_models.dart';
import 'package:personal_financial_assistant/features/plans_progress/domain/services/plan_progress_service.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/transaction.dart';

class CommandCenterService {
  final PlanProgressService _planProgressService;

  const CommandCenterService({PlanProgressService? planProgressService})
    : _planProgressService = planProgressService ?? const PlanProgressService();

  /// Generates deterministic, explainable, and actionable assistant suggestions
  List<HomeAssistantSuggestion> generateAssistantSuggestions({
    required List<Loan> loans,
    required List<Goal> goals,
    required List<Account> accounts,
    required List<Transaction> transactions,
    required List<PlannedExpense> plans,
    required List<PlannedExpenseOverride> overrides,
    required List<Category> categories,
    required MonthlySummaryData monthlySummary,
    String? workspaceContext,
    List<String> workspacePriorities = const [],
    DateTime? asOfDate,
  }) {
    final now = asOfDate ?? DateTime.now();
    final List<HomeAssistantSuggestion> suggestions = [];
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    // 1. Loan Progress Suggestions
    for (final loan in loans.where((l) => l.active)) {
      final progress = _planProgressService.evaluateLoanProgress(
        loan,
        asOfDate: now,
      );

      if (progress.status == PlanProgressStatus.atRisk) {
        suggestions.add(
          HomeAssistantSuggestion(
            id: 'sug_loan_risk_${loan.id}',
            title: '${loan.name} Target Passed',
            description: progress.explanation,
            category: SuggestionCategory.loan,
            severity: SuggestionSeverity.warning,
            actionLabel: 'Review Loan',
            actionRoute: '/loans/${loan.id}',
          ),
        );
      } else if (progress.status == PlanProgressStatus.behind ||
          progress.status == PlanProgressStatus.slightlyBehind) {
        suggestions.add(
          HomeAssistantSuggestion(
            id: 'sug_loan_behind_${loan.id}',
            title: '${loan.name} — ${progress.headline}',
            description: progress.explanation,
            category: SuggestionCategory.loan,
            severity: SuggestionSeverity.warning,
            actionLabel: 'View Loan',
            actionRoute: '/loans/${loan.id}',
          ),
        );
      } else if (progress.status == PlanProgressStatus.noTarget) {
        suggestions.add(
          HomeAssistantSuggestion(
            id: 'sug_loan_target_${loan.id}',
            title: 'Set Target for ${loan.name}',
            description: 'Set a target closure date to track your repayment progress and prepayment pace.',
            category: SuggestionCategory.loan,
            severity: SuggestionSeverity.info,
            actionLabel: 'Set Target',
            actionRoute: '/loans/${loan.id}',
          ),
        );
      }
    }

    // 2. Goal Progress Suggestions
    for (final goal in goals.where((g) => g.active)) {
      final progress = _planProgressService.evaluateGoalProgress(
        goal,
        asOfDate: now,
      );

      if (progress.status == PlanProgressStatus.ahead && progress.isAchieved) {
        suggestions.add(
          HomeAssistantSuggestion(
            id: 'sug_goal_achieved_${goal.id}',
            title: '${goal.name} Reached!',
            description:
                'Congratulations! You have reached 100% of your ${currency.format(goal.targetAmount)} target.',
            category: SuggestionCategory.goal,
            severity: SuggestionSeverity.success,
            actionLabel: 'View Goal',
            actionRoute: '/goals',
          ),
        );
      } else if (progress.status == PlanProgressStatus.atRisk) {
        suggestions.add(
          HomeAssistantSuggestion(
            id: 'sug_goal_risk_${goal.id}',
            title: '${goal.name} Target Passed',
            description: progress.explanation,
            category: SuggestionCategory.goal,
            severity: SuggestionSeverity.warning,
            actionLabel: 'Review Goal',
            actionRoute: '/goals',
          ),
        );
      } else if (progress.status == PlanProgressStatus.behind ||
          progress.status == PlanProgressStatus.slightlyBehind) {
        suggestions.add(
          HomeAssistantSuggestion(
            id: 'sug_goal_behind_${goal.id}',
            title: '${goal.name} — ${progress.headline}',
            description: progress.explanation,
            category: SuggestionCategory.goal,
            severity: SuggestionSeverity.warning,
            actionLabel: 'View Goal',
            actionRoute: '/goals',
          ),
        );
      } else if (progress.status == PlanProgressStatus.noTarget) {
        suggestions.add(
          HomeAssistantSuggestion(
            id: 'sug_goal_target_${goal.id}',
            title: 'Set Target Date for ${goal.name}',
            description: 'Set a target date to calculate your required contribution pace and completion timeline.',
            category: SuggestionCategory.goal,
            severity: SuggestionSeverity.info,
            actionLabel: 'Set Date',
            actionRoute: '/goals',
          ),
        );
      }
    }

    // 3. Cash Flow Deficit Warning
    if (monthlySummary.netCashFlow < 0 && monthlySummary.totalIncome > 0) {
      suggestions.add(
        HomeAssistantSuggestion(
          id: 'sug_cashflow_negative',
          title: 'Negative Cash Flow Alert',
          description:
              'Current month expenses (${currency.format(monthlySummary.totalExpense)}) exceed recorded income by ${currency.format(-monthlySummary.netCashFlow)}.',
          category: SuggestionCategory.cashFlow,
          severity: SuggestionSeverity.warning,
          actionLabel: 'Review Cash Flow',
          actionRoute: '/monthly-review',
        ),
      );
    }

    // 4. Missing / Unrecorded Planned Expenses from FinancialInsightsService
    final existingInsights = FinancialInsightsService.generateInsights(
      transactions: transactions,
      plans: plans,
      overrides: overrides,
      categories: categories,
      periodDate: now,
    );

    for (final insight in existingInsights.take(2)) {
      suggestions.add(
        HomeAssistantSuggestion(
          id: 'sug_insight_${insight.id}',
          title: insight.title,
          description: insight.description,
          category: SuggestionCategory.budget,
          severity: insight.severity == InsightSeverity.warning
              ? SuggestionSeverity.warning
              : SuggestionSeverity.info,
          actionLabel: 'View Budget',
          actionRoute: '/planned-expenses',
        ),
      );
    }

    // 5. Contextual Sort & Deduplication
    final hasDebtPriority = workspacePriorities.any(
      (p) =>
          p.toLowerCase().contains('debt') || p.toLowerCase().contains('loan'),
    );
    final hasEmergencyPriority = workspacePriorities.any(
      (p) =>
          p.toLowerCase().contains('emergency') ||
          p.toLowerCase().contains('save'),
    );

    suggestions.sort((a, b) {
      // 1. Severity: Warning > Info > Success
      if (a.severity == SuggestionSeverity.warning &&
          b.severity != SuggestionSeverity.warning) {
        return -1;
      }
      if (a.severity != SuggestionSeverity.warning &&
          b.severity == SuggestionSeverity.warning) {
        return 1;
      }

      // 2. Workspace Context Priority Boost
      if (hasDebtPriority) {
        if (a.category == SuggestionCategory.loan &&
            b.category != SuggestionCategory.loan) {
          return -1;
        }
        if (a.category != SuggestionCategory.loan &&
            b.category == SuggestionCategory.loan) {
          return 1;
        }
      }
      if (hasEmergencyPriority) {
        if (a.category == SuggestionCategory.goal &&
            b.category != SuggestionCategory.goal) {
          return -1;
        }
        if (a.category != SuggestionCategory.goal &&
            b.category == SuggestionCategory.goal) {
          return 1;
        }
      }

      return 0;
    });

    return suggestions.take(4).toList();
  }

  /// Extracts upcoming payment reminders (EMIs and Planned Expenses) for the next 30 days
  List<UpcomingPaymentReminder> getUpcomingReminders({
    required List<Loan> loans,
    required List<PlannedExpense> plans,
    List<RecurringTransactionRule> recurringRules = const [],
    DateTime? asOfDate,
  }) {
    final now = asOfDate ?? DateTime.now();
    final List<UpcomingPaymentReminder> reminders = [];
    final cutoffDate = now.add(const Duration(days: 30));

    // 1. Upcoming Loan EMIs
    for (final loan in loans.where((l) => l.active && (l.emiAmount ?? 0) > 0)) {
      DateTime? due = loan.nextEmiDate;
      if (due == null) {
        // Estimate next EMI day from start date if available
        final day = loan.startDate?.day ?? 5;
        due = DateTime(now.year, now.month, day);
        if (due.isBefore(now)) {
          due = DateTime(now.year, now.month + 1, day);
        }
      }

      if (due.isAfter(now.subtract(const Duration(days: 1))) &&
          due.isBefore(cutoffDate)) {
        final daysLeft = due.difference(now).inDays;
        reminders.add(
          UpcomingPaymentReminder(
            id: 'rem_emi_${loan.id}',
            title: '${loan.name} EMI',
            subtitle: daysLeft == 0
                ? 'Due today'
                : daysLeft == 1
                ? 'Due tomorrow'
                : 'Due in $daysLeft days',
            amount: loan.emiAmount ?? 0.0,
            dueDate: due,
            daysRemaining: daysLeft,
            actionRoute: '/loans/${loan.id}',
            isEmi: true,
          ),
        );
      }
    }

    // 2. Upcoming Active Planned Expenses
    for (final plan in plans.where((p) => p.active && p.defaultAmount > 0)) {
      final day = plan.startDate.day.clamp(1, 28);
      DateTime due = DateTime(now.year, now.month, day);
      if (due.isBefore(now)) {
        due = DateTime(now.year, now.month + 1, day);
      }

      if (due.isAfter(now.subtract(const Duration(days: 1))) &&
          due.isBefore(cutoffDate)) {
        final daysLeft = due.difference(now).inDays;
        reminders.add(
          UpcomingPaymentReminder(
            id: 'rem_plan_${plan.id}',
            title: plan.name,
            subtitle: daysLeft == 0
                ? 'Scheduled today'
                : daysLeft == 1
                ? 'Scheduled tomorrow'
                : 'Scheduled in $daysLeft days',
            amount: plan.defaultAmount,
            dueDate: due,
            daysRemaining: daysLeft,
            actionRoute: '/planned-expenses',
            isEmi: false,
          ),
        );
      }
    }

    // 3. Upcoming Active Recurring Expense Rules
    for (final rule in recurringRules.where(
      (r) => r.active && r.type == TransactionType.expense,
    )) {
      final due = rule.nextOccurrence;
      if (due.isAfter(now.subtract(const Duration(days: 1))) &&
          due.isBefore(cutoffDate)) {
        final daysLeft = due.difference(now).inDays;
        reminders.add(
          UpcomingPaymentReminder(
            id: 'rem_rec_${rule.id}',
            title: rule.name,
            subtitle: daysLeft == 0
                ? 'Recurring today'
                : daysLeft == 1
                ? 'Recurring tomorrow'
                : 'Recurring in $daysLeft days',
            amount: rule.amount,
            dueDate: due,
            daysRemaining: daysLeft,
            actionRoute: '/recurring-transactions',
            isEmi: false,
          ),
        );
      }
    }

    reminders.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return reminders.take(4).toList();
  }

  /// Calculates authoritative Accounts Summary (Total Assets vs Liabilities)
  AccountsSummaryData getAccountsSummary({
    required List<Account> accounts,
    required Map<String, double> dynamicBalances,
  }) {
    final active = accounts.where((a) => a.active).toList();
    double totalAssets = 0.0;
    double totalLiabilities = 0.0;

    for (final acc in active) {
      final balance = dynamicBalances[acc.id] ?? acc.openingBalance;
      if (acc.nature == AccountNature.asset) {
        totalAssets += balance;
      } else {
        totalLiabilities += balance.abs();
      }
    }

    return AccountsSummaryData(
      activeAccountsCount: active.length,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      netBalance: totalAssets - totalLiabilities,
    );
  }
}
