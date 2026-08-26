import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/screens/account_types_screen.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:personal_financial_assistant/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/screens/login_screen.dart';
import 'package:personal_financial_assistant/features/auth/presentation/screens/register_screen.dart';
import 'package:personal_financial_assistant/features/blueprint/presentation/screens/financial_setup_screen.dart';
import 'package:personal_financial_assistant/features/categories/presentation/screens/categories_screen.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/screens/app_shell.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:personal_financial_assistant/features/goals/presentation/screens/goals_screen.dart';
import 'package:personal_financial_assistant/features/legal/presentation/screens/financial_disclaimer_screen.dart';
import 'package:personal_financial_assistant/features/legal/presentation/screens/privacy_notice_screen.dart';
import 'package:personal_financial_assistant/features/legal/presentation/screens/terms_of_service_screen.dart';
import 'package:personal_financial_assistant/features/loans/presentation/screens/loan_detail_screen.dart';
import 'package:personal_financial_assistant/features/loans/presentation/screens/loans_screen.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/screens/planned_expenses_screen.dart';
import 'package:personal_financial_assistant/features/profile/presentation/screens/profile_screen.dart';
import 'package:personal_financial_assistant/features/review/presentation/screens/monthly_review_screen.dart';
import 'package:personal_financial_assistant/features/settings/presentation/screens/settings_screen.dart';
import 'package:personal_financial_assistant/features/smart_entry/presentation/screens/smart_entry_screen.dart';
import 'package:personal_financial_assistant/features/trade_off/presentation/screens/trade_off_screen.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/screens/transactions_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: _RiverpodRefreshListenable(
      ref,
      authStateChangesProvider,
    ),
    redirect: (context, state) {
      if (authState.isLoading) {
        return null;
      }

      final isLoggedIn = authState.value != null;
      final isLegalRoute =
          state.matchedLocation == '/terms' ||
          state.matchedLocation == '/privacy' ||
          state.matchedLocation == '/disclaimer';
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute && !isLegalRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Core Stateful Navigation Shell for Tab Destinations
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                name: 'dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/accounts',
                name: 'accounts',
                builder: (context, state) => const AccountsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                name: 'transactions',
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                name: 'analytics',
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Secondary Feature & Utility Routes
      GoRoute(
        path: '/terms',
        name: 'terms',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) => const PrivacyNoticeScreen(),
      ),
      GoRoute(
        path: '/disclaimer',
        name: 'disclaimer',
        builder: (context, state) => const FinancialDisclaimerScreen(),
      ),
      GoRoute(
        path: '/categories',
        name: 'categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/planned-expenses',
        name: 'planned-expenses',
        builder: (context, state) => const PlannedExpensesScreen(),
      ),
      GoRoute(
        path: '/loans',
        name: 'loans',
        builder: (context, state) => const LoansScreen(),
      ),
      GoRoute(
        path: '/loans/:loanId',
        name: 'loan-detail',
        builder: (context, state) {
          final loanId = state.pathParameters['loanId'] ?? '';
          return LoanDetailScreen(loanId: loanId);
        },
      ),
      GoRoute(
        path: '/goals',
        name: 'goals',
        builder: (context, state) => const GoalsScreen(),
      ),
      GoRoute(
        path: '/monthly-review',
        name: 'monthly-review',
        builder: (context, state) => const MonthlyReviewScreen(),
      ),
      GoRoute(
        path: '/account-types',
        name: 'account-types',
        builder: (context, state) => const AccountTypesScreen(),
      ),
      GoRoute(
        path: '/smart-entry',
        name: 'smart-entry',
        builder: (context, state) => const SmartEntryScreen(),
      ),
      GoRoute(
        path: '/financial-setup',
        name: 'financial-setup',
        builder: (context, state) => const FinancialSetupScreen(),
      ),
      GoRoute(
        path: '/trade-off',
        name: 'trade-off',
        builder: (context, state) => const TradeOffScreen(),
      ),
    ],

    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
});

class _RiverpodRefreshListenable extends ChangeNotifier {
  _RiverpodRefreshListenable(Ref ref, ProviderBase provider) {
    ref.listen(provider, (_, _) {
      notifyListeners();
    });
  }
}
