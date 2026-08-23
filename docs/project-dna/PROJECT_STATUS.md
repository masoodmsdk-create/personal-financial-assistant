# Project Status

## Current Stage

Phase 4 — Financial Planning: Monthly Financial Review & Unified Financial Overview, Goals, Loan Forecast & What-If Engine, Accounts, Dynamic Categories, Profile Edit, Planned Expenses, Transactions, Financial Aggregation Engine, Charts, and In-App Insights complete.

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
  - `FinancialAggregationService`: Pure deterministic engine calculating `totalIncome`, `totalExpense`, `netCashFlow`, `totalTransfers`, `expenseByCategory`, `incomeByCategory`, dynamic `accountBalances`, `totalNetBalance`, `aggregateByPeriod`, and `calculatePlannedVsActual`.
- **Implemented ANALYTICS, CHARTS & FINANCIAL INSIGHTS**:
  - `FinancialInsight` domain model and `FinancialInsightsService` (local deterministic engine operating at ₹0 AI cost).
  - Material 3 Visual Components: `PeriodSelectorWidget`, `IncomeExpenseChartCard`, `CategoryBreakdownCard`, `ThingsToReviewCard`, and `AnalyticsScreen`.
- **Implemented LOAN FORECAST & WHAT-IF ENGINE (MSD FINAURA)**:
  - Domain model `Loan` with progressively optional fields (`id`, `userId`, `name`, `type`, `originalPrincipal`, `outstandingPrincipal`, `interestRate`, `interestRateType`, `emiAmount`, `remainingTenureMonths`, `startDate`, `nextEmiDate`, `targetClosureDate`, `linkedAccountId`, `notes`).
  - `LoanForecastService`: Pure deterministic engine calculating PMT EMI, remaining tenure, closure date, remaining interest, total repayment, and 12-month amortization preview without fabricating numbers.
  - What-If Scenario Simulations (`WhatIfScenarioCard`): Extra Monthly Payment (+₹X/mo), Annual Prepayment (+₹X/yr), One-Time Lump Sum (+₹X now), Increased EMI, Target Closure Date (desired payoff date), and Custom Interest Rate scenario testing with side-by-side **CURRENT PLAN vs SCENARIO** comparison (EMI, Est. Closure, Interest Saved, Time Saved, Disclaimer notice).
  - `ImproveForecastCard`: Reusable component rendering relevant missing high-value fields with brief explanations without fake accuracy percentages.
  - `FirestoreLoanRepository` and `firestore.rules` extended for `users/{userId}/loans/{loanId}` strictly restricted to `request.auth.uid == userId`.
  - `LoansScreen`, `AddEditLoanDialog`, `/loans` route, and settings navigation.
- **Implemented MONTHLY FINANCIAL REVIEW & UNIFIED FINANCIAL OVERVIEW (MSD FINAURA)**:
  - `Goal` domain model (`id`, `userId`, `name`, `type`, `targetAmount`, `currentAmount`, `targetDate`, `linkedLoanId`, `linkedAccountId`, `notes`, `active`) and `GoalType` enum (`savingsGoal`, `debtGoal`, `emergencyFund`, `customGoal`).
  - Security rules (`firestore.rules`) extended to cover `users/{userId}/goals/{goalId}` restricted strictly to authenticated owner (`request.auth.uid == userId`).
  - `FinancialReviewService`: Pure domain composition service uniting transaction actuals, planned expense forecasts, in-app insights, upcoming month forecast, active goal progress, and loan payoff projections without calculation duplication.
  - Month navigation bar (`< Previous | August 2026 | Next >`).
  - Material 3 components: `MonthlySummaryCard` (with explicit `ACTUAL` / `PLANNED` badges), `ComingUpForecastCard` (with `FORECAST` expected metrics), `GoalsLoanProgressCard` (savings goals progress & loan payoff projections), `MonthlyReviewDashboardCard` (Dashboard entry card), and `MonthlyReviewScreen`.
- **Note on Exclusions**:
  - What-If scenarios and review forecasts are purely illustrative simulations (never modify actual loan data, create transactions, or alter account balances).
  - Bank statement import (PDF/CSV/OCR), automatic bank sync, AI transaction parsing, paid external AI APIs, and mobile push notifications are NOT implemented.
- Unit & Widget tests: 110/110 tests passed (`flutter test`).
- Static Analysis & Formatting: `dart analyze` (0 errors), `dart format .` (clean).
- Built Web distribution bundle (`flutter build web` — succeeded).

## In Progress

Monthly Financial Review & Unified Financial Overview complete. Next milestone: Phase 4 Financial Planning (Budgets & Net Worth calculation).

## Next Work

Implement Financial Planning Foundation (Budgets, Net Worth calculation, & Asset/Liability tracking).







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
