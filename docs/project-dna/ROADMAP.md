# Product Roadmap

## Phase 0 — Foundation
- [x] Inspect development environment
- [x] Configure Flutter (Dart 3.13+, Material 3)
- [x] Configure Firebase Core & Cloud Firestore for Android and Web
- [x] Establish Firestore security rules (owner-isolated `users/{userId}/*`)
- [x] Enable Firestore offline IndexedDB client caching
- [x] Create project DNA & persistent developer context

## Phase 1 — Authentication
- [x] Email/password registration with password strength meter
- [x] Login & Logout
- [x] Password reset trigger
- [x] Reactive authentication state stream (`authStateChangesProvider`)
- [x] User profile & Profile edit (Display Name editor)
- [x] Declarative GoRouter navigation guards

## Phase 2 — Core Finance
- [x] Dynamic Accounts & Account Types (`bank`, `cash`, `creditCard`, `wallet`, custom)
- [x] Dynamic Categories Foundation (Income & Expense categories, system defaults, archiving)
- [x] Planned Expenses & Monthly Forecast Engine (Recurring plans + monthly overrides)
- [x] Transactions (Income, Expense, Transfer)
- [x] Strict accounting invariants (Transfers are net-zero; Credit card debt accounting)
- [x] Dynamic account balance calculation engine (`FinancialAggregationService`)
- [x] Transaction search, filtering, and history

## Phase 3 — Dashboard, Analytics & Review
- [x] Financial overview & live summary metric cards
- [x] Monthly income, monthly expenses, net cash flow
- [x] Spending categories breakdown
- [x] Income vs. Expense bar charts
- [x] Period selection (Weekly, Monthly, Yearly)
- [x] In-app financial insights ("Things to Review" local rule engine)
- [x] Monthly Financial Review screen (Actual vs Planned, Forecast commitments, Loan/Goal progress)
- [x] Responsive layout across 320px–1440px viewports (Adaptive shell, `PageHeader`, `ResponsiveCenter`)
- [x] Fast user interaction & dialog responsiveness (0ms chip/dropdown fallbacks, lazy tab isolation)

## Phase 4 — Financial Planning
- [ ] Category-level Budgets & threshold warning alerts
- [x] Loans & Debt tracking
- [x] PMT EMI & amortization schedules
- [x] What-If loan prepayment simulation engine
- [ ] Manual Investments tracking
- [x] Financial Goals management (Savings, Debt, Emergency fund, Custom)
- [ ] Unified Net Worth calculation (Total Assets - Total Liabilities)

## Phase 5 — Assistant & Natural Language
- [ ] Deterministic natural-language transaction entry
- [ ] Financial Q&A assistant (Rule-based / Template-based answering from actual stored data)
- [ ] Spending & budget variance summaries
- [ ] Loan & goal progress recommendations

## Phase 6 — Intelligence & Production
- [ ] Cash-flow forecasting & future projection models
- [ ] Data export (JSON / CSV backup)
- [ ] Comprehensive security and performance audit
- [ ] Android release APK / AAB packaging
- [ ] Google Play Store preparation & publication
