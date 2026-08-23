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
- [ ] Multi-entity Natural Language Situation Understanding (Extracting Income, Debt Commitments, Living Expenses, Savings, and Goals from a single passage).
- [ ] Financial Blueprint Draft & Interactive Review screen before persistence.
- [ ] Progressive Guided Setup: *"Tell FINAURA about your money"* onboarding flow.
- [ ] Ambiguity resolution dialogs (asking clarifying questions rather than guessing).
- [ ] Workspace boundary & data isolation (`workspaceId` indexing with default "Personal" workspace).
- [ ] Workspace Creation options: "Start Empty" and "Copy Setup" (copying structure without duplicating financial history).

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

## Phase 3 — Category Budgets & Variance
- [ ] Category-level monthly budget allocations.
- [ ] Actual vs. Budget real-time tracking with progress indicators.
- [ ] Threshold warning indicators (50%, 80%, 100% of budget reached).
- [ ] Budget variance analysis integrated with Planned Expenses and Monthly Review.
- [ ] Flexible rollover / non-rollover budget options.

---

## Phase 4 — Net Worth & Unified Balance Sheet
- [ ] Authoritative Net Worth Calculation ($\text{Assets} - \text{Liabilities}$).
- [ ] Asset breakdown (Bank balances, Cash, Investments, Emergency reserves).
- [ ] Liability breakdown (Credit card balances + Loan outstanding principals).
- [ ] Historical Net Worth trajectory chart derived purely from confirmed transaction/loan records.
- [ ] Zero manual totals; 100% derived from authoritative data.

---

## Phase 5 — Financial Intelligence & Goal Trade-Offs
- [x] Deterministic in-app insights engine (`FinancialInsightsService`, `DebtIntelligenceService`).
- [ ] Advanced Goal Trade-Off Engine: Accelerating Loan Prepayments vs. Emergency Fund / Long-Term Savings.
- [ ] Cash flow safety margin calculation (*"How much can I safely save or spend this month?"*).
- [ ] Next Month Commitments Forecast (Fixed EMI + Planned Expenses vs. Expected Income).
- [ ] Overspending root-cause diagnosis.

---

## Phase 6 — Ask FINAURA (Conversational Assistant Layer)
- [ ] Conversational Natural-Language Interface layered on top of the deterministic domain engine.
- [ ] Answering core user questions (*"Where did my money go?"*, *"Which loan costs me the most interest?"*, *"Can I afford this?"*).
- [ ] Generating calm, non-judgmental explanations based strictly on recorded user data.
- [ ] Strict confirmation flow for any suggested record updates.
- [ ] Android release packaging & Google Play publication.
