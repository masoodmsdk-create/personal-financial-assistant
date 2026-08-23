# Project Status — MSD FINAURA

## Current Stage

- **Phase 0 — Foundation & Accounting Core**: COMPLETED.
- **Phase 1 — Smart Financial Entry (Foundation)**: COMPLETED.
- **Phase 2 — Loan & Debt Intelligence Module**: COMPLETED.
- **Phase 3 — Category Budgets & Variance**: UPCOMING.
- **Phase 4 — Net Worth & Unified Balance Sheet**: UPCOMING.
- **Phase 5 — Financial Intelligence & Goal Trade-Offs**: IN PROGRESS (Deterministic Loan Insights completed; Goal Trade-Off Engine upcoming).
- **Phase 6 — Ask FINAURA (Conversational Assistant Layer)**: UPCOMING.

---

## Current Target

Build a Personal Financial Assistant for:
- Personal use (expanding to family/business workspaces)
- 5–10 initial users
- Android first + Web release
- Firebase backend (strict Spark tier ₹0 cost)
- Flutter + Riverpod architecture

---

## Completed Milestones

- **Core Infrastructure & Performance**:
  - Flutter 3.x with Dart 3.13+, Material 3 design system.
  - Configured Firebase Core, Firebase Auth, Cloud Firestore with offline IndexedDB persistence enabled (`Settings(persistenceEnabled: true)`).
  - GoRouter declarative routing with automatic authentication guards across all 14 routes.
  - ₹0 operating cost architecture (Spark tier compliance).
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
- **Smart Financial Entry Assistant**:
  - `SmartParserService`: Pure local deterministic regex/ontology parser for natural language transactions.
  - `SmartEntryScreen`: Interactive draft cards, instant category/account mapping, date pickers, batch persistence.
- **Loan Management & Debt Intelligence**:
  - `DebtIntelligenceService`: Comprehensive portfolio debt aggregation, weighted interest rate, DTI ratio, and Rate Drag vs. Absolute Rupee Drain distinction engine.
  - Multi-Strategy Debt Prioritizer: **Avalanche**, **Snowball**, **Cash Flow Relief**, and **Max Interest Savings** with explainable trade-offs.
  - Refinancing & Rate Reduction Analyzer with break-even tenure calculation.
  - Dedicated `LoanDetailScreen`: Cost Breakdown, What-If Simulator, Full Amortization, and Cash Flow/Goal Impact.
  - Upgraded `LoansScreen` with portfolio banner, strategy selector, and actionable debt insights.
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
- **Automated Verification**:
  - Static Analysis: `dart analyze` (0 issues found).
  - Test Suite: `flutter test` (137/137 tests passing).
  - Web Release Build: `flutter build web --release` (built cleanly).

---

## Next Strategic Work

1. **Phase 1 Evolution**: Multi-entity Situation Understanding & Financial Blueprint Onboarding Flow (*"Tell FINAURA about your money"*).
2. **Phase 3**: Category-level monthly Budgets, threshold warning indicators, and actual vs budget variances.
3. **Phase 4**: Unified Net Worth & Balance Sheet calculation (Assets minus Liabilities).
4. **Phase 5**: Goal vs Debt Prepayment trade-off engine.
5. **Phase 6**: Ask FINAURA natural-language assistant layer.
