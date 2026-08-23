# Product Roadmap — MSD FINAURA

> **Vision**: Personal Financial Understanding + Intelligence System
>
> *"Your Money. Your Goals. Our Assistant."*

---

## Phase 0 — Foundation & Accounting Core
- [x] Flutter 3.x with Dart 3.13+, Material 3 design system.
- [x] Firebase Core & Cloud Firestore with offline IndexedDB client caching.
- [x] Firestore security rules (owner-isolated `users/{userId}/*`).
- [x] Email/password registration, login, profile, and GoRouter auth guards.
- [x] Dynamic Accounts & Account Types (`bank`, `cash`, `creditCard`, `wallet`, custom).
- [x] Dynamic Categories Foundation (Income & Expense categories, system defaults, archiving).
- [x] Planned Expenses & Monthly Forecast Engine (Recurring plans + monthly overrides).
- [x] Transactions with strict accounting invariants (Transfers are net-zero; Credit card debt accounting).
- [x] Pure deterministic calculation engine (`FinancialAggregationService`) for dynamic account balances.
- [x] Responsive layout across 320px–1440px viewports (`PageHeader`, `ResponsiveCenter`, `AppShell`).
- [x] 0ms local dialog interaction responsiveness & IndexedDB client persistence.

---

## Phase 1 — Financial Setup & Financial Blueprint
- [x] Smart Financial Entry Assistant foundation (`SmartParserService`, `SmartEntryScreen`).
- [x] Multi-entity Natural Language Situation Understanding (`FinancialSituationParser`).
- [x] Conversational Clarification Engine (Targeted questions, selectable chips, escape hatches: *"Skip for now"*, *"I'll add later"*).
- [x] Interactive Mutable Financial Blueprint Draft & Review screen (`FinancialBlueprint`, `FinancialSetupScreen`) with safe explicit confirmation.
- [x] Workspace Purpose & Context layer (`Workspace`, `CreateWorkspaceDialog`, `EditWorkspaceDialog`, `_WorkspaceContextCard`).

---

## Phase 2 — Loan & Debt Intelligence
- [x] Progressive Loan Entity (`lenderName`, `processingFee`, `prepaymentCharges`, `linkedAccountId`).
- [x] Loan Forecast & Amortization Engine (`LoanForecastService`).
- [x] Portfolio Debt Burden Analytics (`DebtIntelligenceService`: Total Debt, Total EMI, Remaining Interest, Weighted Average Rate, DTI ratio).
- [x] Multi-Strategy Debt Prioritizer: **Avalanche** (Highest Rate), **Snowball** (Smallest Balance), **Cash Flow Relief** (Highest EMI Freed), **Max Interest Savings** (Total Rupee Cost).
- [x] Rate Drag vs. Absolute Rupee Drain distinction engine.
- [x] Refinancing & Rate Reduction Cost-Benefit Analyzer with break-even tenure calculation.
- [x] Dedicated Multi-Tab Loan Detail Experience (`LoanDetailScreen`: Cost & Breakdown, What-If Simulator, Full Amortization, Cash Flow & Goals).
- [x] Upgraded `LoansScreen` with portfolio banner, strategy selector, and actionable insights.

---

## Phase 3A — Financial Plans & Progress (PLAN → ACTUAL → PROJECTION → VARIANCE → EXPLANATION)
- [x] Core Progress & Variance Domain Engine (`PlanProgressService`, `PlanProgressStatus`).
- [x] Explainable Loan Progress tracking (Outstanding, EMI, EMIs Remaining, Target Closure vs Projected Closure, Dynamic Prepayment Recovery).
- [x] Explainable Goal Progress tracking (Current vs Target, Progress %, Target Date vs Projected Date, Average Contribution Pace).
- [x] Neutral, factual financial explanations for all variance states.
- [x] Consolidated Dashboard Financial Plans section (`FinancialPlansDashboardSection`) with summary pills, prioritized cards, and quick navigation.
- [x] Context-aware prioritization based on Workspace Purpose and active attention triggers.

---

## Phase 3B — Loan vs Goal Trade-Off Intelligence (Next Priority)
- [ ] Extra Cash Flow allocator (Loan Prepayment vs Goal Investment).
- [ ] Multi-scenario strategy comparison (Loan-First vs Goal-First vs Balanced 50/50 vs Custom Split).
- [ ] Net Worth, lifetime interest saved, and timeline comparison engine.

---

## Phase 4 — Category Budgets & Variance
- [ ] Category-level monthly budget allocations.
- [ ] Actual vs. Budget real-time tracking with progress indicators.
- [ ] Threshold warning indicators (50%, 80%, 100% of budget reached).
- [ ] Budget variance analysis integrated with Planned Expenses and Monthly Review.
- [ ] Flexible rollover / non-rollover budget options.

---

## Phase 5 — Net Worth & Unified Balance Sheet
- [ ] Authoritative Net Worth Calculation ($\text{Assets} - \text{Liabilities}$).
- [ ] Asset distribution breakdown (Cash, Bank, Investments, Real Estate).
- [ ] Liability breakdown (Secured Loans, Unsecured Loans, Credit Card Debt).
- [ ] Net Worth growth tracking over time.

---

## Phase 6 — Broader Financial Intelligence
- [ ] Emergency Fund runway calculator (Liquid Assets / Monthly Living Expenses).
- [ ] Savings rate trajectory analytics.
- [ ] Discretionary spending risk alerts.
- [x] Deterministic in-app insights engine (`FinancialInsightsService`, `DebtIntelligenceService`).
- [ ] Advanced Goal Trade-Off Engine: Accelerating Loan Prepayments vs. Emergency Fund / Long-Term Savings.
- [ ] Cash flow safety margin calculation (*"How much can I safely save or spend this month?"*).
- [ ] Next Month Commitments Forecast (Fixed EMI + Planned Expenses vs. Expected Income).
- [ ] Overspending root-cause diagnosis.

---

## Phase 7 — Ask FINAURA (Conversational Assistant Layer)
- [ ] Natural language query answering grounded in local deterministic calculations.
- [ ] Scenario exploration (*"Can I afford a ₹30,000 vacation next month?"*).
- [ ] Conversational explainability of trade-offs, loan amortizations, and cash flow trends.
- [ ] Generating calm, non-judgmental explanations based strictly on recorded user data.
- [ ] Strict confirmation flow for any suggested record updates.
- [ ] Android release packaging & Google Play publication.
