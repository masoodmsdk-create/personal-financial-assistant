# Project Status

## Current Stage

Phase 4 — Financial Planning: Core Finance, Accounts & Types, Dynamic Categories, Planned Expenses & Monthly Overrides, Transactions & Accounting Engine, Loan Forecast & What-If Prepayment Simulator, Goals Management, Analytics & Charts, Monthly Financial Review, Responsive UI Across All Viewports (320px–1440px), Interaction Responsiveness Optimization, and Firestore Offline Client Persistence complete.

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

- **Core Infrastructure & Environment**:
  - Flutter 3.x with Dart 3.13+, Material 3 design system.
  - Configured Firebase Core, Firebase Auth, Cloud Firestore with offline IndexedDB/disk persistence enabled (`Settings(persistenceEnabled: true)`).
  - GoRouter declarative routing with automatic authentication guards across all 13 routes.
  - ₹0 operating cost architecture (Spark tier).
- **Authentication**:
  - `LoginScreen`, `RegisterScreen`, password visibility toggle, password strength meter, password reset dialog, terms/privacy consent checkboxes.
  - Riverpod auth providers (`authControllerProvider`, `currentUserProvider`, `authStateChangesProvider`).
- **Accounts & Types**:
  - `Account` model, `AccountTypeDefinition`, `AccountNature` (`asset`, `liability`).
  - Dynamic balance formulas (Asset: Opening + Income - Expense - Out + In; Liability: Opening + Expense - Income - In + Out).
  - `FirestoreAccountRepository`, `FirestoreAccountTypeRepository`.
  - `AccountsScreen`, `AddEditAccountDialog` (0ms chip rendering with in-memory fallbacks), `AccountTypesScreen`.
- **Dynamic Categories**:
  - `Category` model, `CategoryType` (`income`, `expense`). Transfers do NOT use categories.
  - `FirestoreCategoryRepository` with non-blocking background seeding and `Category.generateDefaults`.
  - `CategoriesScreen`, `AddEditCategoryDialog`.
- **Planned Expenses & Monthly Forecast**:
  - `PlannedExpense` recurring plans and `PlannedExpenseOverride` monthly overrides.
  - `FirestorePlannedExpenseRepository` with deterministic local validation.
  - `PlannedExpensesScreen`, `AddEditPlannedExpenseDialog`, `MonthlyOverrideDialog`.
- **Transactions & Financial Accounting Engine**:
  - `Transaction` model (`income`, `expense`, `transfer`).
  - Strict accounting invariants: Transfers are net-zero (never income or expense, zero effect on Net Cash Flow).
  - `FinancialAggregationService`: Pure deterministic engine calculating total income, total expense, net cash flow, dynamic account balances, total net balance, and category breakdowns.
  - `FirestoreTransactionRepository` with streamlined validation.
  - `TransactionsScreen`, `AddEditTransactionDialog` (with instant category in-memory fallback).
- **Loan Forecast & What-If Prepayment Engine**:
  - `Loan` model with progressively optional fields.
  - `LoanForecastService`: Deterministic PMT EMI, tenure, closure date, amortization schedule, and 5 What-If prepayment scenarios (`extraMonthly`, `annualPrepayment`, `lumpSum`, `increasedEmi`, `interestRateChange`).
  - `LoansScreen`, `AddEditLoanDialog`.
- **Goals Management**:
  - `Goal` model (`savingsGoal`, `debtGoal`, `emergencyFund`, `customGoal`).
  - `FirestoreGoalRepository`, `GoalsScreen`, `AddEditGoalDialog`.
- **Analytics & Financial Insights**:
  - `FinancialInsightsService`: Local rule-based insights ("Things to Review") at ₹0 AI cost.
  - `AnalyticsScreen` with period selector (Weekly, Monthly, Yearly), Income vs Expense bar charts, category breakdown cards.
- **Monthly Financial Review**:
  - `FinancialReviewService`: Domain aggregator uniting actual transactions, planned forecasts, loan projections, and goal progress.
  - `MonthlyReviewScreen` with month navigation and `MonthlyReviewDashboardCard`.
- **Responsive UI Architecture (320px–1440px)**:
  - `PageHeader` (breakpoint 600px) eliminating vertical single-character text collapse across all viewports.
  - `ResponsiveCenter` enforcing full-width constraints to prevent shrink-wrapping.
  - `AppShell` with adaptive `NavigationRail` ($\ge 720\text{px}$) and `NavigationBar` ($< 720\text{px}$).
- **Interaction Responsiveness & Firestore Persistence**:
  - Enabled Firestore IndexedDB persistence in `main.dart`.
  - Lazy tab mounting and `TickerMode`/`Offstage` isolation in `AppShell` to pause inactive tabs during user input.
  - Instant in-memory fallbacks for choice chips and dropdowns across all dialogs.
  - Removed redundant remote network reads from repository validation methods.
- **Automated Verification**:
  - Static Analysis: `dart analyze` (0 errors, 0 warnings).
  - Test Suite: `flutter test` (119/119 tests passing).
  - Web Release Build: `flutter build web --release` (built cleanly).

## In Progress

- Phase 4 Completion: Budgets, Net Worth calculation & Asset/Liability tracking.

## Next Work

- Implement Budgets module (category-level monthly budgets, actual vs budget thresholds, warning indicators).
- Implement Net Worth dashboard card (Assets vs Liabilities breakdown).

## Known Issues

- None blocking release or local development.
- Android builds require local Android SDK/NDK configuration (Web release builds cleanly).

## Current Users

- Initial target: 5–10 users.

## Current Production Status

- Beta testing on Firebase Hosting: `https://msd-financial-assistant.web.app`

## Important Rule

Update this document whenever a major milestone is completed.
Do not mark a feature as completed unless it has been implemented and tested.
