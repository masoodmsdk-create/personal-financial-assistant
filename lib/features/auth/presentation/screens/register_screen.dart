import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_financial_assistant/core/constants/app_constants.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/utils/auth_validators.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int _calculatePasswordStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score.clamp(0, 4);
  }

  String _getPasswordStrengthLabel(int strength) {
    switch (strength) {
      case 0:
        return 'Very weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Strong';
      case 4:
        return 'Very strong';
      default:
        return '';
    }
  }

  Color _getPasswordStrengthColor(int strength, ThemeData theme) {
    switch (strength) {
      case 0:
      case 1:
        return theme.colorScheme.error;
      case 2:
        return Colors.amber;
      case 3:
        return Colors.lightGreen;
      case 4:
        return Colors.green;
      default:
        return theme.colorScheme.outline;
    }
  }

  Future<void> _submit() async {
    if (!_acceptedTerms || !_acceptedPrivacy) return;
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!success && mounted) {
      final state = ref.read(authControllerProvider);
      final error = state.error;
      final errorMessage = error is AppException
          ? error.message
          : (error?.toString() ?? 'Registration failed. Please try again.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);
    final passwordStrength = _calculatePasswordStrength(
      _passwordController.text,
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildIllustration(theme),
                  const SizedBox(height: 24),
                  _buildHeader(theme),
                  const SizedBox(height: 20),
                  _buildSafetyWarningCard(theme),
                  const SizedBox(height: 24),
                  _buildForm(theme, isLoading, passwordStrength),
                  const SizedBox(height: 16),
                  _buildPolicyConsentCheckboxes(theme, isLoading),
                  const SizedBox(height: 24),
                  _buildCreateAccountButton(theme, isLoading),
                  const SizedBox(height: 24),
                  _buildLoginNavigation(theme, isLoading),
                  const SizedBox(height: 24),
                  _buildPrivacyMessage(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(ThemeData theme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.person_add_alt_1_rounded,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Create your financial space',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Take control of your money, one step at a time.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSafetyWarningCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Card(
      color: colorScheme.errorContainer.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_person_outlined,
              color: colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔐 Stay Safe',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We will never ask you for your OTP, UPI PIN, ATM PIN, debit/credit-card PIN, CVV, bank password or internet-banking credentials.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.4,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Never share these details with anyone claiming to represent ${AppConstants.appName}.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme, bool isLoading, int passwordStrength) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _fullNameController,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            autofillHints: const [AutofillHints.name],
            maxLength: AppConstants.maxFullNameLength,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
              hintText: 'John Doe',
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Full name is required';
              }
              if (value.trim().length < 2) {
                return 'Enter your full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'you@example.com',
            ),
            validator: AuthValidators.validateEmail,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            enabled: !isLoading,
            onChanged: (_) => setState(() {}),
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              ),
            ),
            validator: AuthValidators.validatePassword,
          ),
          const SizedBox(height: 8),
          _buildPasswordStrengthIndicator(theme, passwordStrength),
          const SizedBox(height: 8),
          _buildPasswordRequirements(theme),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            enabled: !isLoading,
            onFieldSubmitted: (_) => _submit(),
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                tooltip: _obscureConfirmPassword
                    ? 'Show password'
                    : 'Hide password',
              ),
            ),
            validator: (value) => AuthValidators.validateConfirmPassword(
              _passwordController.text,
              value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(ThemeData theme, int strength) {
    if (_passwordController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = _getPasswordStrengthColor(strength, theme);
    final label = _getPasswordStrengthLabel(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            final isActive = index < strength;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: isActive
                      ? color
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Password strength: $label',
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements(ThemeData theme) {
    final password = _passwordController.text;
    final requirements = [
      _PasswordRequirement('At least 8 characters', password.length >= 8),
      _PasswordRequirement(
        'Uppercase letter',
        RegExp(r'[A-Z]').hasMatch(password),
      ),
      _PasswordRequirement(
        'Lowercase letter',
        RegExp(r'[a-z]').hasMatch(password),
      ),
      _PasswordRequirement('Number', RegExp(r'[0-9]').hasMatch(password)),
      _PasswordRequirement(
        'Special character',
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password requirements',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: requirements.map((req) {
              final isMet = req.isMet;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isMet ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: isMet
                        ? Colors.green
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    req.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isMet
                          ? Colors.green
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                      fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyConsentCheckboxes(ThemeData theme, bool isLoading) {
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        CheckboxListTile(
          value: _acceptedTerms,
          enabled: !isLoading,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          onChanged: (val) {
            setState(() {
              _acceptedTerms = val ?? false;
            });
          },
          title: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('I have read and agree to the '),
              InkWell(
                onTap: () => context.push('/terms'),
                child: Text(
                  'Terms of Service',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Text('.'),
            ],
          ),
        ),
        CheckboxListTile(
          value: _acceptedPrivacy,
          enabled: !isLoading,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          onChanged: (val) {
            setState(() {
              _acceptedPrivacy = val ?? false;
            });
          },
          title: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('I acknowledge the '),
              InkWell(
                onTap: () => context.push('/privacy'),
                child: Text(
                  'Privacy Notice',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Text('.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton(ThemeData theme, bool isLoading) {
    final canSubmit = _acceptedTerms && _acceptedPrivacy && !isLoading;

    return FilledButton(
      onPressed: canSubmit ? _submit : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : const Text(
              'Create My Account',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }

  Widget _buildLoginNavigation(ThemeData theme, bool isLoading) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: isLoading ? null : () => context.go('/login'),
          child: const Text(
            'Sign In',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyMessage(ThemeData theme) {
    return Center(
      child: Text(
        'Your financial data is encrypted and never shared.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PasswordRequirement {
  final String label;
  final bool isMet;

  _PasswordRequirement(this.label, this.isMet);
}
