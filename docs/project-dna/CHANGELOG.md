# Changelog

## 2026-08-23

- Implemented **Accounts Feature** (First Financial Feature in Phase 2):
  - Created `firestore.rules` enforcing user-owned data security (`users/{userId}/{document=**}` read/write allowed strictly for `request.auth.uid == userId`).
  - Implemented `Account` domain entity supporting `AccountType` (Bank Account, Cash, Credit Card, Wallet, Other) and balance calculation helpers.
  - Implemented `AccountRepository` interface and `FirestoreAccountRepository` backed by `FirestoreService` under user-isolated path `users/{userId}/accounts/{accountId}` (ensuring `userId` comes strictly from `FirebaseAuth.currentUser`).
  - Added Riverpod providers: `accountRepositoryProvider`, `accountsStreamProvider`, `totalBalanceProvider`, and `accountControllerProvider`.
  - Created Material 3 `AccountsScreen` featuring Total Net Balance header card, live account tiles with color-coded type badges, pop-up action menu (Edit, Delete), confirmation dialogs, and `EmptyStateWidget`.
  - Created Material 3 `AddEditAccountDialog` with form validation for account name and balance amount.
  - Integrated `AccountsScreen` into `AppShell` navigation and connected `totalBalanceProvider` to `DashboardScreen` total balance card.
  - Added comprehensive unit tests (`account_model_test.dart`) and widget tests (`accounts_screen_test.dart`) — `flutter test` (23/23 tests passed).
  - Verified static analysis (`dart analyze` — 0 errors) and formatting (`dart format .`).
  - Built Web distribution bundle (`flutter build web` — succeeded).
- Polished Authentication & Dashboard UI:
  - Updated app title to "MSD's Financial Assistant" and tagline "Your money. Your goals. Your future.".
  - Added Full Name input and password strength indicator bar/checklist to `RegisterScreen`.
  - Added dynamic time-aware greeting (`Good morning/afternoon/evening, <Name> 👋`) to `DashboardScreen`.

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
