import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/screens/login_screen.dart';
import 'package:personal_financial_assistant/features/auth/presentation/screens/register_screen.dart';
import 'package:personal_financial_assistant/features/categories/presentation/screens/categories_screen.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/screens/app_shell.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/screens/account_types_screen.dart';
import 'package:personal_financial_assistant/features/goals/presentation/screens/goals_screen.dart';

import 'package:personal_financial_assistant/features/legal/presentation/screens/financial_disclaimer_screen.dart';

import 'package:personal_financial_assistant/features/legal/presentation/screens/privacy_notice_screen.dart';
import 'package:personal_financial_assistant/features/legal/presentation/screens/terms_of_service_screen.dart';
import 'package:personal_financial_assistant/features/loans/presentation/screens/loans_screen.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/screens/planned_expenses_screen.dart';
import 'package:personal_financial_assistant/features/profile/presentation/screens/profile_screen.dart';
import 'package:personal_financial_assistant/features/review/presentation/screens/monthly_review_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: _RiverpodRefreshListenable(
      ref,
      authStateChangesProvider,
    ),
    redirect: (context, state) {
      // While auth state is loading on app startup
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
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const AppShell(),
      ),
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
