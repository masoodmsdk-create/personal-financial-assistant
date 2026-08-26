import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_financial_assistant/core/widgets/responsive_center.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/widgets/assistant_suggestions_section.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/widgets/financial_plans_dashboard_section.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/widgets/financial_situation_card.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/widgets/monthly_review_dashboard_card.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/widgets/recent_activity_section.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/widgets/upcoming_reminders_section.dart';
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
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 48.0),
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
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '$greeting, $displayName 👋',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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

            // Tell FINAURA Financial Setup Hero Banner
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/financial-setup'),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 520;
                      if (isCompact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.psychology_alt_rounded,
                                    color: colorScheme.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    children: [
                                      Text(
                                        'Tell FINAURA About Your Money',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'Setup',
                                          style: TextStyle(
                                            color:
                                                colorScheme.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Describe your income, loans, and goals in words to update your Financial Blueprint.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.tonal(
                                onPressed: () =>
                                    context.push('/financial-setup'),
                                child: const Text(
                                  'Start Setup',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.psychology_alt_rounded,
                              color: colorScheme.primary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Tell FINAURA About Your Money',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Setup',
                                        style: TextStyle(
                                          color: colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Describe your income, loans, and goals in words to update your Financial Blueprint.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.tonal(
                            onPressed: () => context.push('/financial-setup'),
                            child: const Text(
                              'Start',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 1. Current Financial Situation (Live Overview & Accounts Summary)
            const RepaintBoundary(child: FinancialSituationCard()),
            const SizedBox(height: 20),

            // 2 & 3. Goals & Loans Progress Portfolio (Top 1-3 Prioritized Cards)
            const RepaintBoundary(child: FinancialPlansDashboardSection()),
            const SizedBox(height: 20),

            // 4. 🧠 FINAURA Suggests (Intelligent, Actionable Guidance)
            const RepaintBoundary(child: AssistantSuggestionsSection()),
            const SizedBox(height: 20),

            // 5. 🔔 Upcoming (Scheduled EMIs & Planned Commitments)
            const RepaintBoundary(child: UpcomingRemindersSection()),
            const SizedBox(height: 20),

            // Monthly Financial Review Entry Card
            const RepaintBoundary(child: MonthlyReviewDashboardCard()),
            const SizedBox(height: 20),

            // 6. Recent Activity (3-5 Recent Transactions)
            const RepaintBoundary(child: RecentActivitySection()),
          ],
        ),
      ),
    );
  }
}
