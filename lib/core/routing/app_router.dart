import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/screens/account_types_screen.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/screens/login_screen.dart';
import 'package:personal_financial_assistant/features/auth/presentation/screens/register_screen.dart';
import 'package:personal_financial_assistant/features/blueprint/presentation/screens/financial_setup_screen.dart';
import 'package:personal_financial_assistant/features/categories/presentation/screens/categories_screen.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/screens/app_shell.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:personal_financial_assistant/features/insights/presentation/screens/insights_hub_screen.dart';
import 'package:personal_financial_assistant/features/legal/presentation/screens/financial_disclaimer_screen.dart';
import 'package:personal_financial_assistant/features/legal/presentation/screens/privacy_notice_screen.dart';
import 'package:personal_financial_assistant/features/legal/presentation/screens/terms_of_service_screen.dart';
import 'package:personal_financial_assistant/features/loans/presentation/screens/loan_detail_screen.dart';
import 'package:personal_financial_assistant/features/money/presentation/screens/money_hub_screen.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/screens/planned_expenses_screen.dart';
import 'package:personal_financial_assistant/features/plans/presentation/screens/plans_hub_screen.dart';
import 'package:personal_financial_assistant/features/profile/presentation/screens/profile_screen.dart';
import 'package:personal_financial_assistant/features/settings/presentation/screens/settings_screen.dart';
import 'package:personal_financial_assistant/features/smart_entry/presentation/screens/smart_entry_screen.dart';
import 'package:personal_financial_assistant/features/trade_off/presentation/screens/trade_off_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: _RiverpodRefreshListenable(
      ref,
      authStateChangesProvider,
    ),
    redirect: (context, state) {
      if (authState.isLoading) {
        return null;
      }

      final isLoggedIn = authState.value != null;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      // Canonical redirect: /dashboard -> /home
      if (state.matchedLocation == '/dashboard') {
        return '/home';
      }

      // Legacy standalone route redirects into the five-pillar shell with tab query parameters
      if (state.matchedLocation == '/accounts') {
        return '/money?tab=0';
      }
      if (state.matchedLocation == '/transactions') {
        return '/money?tab=1';
      }
      if (state.matchedLocation == '/recurring-transactions') {
        return '/money?tab=2';
      }
      if (state.matchedLocation == '/budgets') {
        return '/plans?tab=0';
      }
      if (state.matchedLocation == '/goals') {
        return '/plans?tab=1';
      }
      if (state.matchedLocation == '/loans') {
        return '/plans?tab=2';
      }
      if (state.matchedLocation == '/analytics') {
        return '/insights?tab=0';
      }
      if (state.matchedLocation == '/monthly-review') {
        return '/insights?tab=1';
      }
      if (state.matchedLocation == '/forecast') {
        return '/insights?tab=2';
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

      // Canonical redirect routes for direct navigation
      GoRoute(path: '/dashboard', redirect: (context, state) => '/home'),
      GoRoute(path: '/accounts', redirect: (context, state) => '/money?tab=0'),
      GoRoute(
        path: '/transactions',
        redirect: (context, state) => '/money?tab=1',
      ),
      GoRoute(
        path: '/recurring-transactions',
        redirect: (context, state) => '/money?tab=2',
      ),
      GoRoute(path: '/budgets', redirect: (context, state) => '/plans?tab=0'),
      GoRoute(path: '/goals', redirect: (context, state) => '/plans?tab=1'),
      GoRoute(path: '/loans', redirect: (context, state) => '/plans?tab=2'),
      GoRoute(
        path: '/analytics',
        redirect: (context, state) => '/insights?tab=0',
      ),
      GoRoute(
        path: '/monthly-review',
        redirect: (context, state) => '/insights?tab=1',
      ),
      GoRoute(
        path: '/forecast',
        redirect: (context, state) => '/insights?tab=2',
      ),

      // Core Stateful Navigation Shell for 5 Primary Hub Destinations
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/money',
                name: 'money',
                builder: (context, state) {
                  final tabStr = state.uri.queryParameters['tab'];
                  final tabIndex = int.tryParse(tabStr ?? '') ?? 0;
                  return MoneyHubScreen(initialTabIndex: tabIndex);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plans',
                name: 'plans',
                builder: (context, state) {
                  final tabStr = state.uri.queryParameters['tab'];
                  final tabIndex = int.tryParse(tabStr ?? '') ?? 0;
                  return PlansHubScreen(initialTabIndex: tabIndex);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/insights',
                name: 'insights',
                builder: (context, state) {
                  final tabStr = state.uri.queryParameters['tab'];
                  final tabIndex = int.tryParse(tabStr ?? '') ?? 0;
                  return InsightsHubScreen(initialTabIndex: tabIndex);
                },
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
        path: '/loans/:loanId',
        name: 'loan-detail',
        builder: (context, state) {
          final loanId = state.pathParameters['loanId'] ?? '';
          return LoanDetailScreen(loanId: loanId);
        },
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
