import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_financial_assistant/core/widgets/responsive_center.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/widgets/add_edit_account_dialog.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/widgets/assistant_suggestions_section.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/widgets/budget_dashboard_card.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/widgets/financial_plans_dashboard_section.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/widgets/financial_situation_card.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/widgets/monthly_review_dashboard_card.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/widgets/recent_activity_section.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/widgets/upcoming_reminders_section.dart';
import 'package:personal_financial_assistant/features/forecast/presentation/widgets/multi_horizon_forecast_card.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/goals/presentation/widgets/add_edit_goal_dialog.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/providers/recurring_transaction_providers.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/presentation/widgets/add_edit_recurring_transaction_dialog.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/widgets/add_edit_transaction_dialog.dart';
import 'package:personal_financial_assistant/features/workspaces/presentation/providers/workspace_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  String _getDisplayName(User? user) {
    final displayName = user?.displayName;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    final email = user?.email;
    if (email != null && email.isNotEmpty) {
      final namePart = email.split('@').first;
      return namePart
          .split('.')
          .map(
            (part) => part.isNotEmpty
                ? part[0].toUpperCase() + part.substring(1)
                : '',
          )
          .join(' ');
    }
    return 'Welcome';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final displayName = _getDisplayName(user);
    final greeting = _getTimeBasedGreeting();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final accounts = ref.watch(accountsStreamProvider).value ?? [];
    final transactions = ref.watch(transactionsStreamProvider).value ?? [];
    final recurringRules =
        ref.watch(recurringTransactionsStreamProvider).value ?? [];
    final loans = ref.watch(loansStreamProvider).value ?? [];
    final goals = ref.watch(goalsStreamProvider).value ?? [];

    final isNewUser =
        accounts.isEmpty &&
        transactions.isEmpty &&
        recurringRules.isEmpty &&
        loans.isEmpty &&
        goals.isEmpty;

    final initial = displayName.isNotEmpty
        ? displayName
              .trim()
              .split(' ')
              .map((e) => e[0])
              .take(2)
              .join()
              .toUpperCase()
        : 'U';

    return SingleChildScrollView(
      child: ResponsiveCenter(
        maxWidth: 1100,
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Greeting & Workspace Header Card
            Card(
              elevation: 0,
              color: colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: colorScheme.primary,
                      child: Text(
                        initial,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting, $displayName 👋',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.domain_rounded,
                                size: 14,
                                color: colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  activeWorkspace.name.isNotEmpty
                                      ? activeWorkspace.name
                                      : 'Personal Workspace',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onPrimaryContainer
                                        .withValues(alpha: 0.85),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (activeWorkspace.purpose.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              activeWorkspace.purpose,
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.75),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Welcoming Empty State Card (if user has no data yet)
            if (isNewUser) ...[
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.primary, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Let's build your financial picture",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Describe your finances naturally or add your accounts, transactions, recurring rules, and goals to unlock full financial intelligence.',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: () => context.push('/financial-setup'),
                            icon: const Icon(
                              Icons.psychology_alt_rounded,
                              size: 16,
                            ),
                            label: const Text('Tell FINAURA About Your Money'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const AddEditAccountDialog(),
                              );
                            },
                            icon: const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 16,
                            ),
                            label: const Text('Add Account'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) =>
                                    const AddEditTransactionDialog(),
                              );
                            },
                            icon: const Icon(
                              Icons.receipt_long_outlined,
                              size: 16,
                            ),
                            label: const Text('Add Transaction'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) =>
                                    const AddEditRecurringTransactionDialog(),
                              );
                            },
                            icon: const Icon(Icons.repeat_rounded, size: 16),
                            label: const Text('Set Up Recurring'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const AddEditGoalDialog(),
                              );
                            },
                            icon: const Icon(Icons.flag_outlined, size: 16),
                            label: const Text('Add Goal'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // SECTION 11 — FINAURA QUICK ACTIONS BAR (Shown for existing financial pictures)
            if (!isNewUser) ...[
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => context.push('/smart-entry'),
                        icon: const Icon(Icons.mic_none_rounded, size: 18),
                        label: const Text('Smart Entry'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => context.push('/financial-setup'),
                        icon: const Icon(
                          Icons.psychology_alt_rounded,
                          size: 18,
                        ),
                        label: const Text('Tell FINAURA About Your Money'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => context.push('/trade-off'),
                        icon: const Icon(Icons.balance_rounded, size: 18),
                        label: const Text('Trade-Off Intelligence'),
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const AddEditTransactionDialog(),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Transaction'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // SECTIONS 1, 2, 3 — Financial Position, This Month, Available to Spend
            const RepaintBoundary(child: FinancialSituationCard()),
            const SizedBox(height: 20),

            // SECTION 4 — Scheduled Commitments in next 30 days
            const RepaintBoundary(child: UpcomingRemindersSection()),
            const SizedBox(height: 20),

            // SECTION 7 — Budget & Cash Flow Snapshot Card
            const RepaintBoundary(child: BudgetDashboardCard()),
            const SizedBox(height: 20),

            // SECTIONS 5 & 6 — Goals & Loans Portfolios
            const RepaintBoundary(child: FinancialPlansDashboardSection()),
            const SizedBox(height: 20),

            // SECTION 8 — Future Financial Forecast (1M, 4M, 6M, 12M)
            const RepaintBoundary(child: MultiHorizonForecastCard()),
            const SizedBox(height: 20),

            // SECTION 9 — FINAURA Suggests (Intelligent, Actionable Guidance)
            const RepaintBoundary(child: AssistantSuggestionsSection()),
            const SizedBox(height: 20),

            // SECTION 10 — Monthly Financial Review Entry Card
            const RepaintBoundary(child: MonthlyReviewDashboardCard()),
            const SizedBox(height: 20),

            // SECTION 11 — Recent Activity (3-5 Recent Transactions)
            const RepaintBoundary(child: RecentActivitySection()),
          ],
        ),
      ),
    );
  }
}
