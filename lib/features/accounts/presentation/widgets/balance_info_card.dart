import 'package:flutter/material.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';

class BalanceInfoCard extends StatelessWidget {
  const BalanceInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final infoItems = [
      _BalanceInfoItem(
        type: AccountType.bank,
        example: 'HDFC / SBI',
        effect: 'Adds to balance',
        isDeduction: false,
      ),
      _BalanceInfoItem(
        type: AccountType.cash,
        example: 'Cash in hand',
        effect: 'Adds to balance',
        isDeduction: false,
      ),
      _BalanceInfoItem(
        type: AccountType.creditCard,
        example: 'Credit card outstanding',
        effect: 'Reduces net balance',
        isDeduction: true,
      ),
      _BalanceInfoItem(
        type: AccountType.other,
        example: 'Other account',
        effect: 'Depends on financial nature',
        isDeduction: false,
      ),
    ];

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'How your balance works',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: infoItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = infoItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: item.type.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.type.displayName,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: item.type.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        item.example,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        item.effect,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: item.isDeduction
                              ? colorScheme.error
                              : colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Total Balance is based on the accounts you add. Credit card balances represent amounts owed and therefore reduce your net balance.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceInfoItem {
  final AccountType type;
  final String example;
  final String effect;
  final bool isDeduction;

  _BalanceInfoItem({
    required this.type,
    required this.example,
    required this.effect,
    required this.isDeduction,
  });
}
