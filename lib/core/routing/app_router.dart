import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/screens/login_screen.dart';
import 'package:personal_financial_assistant/features/auth/presentation/screens/register_screen.dart';
import 'package:personal_financial_assistant/features/dashboard/presentation/screens/app_shell.dart';

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
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) {
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
