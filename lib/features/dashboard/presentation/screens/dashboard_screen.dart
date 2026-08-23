import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';

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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Welcome Card
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
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
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Here's your financial snapshot.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Overview Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Overview',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Chip(
                label: const Text('Live & Placeholder'),
                backgroundColor: colorScheme.surfaceContainerHighest,
                avatar: const Icon(Icons.info_outline, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Financial Summary Cards (Grid)
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _LiveTotalBalanceCard(
                totalBalance: ref.watch(totalBalanceProvider),
              ),
              const _PlaceholderCard(
                title: 'Monthly Income',
                amount: '₹ --',
                icon: Icons.arrow_downward_outlined,
                color: Colors.green,
              ),
              const _PlaceholderCard(
                title: 'Monthly Expenses',
                amount: '₹ --',
                icon: Icons.arrow_upward_outlined,
                color: Colors.red,
              ),
              const _PlaceholderCard(
                title: 'Monthly Savings',
                amount: '₹ --',
                icon: Icons.savings_outlined,
                color: Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Transactions Section Header
          Text(
            'Recent Transactions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Placeholder Recent Transactions List
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final placeholders = [
                  {
                    'name': 'Sample Income Placeholder',
                    'type': 'Income',
                    'amount': '+ ₹0.00',
                  },
                  {
                    'name': 'Sample Expense Placeholder',
                    'type': 'Expense',
                    'amount': '- ₹0.00',
                  },
                  {
                    'name': 'Sample Transfer Placeholder',
                    'type': 'Transfer',
                    'amount': '₹0.00',
                  },
                ];
                final item = placeholders[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.receipt_long_outlined, size: 20),
                  ),
                  title: Text(item['name']!),
                  subtitle: Text('[Placeholder] ${item['type']}'),
                  trailing: Text(
                    item['amount']!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
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

class _LiveTotalBalanceCard extends StatelessWidget {
  final double totalBalance;

  const _LiveTotalBalanceCard({required this.totalBalance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Balance',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Icon(
                  Icons.account_balance_outlined,
                  size: 20,
                  color: Colors.blue,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoneyText(
                  totalBalance,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Live Account Sum',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  const _PlaceholderCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Icon(icon, size: 20, color: color),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '[Placeholder]',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
