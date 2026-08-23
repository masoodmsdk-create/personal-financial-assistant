import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final success = await ref
        .read(authControllerProvider.notifier)
        .updateDisplayName(newName);

    if (mounted) {
      if (success) {
        setState(() {
          _isEditing = false;
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final state = ref.read(authControllerProvider);
        final error = state.error;
        final errorMessage = error is AppException
            ? error.message
            : (error?.toString() ?? 'Failed to update profile name.');
        messenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final user = ref.read(currentUserProvider);
    final email = user?.email;
    if (email == null || email.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;

    final success = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(email);

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Password reset link sent to $email'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final state = ref.read(authControllerProvider);
        final error = state.error;
        final errorMessage = error is AppException
            ? error.message
            : 'Failed to send password reset email';
        messenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);

    final currentDisplayName = user?.displayName ?? 'Not provided';
    final email = user?.email ?? 'Not provided';
    final uid = user?.uid ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profile Avatar & Info Card
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person_rounded,
                            size: 36,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentDisplayName,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
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
                Text(
                  'Profile Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Edit Display Name Form / Tile
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Full Name',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (!_isEditing)
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _nameController.text =
                                          user?.displayName ?? '';
                                      _isEditing = true;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Edit'),
                                ),
                            ],
                          ),
                          if (_isEditing) ...[
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              enabled: !isLoading,
                              decoration: const InputDecoration(
                                labelText: 'Display Name',
                                hintText: 'Enter your full name',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Display name cannot be empty';
                                }
                                if (value.trim().length > 50) {
                                  return 'Name cannot exceed 50 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _isEditing = false;
                                          });
                                        },
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: isLoading ? null : _saveName,
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Save Changes'),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 4),
                            Text(
                              currentDisplayName,
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Read-only Email Tile
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email Address'),
                    subtitle: Text(email),
                    trailing: const Chip(
                      label: Text('Read Only'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  'Account Security',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.fingerprint_rounded),
                        title: const Text('User ID'),
                        subtitle: Text(
                          uid,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_reset_rounded),
                        title: const Text('Reset Password'),
                        subtitle: const Text(
                          'Send a password reset email to your registered email address.',
                        ),
                        trailing: OutlinedButton(
                          onPressed: isLoading ? null : _sendPasswordReset,
                          child: const Text('Reset'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
