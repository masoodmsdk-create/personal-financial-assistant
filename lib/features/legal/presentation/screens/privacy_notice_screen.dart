import 'package:flutter/material.dart';
import 'package:personal_financial_assistant/core/constants/app_constants.dart';

class PrivacyNoticeScreen extends StatelessWidget {
  const PrivacyNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Notice')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notice Header Card
                  Card(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${AppConstants.appName} Privacy Notice',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Version ${AppConstants.privacyVersion}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
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

                  _buildSection(
                    theme,
                    title: '1. Information We Collect',
                    content:
                        'We collect only information necessary to provide personal financial management functionality:\n\n'
                        '• Account Credentials & Identity: Full Name, Email Address, and Firebase Authentication identity.\n'
                        '• User Financial Accounts: Account name, account type (Bank Account, Cash, Credit Card, Other), opening balance, currency code, active status, and creation/update timestamps.\n'
                        '• Future Functionality Inputs: As features are added, users may voluntarily enter transactions, budgets, or notes.',
                  ),
                  _buildSection(
                    theme,
                    title: '2. Purposes of Data Processing',
                    content:
                        'Your data is processed strictly for the following purposes:\n\n'
                        '• Creating and authenticating user accounts.\n'
                        '• Providing personal financial-management functionality.\n'
                        '• Storing user-created account information securely.\n'
                        '• Calculating and displaying financial summary totals.\n'
                        '• Maintaining application security and preventing unauthorized access.\n\n'
                        'We DO NOT use your data for advertising, marketing profiling, selling to third parties, or training public AI models.',
                  ),
                  _buildSection(
                    theme,
                    title: '3. Financial Information Privacy & Best Practices',
                    content: 'Users voluntarily enter financial metadata to track their personal budgets. We advise users to provide only necessary information for personal tracking and avoid entering confidential account numbers or secret notes in custom names.',
                  ),
                  _buildSection(
                    theme,
                    title: '4. VERY IMPORTANT — Sensitive Banking Credential Warning',
                    content:
                        'CRITICAL SAFETY RECOMMENDATION: ${AppConstants.appName} does NOT collect, request, or store:\n'
                        '• One-Time Passwords (OTPs)\n'
                        '• UPI PINs\n'
                        '• ATM PINs\n'
                        '• Credit/Debit Card PINs\n'
                        '• CVV / CVC security codes\n'
                        '• Internet-banking passwords\n\n'
                        'Users must NEVER enter these credentials into any field, account name, note, or support request.',
                  ),
                  _buildSection(
                    theme,
                    title: '5. Third-Party Infrastructure (Firebase)',
                    content: 'We use Google Firebase (Firebase Auth & Cloud Firestore) for user authentication and user-isolated cloud data storage. Data is stored under user-isolated Firestore rules (`users/{userId}/...`). We implement standard security practices but acknowledge no internet-based service can claim 100% security.',
                  ),
                  _buildSection(
                    theme,
                    title: '6. Data Retention & Deletion Flow',
                    content:
                        'Currently, an automated self-service account and data deletion mechanism is in development and pending implementation. If you require data removal before the self-service flow is deployed, ${AppConstants.supportContactMessage}',
                  ),
                  _buildSection(
                    theme,
                    title: '7. Privacy Rights',
                    content:
                        'Depending on applicable law, users may have rights regarding their personal data, including requesting access, correction, or deletion. ${AppConstants.supportContactMessage}',
                  ),
                  _buildSection(
                    theme,
                    title: '8. Contact & Governing Law',
                    content:
                        '${AppConstants.governingLawMessage}\n\n${AppConstants.supportContactMessage}',
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
