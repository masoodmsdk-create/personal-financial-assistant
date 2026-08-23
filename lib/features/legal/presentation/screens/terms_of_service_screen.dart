import 'package:flutter/material.dart';
import 'package:personal_financial_assistant/core/constants/app_constants.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notice Card
                  Card(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.gavel_outlined,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${AppConstants.appName} Terms of Service',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Version ${AppConstants.termsVersion}',
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
                    title: '1. Nature of the Application',
                    content:
                        '${AppConstants.appName} is a personal financial-management software assistant. The application is designed solely as a software tool to assist users in organizing financial information, recording income and expenses, managing financial accounts, calculating financial figures, viewing dashboards, and setting budgets/goals in future updates.\n\n'
                        'IMPORTANT NOTICE: ${AppConstants.appName} is NOT a bank, Non-Banking Financial Company (NBFC), payment service provider, stockbroker, investment adviser, financial institution, tax adviser, legal counsel, accountant, or credit provider. The application does not provide formal professional advice.',
                  ),
                  _buildSection(
                    theme,
                    title: '2. No Custody or Control of Money',
                    content: 'The application DOES NOT hold, transfer, custody, or manage user funds. It does not execute bank transactions, authorize payments, make investments on behalf of users, or control any external bank accounts. The user remains solely responsible for all actual money movements, payments, and external bank accounts.',
                  ),
                  _buildSection(
                    theme,
                    title: '3. Financial Decision Disclaimer',
                    content:
                        'The application provides software-based calculations and information to assist users in organizing their financial data. It DOES NOT replace professional financial, investment, tax, legal, accounting, or qualified advice.\n\n'
                        'Users must exercise their own independent judgment. Important financial decisions should be independently verified with qualified professional advisers before taking action.',
                  ),
                  _buildSection(
                    theme,
                    title: '4. Accuracy of User Data',
                    content:
                        'Financial calculations and summaries rely strictly on information entered by the user. Incorrect or incomplete input will result in inaccurate calculations.\n\n'
                        'Users are responsible for reviewing and verifying their entries. The application must NOT be treated as the sole or official authoritative record of a user\'s finances.',
                  ),
                  _buildSection(
                    theme,
                    title: '5. AI Assistant Disclaimer (Future Features)',
                    content:
                        'Future versions of ${AppConstants.appName} may introduce artificial intelligence (AI) informational tools. Any future AI-generated outputs may contain errors, omit relevant information, make incorrect assumptions, or produce outdated information.\n\n'
                        'AI responses are strictly informational and must NOT be relied upon as professional financial advice. Note: No AI assistant currently exists in the live application.',
                  ),
                  _buildSection(
                    theme,
                    title: '6. Security & Credential Safety Warning',
                    content:
                        'CRITICAL SAFETY WARNING: ${AppConstants.appName} DOES NOT require and will NEVER ask users to provide:\n'
                        '• One-Time Passwords (OTPs)\n'
                        '• UPI PINs\n'
                        '• ATM or Card PINs\n'
                        '• CVV numbers\n'
                        '• Net-banking or bank login passwords\n\n'
                        'NEVER share these credentials with anyone claiming to represent ${AppConstants.appName}. The application contains no fields for such credentials.',
                  ),
                  _buildSection(
                    theme,
                    title: '7. User Account Security',
                    content: 'Users are responsible for maintaining the confidentiality of their login credentials, choosing a secure password, securing their personal devices, and logging out when appropriate. If you suspect unauthorized access to your account, please notify us using the official contact mechanism made available within the Application.',
                  ),
                  _buildSection(
                    theme,
                    title: '8. User Financial Data Responsibility',
                    content: 'Users retain ownership and responsibility for the financial data they enter into the application (such as account names, opening balances, and future notes/transactions). Users must ensure they only enter information necessary for their personal use.',
                  ),
                  _buildSection(
                    theme,
                    title: '9. Service Availability',
                    content: 'While we endeavor to keep the service operational, we do not promise uninterrupted availability. The application may be temporarily unavailable due to maintenance, software updates, internet/network issues, device compatibility, or third-party infrastructure outages.',
                  ),
                  _buildSection(
                    theme,
                    title: '10. Third-Party Services',
                    content: 'The application utilizes Firebase (Google Cloud) for authentication and cloud database storage. Usage of the application implies acknowledgment of these underlying infrastructure components.',
                  ),
                  _buildSection(
                    theme,
                    title: '11. Prohibited Use',
                    content: 'Users agree not to access another user\'s financial information, bypass security controls, reverse engineer the application, interfere with service operations, or engage in malicious or abusive activity against the infrastructure.',
                  ),
                  _buildSection(
                    theme,
                    title: '12. Intellectual Property',
                    content:
                        'All intellectual property rights in ${AppConstants.appName}, including its software, branding, logos, design, and user interface, belong to the application developer. User-entered financial data remains the property of the user.',
                  ),
                  _buildSection(
                    theme,
                    title: '13. Changes & Termination',
                    content: 'We reserve the right to update these Terms, modify features, or suspend access in response to security concerns or terms violations. Material changes to terms will be communicated within the application.',
                  ),
                  _buildSection(
                    theme,
                    title: '14. Limitation of Liability',
                    content:
                        'To the maximum extent permitted by applicable law, ${AppConstants.appName} and its developer shall not be liable for any indirect, incidental, or consequential damages resulting from user data entry errors, software outages, reliance on calculations, or internet connectivity issues.',
                  ),
                  _buildSection(
                    theme,
                    title: '15. Governing Law & Contact Information',
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
