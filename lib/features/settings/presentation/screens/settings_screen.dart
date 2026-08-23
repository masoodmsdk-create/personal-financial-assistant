import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_financial_assistant/core/constants/app_constants.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    final displayName =
        (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : (user?.email?.split('@').first ?? 'User');
    final email = user?.email ?? '';

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          // Profile Header Tile
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(email),
              trailing: OutlinedButton(
                onPressed: () => context.push('/profile'),
                child: const Text('Edit Profile'),
              ),
              onTap: () => context.push('/profile'),
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'Financial Management',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Transaction Categories'),
                  subtitle: const Text(
                    'Customize income and expense categories',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/categories'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.event_repeat_rounded),
                  title: const Text('Planned Expenses & Forecast'),
                  subtitle: const Text(
                    'Define recurring expenses and view monthly forecast',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/planned-expenses'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'Legal & Information',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/terms'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Notice'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/privacy'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gavel_outlined),
                  title: const Text('Financial Disclaimer'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/disclaimer'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(AppConstants.appName),
              subtitle: const Text('Version 1.0.0'),
            ),
          ),

          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
