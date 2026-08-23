# Changelog

## 2026-08-23

- Implemented **Transactions & Financial Aggregation Engine**:
  - `Transaction` domain model with types `income`, `expense`, and `transfer`.
  - Accounting Rules:
    - Income: Amount, Account ID, Category ID (Income category), Date, Note.
    - Expense: Amount, Account ID, Category ID (Expense category), Date, Note.
    - Transfer: Amount, From Account ID, To Account ID, Date, Note. Transfers have NO Category ID and do NOT affect Income, Expense, or Net Cash Flow.
  - Extended `firestore.rules` for isolated subcollection path `users/{userId}/transactions/{transactionId}` (`request.auth.uid == userId`).
  - `FirestoreTransactionRepository` backed by `FirestoreService` enforcing user UID scoping and validation (amount > 0, date required, note max 200, category type matching, distinct transfer accounts).
  - `FinancialAggregationService`: Pure deterministic engine calculating `totalIncome`, `totalExpense`, `netCashFlow` (`Income - Expense`), `totalTransfers`, `expenseByCategory`, `incomeByCategory`, dynamic `accountBalances` (`openingBalance + income - expense + transferIn - transferOut`), `totalNetBalance` (applying credit card negative net balance convention), `aggregateByPeriod` (Weekly / Monthly / Yearly buckets by transaction date), and `calculatePlannedVsActual`.
  - Riverpod providers (`transactionRepositoryProvider`, `transactionsStreamProvider`, `transactionFilterProvider`, `filteredTransactionsProvider`, `calculatedAccountBalancesProvider`, `calculatedTotalBalanceProvider`, `monthlyFinancialSummaryProvider`, `plannedVsActualProvider`, `transactionControllerProvider`).
  - Material 3 `TransactionsScreen` replacing placeholder in `AppShell` with date-grouped transaction list, type filter chips (`All`, `Income`, `Expense`, `Transfer`), summary banner metrics, and `AddEditTransactionDialog`.
  - Updated `DashboardScreen` displaying live dynamic total balance, current month income, current month expenses, current month net cash flow, and real recent transactions list.
  - Product Exclusions Maintained: No stored `currentBalance` in Firestore, no bank statement import (PDF/CSV/OCR), no automatic bank sync, no AI transaction parsing, no push notifications, no automatic transaction generation from planned expenses.
  - Unit & Widget tests: 70/70 tests passed (`flutter test`).
  - Static Analysis & Formatting: `dart analyze` (0 errors), `dart format .` (clean).
  - Built Web distribution bundle (`flutter build web` — succeeded).

## 2026-08-23 (Earlier)

- Implemented **Planned Expenses / Monthly Forecast Foundation**:
  - Domain models `PlannedExpense` (`id`, `userId`, `name`, `categoryId`, `defaultAmount`, `frequency`, `startDate`, `endDate`, `active`, `accountId`, `createdAt`, `updatedAt`) and `PlannedExpenseOverride` (`id`, `userId`, `planId`, `year`, `month`, `amount`).
  - Enum `RecurrenceFrequency` (`monthly`, `weekly`, `quarterly`, `halfYearly`, `yearly`, `oneTime`).
  - Category Binding: Planned Expenses strictly reference `categoryId` of active Expense categories.
  - Extended `firestore.rules` for isolated user collection paths `users/{userId}/planned_expenses/{planId}` and `users/{userId}/planned_expense_overrides/{overrideId}`.
  - `FirestorePlannedExpenseRepository` backed by `FirestoreService` enforcing user UID scoping and input validations (name <= 50 chars, defaultAmount > 0, endDate >= startDate, expense category check).
  - Riverpod providers (`plannedExpenseRepositoryProvider`, `plannedExpensesStreamProvider`, `selectedForecastDateProvider`, `monthlyOverridesStreamProvider`, `monthlyForecastProvider`, `plannedExpenseControllerProvider`).
  - Material 3 `PlannedExpensesScreen` featuring:
    - **Monthly Forecast Tab**: Month navigation bar, Total Forecasted Expense summary card, plan breakdown items with override chips, inline monthly override dialog.
    - **Recurring Plans Tab**: List of recurring templates, active/archived toggle filter, add/edit/archive/restore actions.
  - `AddEditPlannedExpenseDialog` and `MonthlyOverrideDialog` (allows custom monthly forecast amount override for a specific month without modifying default recurring amount).
  - Added route `/planned-expenses` to `GoRouter` and connected navigation tile in `SettingsScreen`.
  - Exclusions explicitly maintained: Planned expenses are NOT actual transactions and do NOT automatically create transactions. Bank statement import, PDF/CSV parsing, OCR, AI transaction parsing, and automated reminders are NOT implemented.
  - Unit & Widget tests: 55/55 tests passed (`flutter test`).
  - Static Analysis & Formatting: `dart analyze` (0 errors), `dart format .` (clean).
  - Built Web distribution bundle (`flutter build web` — succeeded).

## 2026-08-23 (Earlier)

- Implemented **Track A — Dynamic Categories Foundation**:
  - Domain model `Category` implementing `Entity` with `id`, `userId`, `name`, `type` (`income` / `expense`), `active`, `isDefault`, `sortOrder`, `createdAt`, and `updatedAt`.
  - Default categories generator with sensible defaults for Income (Salary, Business Income, Freelance, Rental Income, Interest, Other Income) and Expenses (Food, Groceries, Rent, Utilities, Transport, Healthcare, Education, Shopping, Entertainment, EMI / Loan Payment, Other Expense).
  - Extended `firestore.rules` for isolated user collection path `users/{userId}/categories/{categoryId}`.
  - `FirestoreCategoryRepository` backed by `FirestoreService` enforcing user isolation, case-insensitive duplicate prevention within category type, and automatic default seeding.
  - Riverpod providers (`categoryRepositoryProvider`, `categoriesStreamProvider`, `incomeCategoriesProvider`, `expenseCategoriesProvider`, `categoryControllerProvider`).
  - Material 3 `CategoriesScreen` featuring Income and Expense tabs, active/archived category toggle, default badges, and inline add/edit/archive/restore actions.
  - `AddEditCategoryDialog` with input validation (required non-empty name, 50-character limit, type lockdown during edit).
- Implemented **Track B — Profile Edit**:
  - Extended `AuthRepository`, `FirebaseAuthRepository`, and `AuthService` with `updateDisplayName`.
  - Added `updateDisplayName` to `AuthController` with error and loading state management.
  - Created Material 3 `ProfileScreen` with user avatar, editable display name, read-only email address, user ID card, and password reset trigger button.
  - Created Material 3 `SettingsScreen` replacing the placeholder tab in `AppShell`, linking Profile Edit, Categories, Legal pages (Terms, Privacy Notice, Disclaimer), and Sign Out.
  - Added routes `/categories` and `/profile` to `GoRouter`.
- Exclusions explicitly maintained:
  - Transactions feature is NOT yet implemented.
  - Bank statement/PDF/CSV import is NOT implemented.
  - AI transaction parsing is NOT implemented.
- Unit & Widget tests: 42/42 tests passed (`flutter test`).
- Static Analysis & Formatting: `dart analyze` (0 errors), `dart format .` (clean).
- Built Web distribution bundle (`flutter build web` — succeeded).

## 2026-08-23 (Earlier)

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
