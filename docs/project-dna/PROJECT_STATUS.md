# Project Status

## Current Stage

Phase 3 — Dashboard & Analytics: Accounts, Dynamic Categories, Profile Edit, Planned Expenses, Transactions, Financial Aggregation Engine, Charts, and Safe In-App Insights complete.

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
- Created Material 3 `AppShell` with bottom navigation bar (Dashboard, Analytics, Transactions, Accounts, Forecast, Settings) and account sign-out dialog.
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
  - `FirestoreTransactionRepository` with user scoping and validation.
  - `FinancialAggregationService`: Pure deterministic engine calculating `totalIncome`, `totalExpense`, `netCashFlow`, `totalTransfers`, `expenseByCategory`, `incomeByCategory`, dynamic `accountBalances`, `totalNetBalance` (applying credit card negative liability convention), `aggregateByPeriod`, and `calculatePlannedVsActual`.
- **Implemented ANALYTICS, CHARTS & FINANCIAL INSIGHTS**:
  - Domain model `FinancialInsight` with types `missingPlannedExpense`, `overPlanExpense`, `underPlanExpense`, `upcomingPlannedExpense` and severities `info`, `warning`, `critical`.
  - `FinancialInsightsService`: Local safe deterministic in-app insights generator without external AI API costs.
  - `CategoryBreakdownItem` and `calculateCategoryBreakdown` in `FinancialAggregationService` supporting dynamic categories (custom & archived).
  - Riverpod analytics providers (`selectedAnalyticsPeriodModeProvider`, `selectedAnalyticsDateProvider`, `periodDateRangeProvider`, `periodTransactionsProvider`, `periodSummaryProvider`, `expenseCategoryBreakdownProvider`, `incomeCategoryBreakdownProvider`, `periodPlannedVsActualProvider`, `financialInsightsProvider`).
  - UI Components: `PeriodSelectorWidget` (Weekly, Monthly, Yearly), `IncomeExpenseChartCard` (Custom Material 3 Bar Chart), `CategoryBreakdownCard` (Visual progress bars & percentages), `ThingsToReviewCard` (Actionable financial warnings & suggestions), and `AnalyticsScreen`.
  - Updated `AppShell` with Analytics tab and `DashboardScreen` with Things to Review & trend chart.
- **Note on Exclusions**:
  - Bank statement import (PDF/CSV/OCR), automatic bank sync, AI transaction parsing, paid external AI APIs, and push notifications are NOT implemented.
  - Account `currentBalance` is NOT stored in Firestore (calculated dynamically).
  - Planned expenses are NOT automatically converted to actual transactions.
- Unit & Widget tests: 85/85 tests passed (`flutter test`).
- Static Analysis & Formatting: `dart analyze` (0 errors), `dart format .` (clean).
- Built Web distribution bundle (`flutter build web` — succeeded).

## In Progress

Phase 3 Analytics and Dashboard complete. Next milestone: Phase 4 — Financial Planning (Budgets, Loans & EMI, Investments, Goals, Assets/Liabilities/Net Worth).

## Next Work

Implement Financial Planning Foundation (Budgets & Loan Amortization / Prepayment Simulator).





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
