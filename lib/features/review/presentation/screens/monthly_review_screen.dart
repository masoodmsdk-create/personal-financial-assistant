import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/features/analytics/presentation/widgets/category_breakdown_card.dart';
import 'package:personal_financial_assistant/features/analytics/presentation/widgets/things_to_review_card.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/loans/domain/models/loan_forecast.dart';

import 'package:personal_financial_assistant/features/loans/presentation/widgets/improve_forecast_card.dart';
import 'package:personal_financial_assistant/features/review/presentation/providers/monthly_review_providers.dart';
import 'package:personal_financial_assistant/features/review/presentation/widgets/coming_up_forecast_card.dart';
import 'package:personal_financial_assistant/features/review/presentation/widgets/goals_loan_progress_card.dart';
import 'package:personal_financial_assistant/features/review/presentation/widgets/monthly_summary_card.dart';

import 'package:personal_financial_assistant/core/widgets/responsive_center.dart';

class MonthlyReviewScreen extends ConsumerWidget {
  const MonthlyReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selectedDate = ref.watch(selectedReviewDateProvider);
    final reviewAsync = ref.watch(monthlyReviewDataProvider);

    final formattedMonth = DateFormat('MMMM yyyy').format(selectedDate);

    return Scaffold(
      body: Column(
        children: [
          // Month Navigation Bar

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: colorScheme.surfaceContainerLow,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Previous Month',
                  onPressed: () {
                    ref.read(selectedReviewDateProvider.notifier).state =
                        DateTime(selectedDate.year, selectedDate.month - 1);
                  },
                ),
                Text(
                  formattedMonth,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Next Month',
                  onPressed: () {
                    ref.read(selectedReviewDateProvider.notifier).state =
                        DateTime(selectedDate.year, selectedDate.month + 1);
                  },
                ),
              ],
            ),
          ),

          // Main Review Scroll Content
          Expanded(
            child: reviewAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Error loading review: $err')),
              data: (data) {
                // Compile all missing loan fields for progressive forecast assistance
                final missingLoanFields = <LoanMissingFieldInfo>[];
                for (final l in data.loanSummaries) {
                  missingLoanFields.addAll(l.forecast.missingFields);
                }

                return SingleChildScrollView(
                  child: ResponsiveCenter(
                    maxWidth: 1000,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PageHeader(
                          title: 'Monthly Review',
                          subtitle: 'A complete monthly summary of actual cash flow, planned expenses, and forecast commitments.',
                        ),

                        // Section 1: What Happened?
                        _SectionHeader(title: '1. What Happened?'),

                        MonthlySummaryCard(reviewData: data),
                        const SizedBox(height: 16),

                        if (!data.hasTransactions) ...[
                          EmptyStateWidget(
                            icon: Icons.receipt_long_outlined,
                            title: 'No Transactions Recorded Yet',
                            message:
                                'Record your income and expenses for $formattedMonth to see your detailed category spending breakdown.',
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          CategoryBreakdownCard(
                            title: 'Expense Spending Share',
                            items: data.expenseCategoryBreakdown,
                            type: CategoryType.expense,
                          ),
                          const SizedBox(height: 16),
                          CategoryBreakdownCard(
                            title: 'Income Sources Share',
                            items: data.incomeCategoryBreakdown,
                            type: CategoryType.income,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Section 2: Things to Review
                        _SectionHeader(title: '2. Things to Review'),
                        ThingsToReviewCard(customInsights: data.insights),

                        const SizedBox(height: 16),

                        // Section 3: What's Coming Next?
                        _SectionHeader(title: '3. What\'s Coming Next?'),
                        ComingUpForecastCard(forecast: data.upcomingForecast),
                        const SizedBox(height: 16),

                        // Section 4: How are my goals & loans progressing?
                        _SectionHeader(
                          title: '4. How are my goals & loans progressing?',
                        ),
                        GoalsLoanProgressCard(
                          goalSummaries: data.goalSummaries,
                          loanSummaries: data.loanSummaries,
                        ),
                        if (missingLoanFields.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ImproveForecastCard(missingFields: missingLoanFields),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
