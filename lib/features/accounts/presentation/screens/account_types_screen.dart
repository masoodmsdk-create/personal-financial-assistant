import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/core/widgets/financial_widgets.dart';
import 'package:personal_financial_assistant/core/widgets/responsive_center.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/widgets/add_edit_account_type_dialog.dart';

class AccountTypesScreen extends ConsumerWidget {
  const AccountTypesScreen({super.key});

  void _showAddTypeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const AddEditAccountTypeDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountTypesAsync = ref.watch(accountTypesStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Account Types')),
      body: accountTypesAsync.when(
        data: (types) {
          final activeTypes = types.where((t) => t.active).toList();
          return SingleChildScrollView(
            child: ResponsiveCenter(
              maxWidth: 800,
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 100.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: theme.colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Extensible Account Types',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Default types (Bank, Cash, Credit Card, Other) are system-protected. You can add custom account types configured as Assets or Liabilities to organize your accounts.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Configured Account Types',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeTypes.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),

                    itemBuilder: (context, index) {
                      final typeDef = activeTypes[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: typeDef.color.withValues(
                              alpha: 0.15,
                            ),
                            child: Icon(typeDef.icon, color: typeDef.color),
                          ),
                          title: Text(
                            typeDef.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${typeDef.nature.displayName} • ${typeDef.isDefault ? 'System Default' : 'Custom'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: typeDef.isDefault
                              ? const Chip(
                                  label: Text('System'),
                                  visualDensity: VisualDensity.compact,
                                )
                              : IconButton(
                                  icon: const Icon(Icons.archive_outlined),
                                  tooltip: 'Archive Type',
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text(
                                          'Archive Account Type',
                                        ),
                                        content: Text(
                                          'Archive custom type "${typeDef.name}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: const Text('Archive'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await ref
                                          .read(
                                            customAccountTypeControllerProvider
                                                .notifier,
                                          )
                                          .archiveAccountType(typeDef.id);
                                    }
                                  },
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingWidget(message: 'Loading account types...'),
        error: (err, _) => AppErrorWidget(
          message: 'Error loading account types: $err',
          onRetry: () => ref.invalidate(accountTypesStreamProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTypeDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Account Type'),
      ),
    );
  }
}
