# Changelog

## 2026-08-23 (Latest — Project DNA Consolidation & Future Agent Context)

- Created authoritative master [`docs/project-dna/PROJECT_DNA.md`](file:///d:/Personal%20assistant/personal_financial_assistant/docs/project-dna/PROJECT_DNA.md) consolidating product identity, real technology stack, architecture layers, feature map, financial domain accounting invariants, loan/goal engines, performance guardrails, and developer workflow.
- Streamlined [`AGENTS.md`](file:///d:/Personal%20assistant/personal_financial_assistant/AGENTS.md) as a concise master rulebook directing future agents directly to `PROJECT_DNA.md` to prevent repetitive codebase scanning.
- Synchronized and updated [`PROJECT_STATUS.md`](file:///d:/Personal%20assistant/personal_financial_assistant/docs/project-dna/PROJECT_STATUS.md), [`ROADMAP.md`](file:///d:/Personal%20assistant/personal_financial_assistant/docs/project-dna/ROADMAP.md), and [`DEVELOPMENT_RULES.md`](file:///d:/Personal%20assistant/personal_financial_assistant/docs/project-dna/DEVELOPMENT_RULES.md).

## 2026-08-23 (Critical Interaction Responsiveness & Firestore Offline Persistence Pass)

- **Cloud Firestore Offline Client Persistence**: Enabled `FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED)` in [`main.dart`](file:///d:/Personal%20assistant/personal_financial_assistant/lib/main.dart) to cache all Firestore documents in browser IndexedDB, eliminating remote network handshake stalls on initial stream loads and writes.
- **Repository Streamlining**:
  - `FirestoreCategoryRepository.watchCategories()`: Removed blocking `asyncMap` batch write side-effects, enabling direct stream mapping with fallback to `Category.generateDefaults` and non-blocking background seeding.
  - `FirestoreTransactionRepository._validateTransaction()` & `FirestorePlannedExpenseRepository._validatePlan()`: Removed redundant remote network calls to `getAccounts()` and `getCategories()` during save operations. Validations are now local, immediate, and deterministic.
- **Instant Dropdown & Chip Fallbacks**: Added immediate in-memory fallbacks (`AccountTypeDefinition.defaultTypes`, `Category.generateDefaults`) across all dialogs to guarantee 0ms rendering latency.
- **AppShell Tab Isolation**: Enhanced `AppShell` with lazy page mounting (`_visitedIndices`) and `TickerMode`/`Offstage` wrappers to keep inactive tabs paused during active user interactions.
- **Verification**: 119/119 tests passed (`flutter test`), 0 issues (`dart analyze`), clean formatting (`dart format .`), release web build succeeded (`flutter build web --release`).

## 2026-08-23 (Responsive Title & Character Collapse Fix)

- Resolved vertical single-character text collapse across all screens by replacing unconstrained flex layouts with responsive `PageHeader` (breakpoint 600px).
- Enforced full-width layout constraints in `ResponsiveCenter` (`width: double.infinity`) to prevent child container shrink-wrapping.
- Added bottom padding for Floating Action Buttons across list views.


- Completed application-wide UI/UX, responsiveness, and layout stabilization pass:
  - **Profile Screen Overhaul**: Resolved single-character text column collapse (`R\ne\ns\ne\nt P\na\ns\ns\nw\no\nr\nd`) by removing action buttons from constrained `ListTile.trailing` slots and introducing responsive card sections with explicit **Save Changes**, **Cancel**, and **Reset Password** buttons. Added `TextOverflow.ellipsis` to User ID text for narrow 320px viewports.
  - **Core Responsive Framework**: Created reusable `ResponsiveCenter` widget (`maxWidth: 1000` on main screens, `600` on forms/profile, `500` on dialogs) ensuring centered, optimal line-lengths on desktop web without distortion.
  - **Responsive Shell**: Enhanced `AppShell` with a `NavigationRail` on wide viewports (≥ 720px) while preserving bottom `NavigationBar` on mobile viewports (< 720px).
  - **Dynamic Dashboard Grid**: Updated `DashboardScreen` metric card grid to dynamically adapt: 4 columns (> 900px), 2 columns (500–900px), 1 column (< 500px).
  - **Financial Goals Management**: Added dedicated `GoalsScreen` & `AddEditGoalDialog` allowing users to create, edit, track, and delete savings targets, debt payoff plans, and emergency reserves.
  - **Routing & Settings**: Added `/goals` GoRoute to [`lib/core/routing/app_router.dart`](file:///d:/Personal%20assistant/personal_financial_assistant/lib/core/routing/app_router.dart) and Financial Goals tile to [`lib/features/settings/presentation/screens/settings_screen.dart`](file:///d:/Personal%20assistant/personal_financial_assistant/lib/features/settings/presentation/screens/settings_screen.dart).
  - **Verification & Testing**: Added regression tests (`profile_screen_test.dart` and `goals_screen_test.dart`). 114/114 tests passed (`flutter test`), 0 issues (`dart analyze`), clean formatting (`dart format .`), release web build succeeded (`flutter build web --release`).

## 2026-08-23 (Branding Update: MSD FINAURA)


- Updated application product branding across source code and web metadata:
  - **App Title**: `MSD FINAURA`
  - **Tagline**: `"Your Money. Your Goals. Our Assistant."`
  - **App Constants**: Centralized in [`lib/core/constants/app_constants.dart`](file:///d:/Personal%20assistant/personal_financial_assistant/lib/core/constants/app_constants.dart).
  - **Web Browser Title**: Updated `<title>MSD FINAURA</title>` and meta description in [`web/index.html`](file:///d:/Personal%20assistant/personal_financial_assistant/web/index.html).
  - **PWA Manifest**: Updated `"name": "MSD FINAURA"` and `"short_name": "FINAURA"` in [`web/manifest.json`](file:///d:/Personal%20assistant/personal_financial_assistant/web/manifest.json).
  - **UI Integration**: Consistent display across `LoginScreen`, `RegisterScreen`, `AppShell`, `DashboardScreen`, `SettingsScreen`, and Legal screens.
  - **Verification**: `dart analyze` (0 errors), `flutter test` (110/110 passed), `flutter build web --release` (succeeded).

## 2026-08-23 (Monthly Financial Review & Unified Financial Overview)


- Implemented **Monthly Financial Review & Unified Financial Overview (MSD FINAURA)**:
  - `Goal` domain model (`id`, `userId`, `name`, `type`, `targetAmount`, `currentAmount`, `targetDate`, `linkedLoanId`, `linkedAccountId`, `notes`, `active`, `createdAt`, `updatedAt`).
  - Supported goal types: Savings Goal, Debt Payoff Goal, Emergency Reserve, Custom Goal (`GoalType`).
  - Security rules (`firestore.rules`) extended to cover `users/{userId}/goals/{goalId}` restricted strictly to authenticated owner (`request.auth.uid == userId`).
  - `FinancialReviewService`: Pure domain composition service uniting transaction actuals, planned expense forecasts, in-app insights, upcoming month forecast, active goal progress, and loan payoff projections without calculation duplication.
  - Month navigation bar (`< Previous | August 2026 | Next >`).
  - Material 3 components: `MonthlySummaryCard` (with explicit `ACTUAL` / `PLANNED` badges), `ComingUpForecastCard` (with `FORECAST` expected metrics), `GoalsLoanProgressCard` (savings goals progress & loan payoff projections), `MonthlyReviewDashboardCard` (Dashboard entry card), and `MonthlyReviewScreen`.
  - Exclusions Maintained: Review forecasts are purely illustrative simulations (never modify actual loan data, create transactions, or alter account balances). No paid external AI APIs or push notifications.
  - Unit & Widget tests: 110/110 tests passed (`flutter test`).
  - Static Analysis & Formatting: `dart analyze` (0 errors), `dart format .` (clean).
  - Built Web distribution bundle (`flutter build web` — succeeded).

## 2026-08-23 (Loan Forecast & What-If Engine)


- Implemented **Loan Forecast & What-If Engine (MSD FINAURA)**:
  - `Loan` domain model supporting progressively optional fields (`id`, `userId`, `name`, `type`, `originalPrincipal`, `outstandingPrincipal`, `interestRate`, `interestRateType`, `emiAmount`, `remainingTenureMonths`, `startDate`, `nextEmiDate`, `targetClosureDate`, `linkedAccountId`, `notes`).
  - Supported loan types: Home Loan, Personal Loan, Car Loan, Education Loan, Credit Card Debt, Other Loan.
  - `LoanForecastService`: Pure deterministic engine calculating PMT EMI, remaining tenure, closure date, remaining interest, total repayment, and 12-month amortization preview without fabricating numbers.
  - What-If Prepayment & Rate Scenario Simulations (`WhatIfScenarioCard`): Extra Monthly Payment (+₹X/mo), Annual Prepayment (+₹X/yr), One-Time Lump Sum (+₹X now), Increased EMI, Target Closure Date (desired payoff date), and Custom Interest Rate scenario testing with side-by-side **CURRENT PLAN vs SCENARIO** comparison (EMI, Est. Closure, Interest Saved, Time Saved, Disclaimer notice).
  - `ImproveForecastCard`: Reusable component rendering relevant missing high-value fields with brief explanations without fake accuracy percentages.
  - `FirestoreLoanRepository` and `firestore.rules` extended for `users/{userId}/loans/{loanId}` strictly restricted to `request.auth.uid == userId`.
  - Material 3 `LoansScreen`, `AddEditLoanDialog`, `/loans` route, and settings navigation.
  - Exclusions Maintained: What-If scenarios are purely illustrative simulations (never modify actual loan data, create transactions, or alter account balances).
  - Unit & Widget tests: 103/103 tests passed (`flutter test`).
  - Static Analysis & Formatting: `dart analyze` (0 errors), `dart format .` (clean).
  - Built Web distribution bundle (`flutter build web` — succeeded).

## 2026-08-23


- Implemented **Analytics, Charts & Financial Insights**:
  - `FinancialInsight` domain model (`InsightType`, `InsightSeverity`, title, description, categoryId, amount, suggestedAction).
  - `FinancialInsightsService`: Local safe deterministic in-app insights generator without external AI API costs (identifies missing planned expenses, over-plan spending, under-plan savings, upcoming commitments).
  - Extended `FinancialAggregationService` with `CategoryBreakdownItem` and `calculateCategoryBreakdown` supporting custom and archived categories without double counting.
  - Riverpod analytics providers (`selectedAnalyticsPeriodModeProvider`, `selectedAnalyticsDateProvider`, `periodDateRangeProvider`, `periodTransactionsProvider`, `periodSummaryProvider`, `expenseCategoryBreakdownProvider`, `incomeCategoryBreakdownProvider`, `periodPlannedVsActualProvider`, `financialInsightsProvider`).
  - Material 3 Visual Components:
    - `PeriodSelectorWidget`: Segmented button controlling Weekly, Monthly, and Yearly aggregation scope with date range label and date navigation.
    - `IncomeExpenseChartCard`: Custom Material 3 dual bar chart showing comparative income vs expense across periods.
    - `CategoryBreakdownCard`: Category breakdown with color-coded progress bars and percentage share.
    - `ThingsToReviewCard`: Interactive actionable financial review warnings and suggestions card.
    - `AnalyticsScreen`: Dedicated analytics screen integrating all components, planned vs actual comparison, account balance & credit card liability overview, and empty state support.
  - Integration: Added Analytics tab to `AppShell` bottom navigation and integrated `ThingsToReviewCard` & `IncomeExpenseChartCard` into `DashboardScreen`.
  - Exclusions Maintained: No external AI APIs used, no paid infrastructure introduced, no duplicate calculations in UI widgets, no automatic transaction creation from planned expenses.
  - Unit & Widget tests: 85/85 tests passed (`flutter test`).
  - Static Analysis & Formatting: `dart analyze` (0 errors), `dart format .` (clean).
  - Built Web distribution bundle (`flutter build web` — succeeded).

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
