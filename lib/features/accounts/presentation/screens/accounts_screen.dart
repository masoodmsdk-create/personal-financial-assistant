import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/widgets/add_edit_account_dialog.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/widgets/balance_info_card.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  void _showAddAccountDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const AddEditAccountDialog(),
    );
  }

  void _showEditAccountDialog(BuildContext context, Account account) {
    showDialog<void>(
      context: context,
      builder: (context) => AddEditAccountDialog(account: account),
    );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
    Account account,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete "${account.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: errorColor),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(accountControllerProvider.notifier)
          .deleteAccount(account.id);

      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Account "${account.name}" deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final state = ref.read(accountControllerProvider);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              state.error?.toString() ?? 'Failed to delete account.',
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: accountsAsync.when(
        data: (accounts) {
          if (accounts.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const BalanceInfoCard(),
                  const SizedBox(height: 16),
                  EmptyStateWidget(
                    icon: Icons.account_balance_outlined,
                    title: 'No Accounts Yet',
                    message: 'Add your bank accounts, cash, credit cards, or other accounts to start tracking your finances.',
                    actionLabel: 'Add Account',
                    onAction: () => _showAddAccountDialog(context),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Accounts Summary Header
                Card(
                  color: colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Net Balance',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            MoneyText(
                              totalBalance,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        Chip(
                          avatar: Icon(
                            Icons.account_balance_wallet,
                            size: 18,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          label: Text(
                            '${accounts.length} ${accounts.length == 1 ? 'Account' : 'Accounts'}',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: colorScheme.surfaceContainerHighest,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const BalanceInfoCard(),
                const SizedBox(height: 24),

                Text(
                  'Your Accounts',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: accounts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return _AccountTile(
                      account: account,
                      onEdit: () => _showEditAccountDialog(context, account),
                      onDelete: () =>
                          _confirmDeleteAccount(context, ref, account),
                    );
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading accounts...'),
        error: (error, stack) => AppErrorWidget(
          message: 'Failed to load accounts: $error',
          onRetry: () => ref.invalidate(accountsStreamProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAccountDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Account'),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final Account account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AccountTile({
    required this.account,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = account.type;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: type.color.withValues(alpha: 0.15),
          child: Icon(type.icon, color: type.color),
        ),
        title: Text(
          account.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                type.displayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: type.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(
                  account.effectiveBalance,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: account.isCreditAccount
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
                Text(
                  account.currency,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
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
