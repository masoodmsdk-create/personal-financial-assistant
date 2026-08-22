# Changelog

## 2026-08-22

- Implemented Firebase Email/Password Authentication layer (`AuthService` and `FirebaseAuthRepository`).
- Added form input validation for email address formats, minimum password requirements (>= 6 chars), password confirmation matching, and empty fields (`AuthValidators`).
- Configured Riverpod authentication state management (`authRepositoryProvider`, `authStateChangesProvider`, `authControllerProvider`).
- Configured `GoRouter` declarative routing with automatic authentication state redirection and startup loading screen resolution (`AppRouter`).
- Implemented Material 3 `LoginScreen` with email/password inputs, obscure text toggle, submit progress indicator, floating error snackbars, and registration navigation.
- Implemented Material 3 `RegisterScreen` with email/password/confirm password inputs, obscure text toggle, submit progress indicator, floating error snackbars, and login navigation.
- Implemented Material 3 `AppShell` with navigation bar and logout confirmation modal dialog.
- Implemented `DashboardScreen` displaying user welcome card (`FirebaseAuth.currentUser?.email`), and placeholder overview cards for Balance, Income, Expenses, Savings, and Recent Transactions.
- Added unit tests for input validators and exception mapping, and widget tests for LoginScreen (`flutter test` 12/12 passed).
- Verified static analysis (`dart analyze` — 0 errors) and formatting (`dart format .`).
- Verified Web distribution build (`flutter build web` succeeded).
- Configured Firebase Core for Android and Web using FlutterFire CLI with Firebase project `msd-financial-assistant`.
- Configured Android application ID `com.masoodmsdk.personalfinance`.
