# Project Status

## Current Stage

Phase 2 — Core Finance: Accounts, Dynamic Categories, Profile Edit, Planned Expenses, Transactions, and Financial Aggregation Engine complete.

## Current Target

Build a Personal Financial Assistant for:

- Personal use
- 5–10 initial users
- Android first
- Web support
- Firebase backend
- Flutter application
- ₹0 recurring cost target (Firebase Spark tier)

## Completed

- Inspected the workspace and preserved existing structure and commits.
- Configured Firebase Core for Android and Web in Firebase project `msd-financial-assistant`.
- Implemented `AuthService` and `FirebaseAuthRepository` abstraction for Firebase Email/Password authentication.
- Implemented form input validators for email, full name, password strength, and password confirmation.
- Implemented authentication state stream listener and state management with Riverpod (`authRepositoryProvider`, `authStateChangesProvider`, `authControllerProvider`).
- Integrated `GoRouter` declarative routing with automatic authentication state redirection and loading screen resolution.
- Polished Material 3 `LoginScreen` ("MSD's Financial Assistant", tagline, email/password login, visibility toggle, forgot password dialog, privacy shield badge).
- Polished Material 3 `RegisterScreen` (Full Name, email, password, confirm password, password strength indicator bar, password requirements checklist).
- Created Material 3 `AppShell` with bottom navigation bar and account sign-out dialog.
- **Implemented ACCOUNTS Feature**:
  - `Account` model with JSON serialization, dynamic balance calculations, and `AccountType` extensions (`bank`, `cash`, `creditCard`, `wallet`, `other`).
  - `FirestoreAccountRepository` storing user accounts under isolated path `users/{userId}/accounts/{accountId}` backed by `FirestoreService`.
  - Security rules (`firestore.rules`) restricting read/write access to `users/{userId}` strictly to authenticated owner (`request.auth.uid == userId`).
  - Riverpod providers (`accountRepositoryProvider`, `accountsStreamProvider`, `totalBalanceProvider`, `accountControllerProvider`).
  - `AccountsScreen` with total net balance header card, list of account tiles with type badges, actions overflow menu (Edit, Delete with confirmation dialog), and `EmptyStateWidget`.
  - `AddEditAccountDialog` with validation for account name and balance amount.
- **Implemented DYNAMIC CATEGORIES FOUNDATION**:
  - `Category` domain model (`id`, `userId`, `name`, `type`, `active`, `isDefault`, `sortOrder`, `createdAt`, `updatedAt`).
  - `CategoryType` enum (`income`, `expense`). Transfers do NOT use categories.
  - Default categories generator providing sensible defaults.
  - Firestore security rules extended to cover `users/{userId}/categories/{categoryId}`.
  - `FirestoreCategoryRepository` enforcing user isolation, case-insensitive duplicate prevention within category type, and automatic default seeding.
  - Riverpod providers (`categoryRepositoryProvider`, `categoriesStreamProvider`, `incomeCategoriesProvider`, `expenseCategoriesProvider`, `categoryControllerProvider`).
  - Material 3 `CategoriesScreen` with Income / Expense tabs, active/archived category toggle, default badges, and inline add/edit/archive/restore actions.
- **Implemented PROFILE EDIT**:
  - Material 3 `ProfileScreen` displaying user display name, read-only authenticated email, user ID, and password reset trigger.
  - Profile display name inline editor with validation, saving state, floating snackbar notifications, and immediate global state propagation.
  - Material 3 `SettingsScreen` integrating Profile Edit, Category Management, Planned Expenses, Legal links, App version info, and Sign Out.
- **Implemented PLANNED EXPENSES / MONTHLY FORECAST FOUNDATION**:
  - Domain models `PlannedExpense` and `PlannedExpenseOverride`.
  - Extended `firestore.rules` for isolated user collection paths `users/{userId}/planned_expenses/{planId}` and `users/{userId}/planned_expense_overrides/{overrideId}`.
  - `FirestorePlannedExpenseRepository` with user scoping, input validation, and category expense type verification.
  - Material 3 `PlannedExpensesScreen` featuring **Monthly Forecast** tab and **Recurring Plans** tab.
  - `AddEditPlannedExpenseDialog` and `MonthlyOverrideDialog`.
- **Implemented TRANSACTIONS & FINANCIAL AGGREGATION ENGINE**:
  - `Transaction` domain model with types `income`, `expense`, and `transfer`.
  - Strict accounting rules: Transfers have NO `categoryId` and do NOT affect Income, Expense, or Net Cash Flow.
  - Extended `firestore.rules` for isolated user collection path `users/{userId}/transactions/{transactionId}`.
  - `FirestoreTransactionRepository` with user scoping and validation (amount > 0, date required, note max 200, category type matching for income/expense, transfer account distinction).
  - `FinancialAggregationService`: Pure deterministic engine calculating `totalIncome`, `totalExpense`, `netCashFlow` (`Income - Expense`), `totalTransfers`, `expenseByCategory`, `incomeByCategory`, dynamic `accountBalances` (`openingBalance + income - expense + transferIn - transferOut`), `totalNetBalance` (applying credit card negative net balance convention), `aggregateByPeriod` (Weekly / Monthly / Yearly buckets by transaction date), and `calculatePlannedVsActual`.
  - Riverpod providers (`transactionRepositoryProvider`, `transactionsStreamProvider`, `transactionFilterProvider`, `filteredTransactionsProvider`, `calculatedAccountBalancesProvider`, `calculatedTotalBalanceProvider`, `monthlyFinancialSummaryProvider`, `plannedVsActualProvider`, `transactionControllerProvider`).
  - Material 3 `TransactionsScreen` replacing placeholder in `AppShell` with date-grouped transaction list, type filter chips (`All`, `Income`, `Expense`, `Transfer`), summary banner metrics, and `AddEditTransactionDialog`.
  - Updated `DashboardScreen` displaying live dynamic total balance, current month income, current month expenses, current month net cash flow, and real recent transactions list.
- **Note on Exclusions**:
  - Bank statement import (PDF/CSV/OCR), automatic bank sync, AI transaction parsing, push notifications, and brokerage APIs are NOT implemented.
  - Charts and Goals are NOT yet implemented (scheduled for next milestone).
  - Account `currentBalance` is NOT stored in Firestore (calculated dynamically).
  - Planned expenses are NOT automatically converted to actual transactions.
- Unit & Widget tests: 70/70 tests passed (`flutter test`).
- Static Analysis & Formatting: `dart analyze` (0 errors), `dart format .` (clean).
- Built Web distribution bundle (`flutter build web` — succeeded).

## In Progress

Core Finance (Accounts, Categories, Profile, Planned Expenses, Transactions, Aggregation Engine) complete. Next milestone: Charts & Financial Planning Visualizations.

## Next Work

Implement Financial Visualization & Charting (Category expense distribution, Monthly income vs expense trends, Cash flow charts).




## Known Issues

- `flutter doctor` reports Android SDK license status as unknown.
- Android debug build failed due to missing local NDK version 28.2.13676358 in local environment (`flutter build web` succeeded).

## Current Users

Initial target: 5–10 users.

## Current Production Status

Not released.

## Important Rule

Update this document whenever a major milestone is completed.
Do not mark a feature as completed unless it has been implemented and tested.
