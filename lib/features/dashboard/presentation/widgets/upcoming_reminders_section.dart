import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:personal_financial_assistant/features/dashboard/domain/models/command_center_models.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/providers/command_center_providers.dart';

class UpcomingRemindersSection extends ConsumerWidget {
  const UpcomingRemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(upcomingRemindersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.notifications_active_outlined,
                        color: Colors.amber.shade800,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Upcoming',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Scheduled commitments in the next 30 days',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => context.push('/recurring-transactions'),
              icon: const Icon(Icons.repeat_rounded, size: 16),
              label: const Text('Recurring', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (reminders.isEmpty) ...[
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    color: colorScheme.primary.withValues(alpha: 0.7),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No upcoming loan EMIs or scheduled planned expenses due in the next 30 days.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: ListView.separated(
              itemCount: reminders.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final rem = reminders[index];
                return _ReminderTile(reminder: rem, currency: currency);
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final UpcomingPaymentReminder reminder;
  final NumberFormat currency;

  const _ReminderTile({required this.reminder, required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateStr = DateFormat('d MMM').format(reminder.dueDate);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push(reminder.actionRoute),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: reminder.color.withValues(alpha: 0.12),
              child: Icon(reminder.icon, size: 18, color: reminder.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: reminder.daysRemaining <= 3
                              ? Colors.amber.shade100
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          reminder.subtitle,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: reminder.daysRemaining <= 3
                                ? Colors.amber.shade900
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        '• $dateStr',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              currency.format(reminder.amount),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: reminder.isEmi ? Colors.purple : colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
