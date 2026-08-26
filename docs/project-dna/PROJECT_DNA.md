# MSD FINAURA — MASTER PROJECT DNA

> **Persistent Architectural Memory & Future Agent Context**
> 
> *The actual Dart source code and config files are ALWAYS the source of truth.*

---

## 1. PRODUCT IDENTITY & MASTER PHILOSOPHY

- **Product Name**: MSD FINAURA
- **Tagline**: *"Your Money. Your Goals. Our Assistant."*
- **Product Vision**: FINAURA is **NOT** just another manual expense tracker. It is a **Personal Financial Understanding + Intelligence System** that enables users to describe their financial situation naturally, transforms that into structured, reviewable data, and delivers explainable, actionable financial intelligence.

### The Master Product Interaction Flow
```text
USER TELLS FINAURA ABOUT THEIR MONEY
                 ↓
        FINAURA UNDERSTANDS
                 ↓
    FINAURA STRUCTURES (BLUEPRINT)
                 ↓
           USER REVIEWS
                 ↓
          USER CONFIRMS
                 ↓
   FINAURA CREATES / UPDATES DATA
                 ↓
    FINAURA ANALYZES PICTURE
                 ↓
     FINAURA EXPLAINS MEANING
                 ↓
      FINAURA HELPS DECIDE
```

### Core Product Principles
1. **Reduce Manual Data Entry**: Shift progressively from tedious multi-step manual entry toward guided financial understanding (*"Tell me about your finances"*).
2. **Never Trust Ambiguous Input Silently**:
   - `Natural Language → Parser → Structured Draft → Validation → Review → Confirmation → Persistence`.
   - Never silently modify or create financial records without explicit user confirmation.
   - Always prefer *"Ask / clarify / review"* over guessing.
3. **Deterministic Financial Engine First**:
   - All accounting, cash flow, debt prioritization, loan amortization, what-if forecasts, budget tracking, goal progress, and net worth calculations run in pure, testable, 100% offline Dart domain services (0ms latency, ₹0 cost).
   - **Never use an LLM or external AI API for financial calculations.**
4. **AI as a Layer, NOT the Foundation**:
   - The deterministic financial engine is the authoritative ground truth.
   - AI/LLM layers exist solely for natural-language flexibility, conversational drafting, and conversational explanations.
5. **No Data Fabrication & Calm Insight Style**:
   - Never invent balances, transactions, interest rates, or fake precision (e.g. *"Financial health score: 87.4%"*).
   - Always clearly label data sources: `ACTUAL`, `PLANNED`, `FORECAST`, `ESTIMATED`, `ILLUSTRATIVE`.
6. **Actual vs. Forecast Separation**:
   - Planned expenses and loan forecasts **NEVER** automatically create `Transaction` documents or mutate balances. Actual transactions require explicit user confirmation.
7. **Mandatory Action (Submit) Buttons**:
   - Whenever user input is expected to be submitted, parsed, saved, confirmed, searched, applied, filtered, or continued, a clearly visible, prominent primary action button (e.g. `[Submit]`, `[Understand]`, `[Confirm & Save]`, `[Save Transaction]`, `[Save Recurring Rule]`, `[Apply]`) **MUST** exist.
   - Relying exclusively on keyboard Enter, implicit auto-save, gesture dismiss, or automatic background triggers is **strictly prohibited** across all features, dialogs, cards, and screens.

---

## 2. FINANCIAL UNDERSTANDING, CLARIFICATION & THE FINANCIAL BLUEPRINT

### The Master Interactive Flow
```text
User Natural Language Input
            ↓
    Financial Parser
            ↓
Is meaning sufficiently clear?
      ├── YES ──→ Add to Blueprint Draft
      └── NO  ──→ Present Targeted Clarification Question
                        ↓
                  User Selects / Answers
                        ↓
                  Update Blueprint Dynamically
                        ↓
                  User Confirms Blueprint
                        ↓
                  Persist Records (0ms Local)
```

### Financial Situation Understanding
Evolves from single-transaction parsing to multi-entity financial situation extraction:
- **Input**: Free-form natural language describing an entire financial picture (e.g., *"Salary 1L, wife earns 60k, home loan EMI 45k, rent 20k, groceries 8k, emergency fund goal 5L"*).
- **Extraction Heads**:
  - **Income**: Primary salary, secondary income, freelance, investments.
  - **Loans / Debt Commitments**: Home loan, personal loan, car loan, credit card EMI.
  - **Recurring Expenses**: Rent, utilities, groceries, fuel.
  - **Savings & Assets**: Existing bank balances, emergency savings.
  - **Goals**: Target amounts and target timelines.

### Interactive Clarification Loop ("When to Ask")
FINAURA must **NOT** blindly guess or silently choose an interpretation when input is ambiguous.
- **Trigger Clarification When Ambiguity Materially Changes**:
  - **Entity Type**: Actual historical expense vs. recurring monthly commitment vs. planned budget.
  - **Payment vs. Commitment**: Actual EMI paid today vs. ongoing recurring loan obligation.
  - **Account Matching**: Multiple accounts matching keyword (e.g., *"Which HDFC account: Salary Account or Credit Card?"*) or unlinked account (*"Create HDFC account"*, *"Choose another"*, *"Skip for now"*).
  - **Frequency**: One-time expense vs. monthly recurring budget.
  - **Loan Association**: Payment toward specific existing loan vs. generic commitment.
- **Clarification UX Principles**:
  1. **Concise & Contextual**: Short questions with clear tap targets/chips.
  2. **Intelligent Batching**: Auto-resolve obvious items immediately without asking 5 redundant questions. Prefer batched confirmations (e.g., *"I understood these 4 items as monthly recurring amounts. Is that correct?"*).
  3. **Escape Hatches Guaranteed**: Always provide escape options (*"Not sure"*, *"Skip for now"*, *"I'll add it later"*, *"Enter manually"*). Never trap the user in an inescapable question loop.

### The Mutable Financial Blueprint
A **Financial Blueprint** is the live, mutable intermediate state representing the parsed financial picture **before** persistence.
```text
Financial Blueprint Draft (Mutable)
├── Income Heads (₹1,60,000/mo) [CONFIRMED]
├── Debt Commitments (₹45,000/mo) [CONFIRMED]
├── Recurring Living Expenses (₹28,000/mo) [CONFIRMED]
├── Estimated Net Cash Flow (₹87,000/mo) [DERIVED]
├── Existing Savings Reserves (₹2,00,000) [CONFIRMED]
└── Active Goals (Emergency Fund ₹5,00,000) [NEEDS CLARIFICATION]
```
As clarification questions are answered, the Blueprint updates reactively in memory without restarting the session. The user reviews and clicks `[Confirm & Create Setup]`.


---

## 3. WORKSPACE ARCHITECTURE, PURPOSE & FINANCIAL CONTEXT

### Architectural Purpose
A Workspace is an independent financial boundary (e.g., *Personal*, *Family Finances*, *Rental Property*, *Business / Freelance*, *Testing*). It is not merely a database container, but carries a user-provided **Workspace Purpose & Financial Context**.

### Workspace Purpose & Financial Context
When creating or configuring a Workspace, the user provides a lightweight purpose statement:
> *"What is this Workspace for? Tell FINAURA what you are managing or trying to achieve here. This helps FINAURA understand your financial context and provide more relevant insights."*

#### Concrete Context Examples:
- **Family Finances**: *"My wife and I manage our household finances here. We want to control spending, pay off our home loan faster, and build an emergency fund."*
- **Rental Property**: *"I want to track rental income, property expenses, maintenance, and loan repayment to understand whether this property is profitable."*

### Critical Architectural Rules for Workspace Purpose
1. **Purpose is Context, NOT Accounting Data**:
   - Workspace Purpose must **NEVER** modify deterministic accounting formulas.
   - It must **NEVER** override accounting invariants.
   - It must **NEVER** create or modify financial records automatically.
   - It must **NEVER** be used to invent or fabricate missing financial data (amounts, rates, balances, loans).
2. **Authoritative Financial Data First**:
   - Actual recorded financial data is always authoritative.
   - The Purpose provides context to the Financial Intelligence layer (influencing insight emphasis, relevant suggestions, dashboard focus, and Ask FINAURA explanations).
3. **User Control & Full Mutability**:
   - Workspace Purpose is completely editable at any time under **Workspace Settings** (`name`, `purpose`, optional `priorities`).
4. **Simple 3-Step Creation UX**:
   - Step 1: Name the Workspace.
   - Step 2: Tell FINAURA why it exists (Purpose).
   - Step 3: Choose starting mode (`Start Empty` vs. `Copy Setup`).
5. **Data Isolation & Privacy**:
   - Documents reside at `users/{userId}/{collection}/{documentId}` with an indexed `workspaceId` field.
   - All queries filter strictly by `request.auth.uid == userId` and `workspaceId == activeWorkspaceId`.
   - Workspace purpose and financial data are strictly isolated; zero leakage across workspaces or users.
6. **Workspace Duplication ("Copy Setup")**:
   - `Copy Setup` duplicates reusable structures (categories, account types, planned expense templates, goal definitions).
   - **Never duplicates historical transactions, account balances, or actual loan payment records.**


---

## 4. REAL TECHNOLOGY STACK

*Verified against `pubspec.yaml`, `firebase.json`, and source code:*

- **Framework**: Flutter (Material 3 enabled, Android-first, Web-supported)
- **Language**: Dart (SDK `^3.13.1`)
- **State Management**: Flutter Riverpod (`^2.6.1`)
- **Routing**: GoRouter (`^14.6.2`) with declarative authentication guards
- **Backend / Database**:
  - **Firebase Core**: `^4.13.0`
  - **Firebase Authentication**: `^6.0.2` (Email/Password authentication)
  - **Cloud Firestore**: `^6.0.1` (IndexedDB / Disk offline persistence enabled, cache size unlimited)
  - **Hosting**: Firebase Hosting (`msd-financial-assistant.web.app`)
- **Formatting / Internationalization**: `intl: ^0.19.0` (Default currency `INR / ₹`, locale `en_IN`)
- **Code Generation / Serialization**: `freezed_annotation: ^3.0.0`, `json_annotation: ^4.9.0`
- **Cost Objective**: ₹0 recurring operating cost (strict Firebase Spark tier compliance).

---

## 5. PROJECT ARCHITECTURE & LAYER RESPONSIBILITIES

```text
Presentation Layer (Screens, Widgets, Dialogs, Adaptive Shell)
        ↓ (watches/reads)
Riverpod Providers & Controllers (State management, Memoized aggregations)
        ↓ (invokes)
Deterministic Domain Layer (Pure Dart services, Entities, Value objects)
        ↓ (implemented by)
Data Layer (Firestore repositories, FirestoreService wrapper)
        ↓ (persists to)
Firebase (Cloud Firestore with local offline client cache enabled)
```

### Authoritative Domain Services Matrix
| Service Name | Source Location | Responsibility |
| :--- | :--- | :--- |
| `FinancialAggregationService` | `lib/features/transactions/domain/services/` | Computes income/expense totals, net cash flow, category breakdowns, period aggregations, dynamic account balances, and planned vs. actual differences. |
| `DebtIntelligenceService` | `lib/features/loans/domain/services/` | Portfolio debt analytics, Avalanche vs Snowball vs Cash Flow prioritization, refinancing cost-benefit, and deterministic loan insights. |
| `LoanForecastService` | `lib/features/loans/domain/services/` | Standard PMT EMI, tenure, closure date, amortization schedule, and 6 What-If prepayment simulations. |
| `FinancialInsightsService` | `lib/features/analytics/domain/services/` | Rule-based financial insights ("Things to Review") evaluating spending spikes, cash-flow margin, and category variances. |
| `FinancialReviewService` | `lib/features/review/domain/services/` | Compiles comprehensive monthly review packages uniting actual transactions, planned forecasts, debt obligations, and goal savings. |
| `SmartParserService` | `lib/features/smart_entry/domain/services/` | Pure Dart local deterministic regex & ontology parser extracting amounts, dates, types, categories, accounts, and loan notes. |

---

## 6. FINANCIAL DOMAIN & ACCOUNTING INVARIANTS

### Core Accounting Rules
1. **Income**: Total sum of incoming transactions assigned to an Income category.
2. **Expense**: Total sum of outgoing transactions assigned to an Expense category.
3. **Net Cash Flow**: `Total Income - Total Expense`.
4. **Transfers are Net-Zero**: Moving money between two accounts (`From Account → To Account`) never creates income or expense and has **ZERO** impact on Net Cash Flow. `categoryId` must be null.
5. **Credit Card Debt Accounting**:
   - Expenses increase Credit Card liability.
   - Transfer from Bank $\rightarrow$ Credit Card decreases bank asset and decreases credit card liability without creating duplicate expenses.
6. **Dynamic Account Balances (No Stored Balance Fields)**:
   - Account balances are dynamically computed in memory by `FinancialAggregationService`.
   - $\text{Asset Balance} = \text{Opening Balance} + \text{Income} - \text{Expense} - \text{Transfers Out} + \text{Transfers In}$.
   - $\text{Liability Balance} = \text{Opening Balance} + \text{Expense} - \text{Income} - \text{Transfers In} + \text{Transfers Out}$.
7. **Unified Net Worth**:
   - $\text{Net Worth} = \sum \text{Authoritative Asset Balances} - \sum \text{Authoritative Liabilities (Credit Cards + Loan Principals)}$.

---

## 7. LOAN INTELLIGENCE & DEBT PRIORITIZATION

- **Progressive Fields**: `name`, `type`, `outstandingPrincipal`, `interestRate`, `interestRateType`, `emiAmount`, `remainingTenureMonths`, `lenderName`, `processingFee`, `prepaymentCharges`.
- **Debt Prioritization Strategies**:
  1. **Avalanche (Highest Rate First)**: Mathematically minimizes lifetime interest paid.
  2. **Snowball (Smallest Balance First)**: Delivers fast psychological momentum and eliminates monthly commitment lines quickly.
  3. **Cash Flow Relief**: Prioritizes highest monthly EMI freed relative to balance.
  4. **Max Interest Savings**: Targets the largest absolute rupee interest drain.
- **Nuance Engine**: Explicitly distinguishes between *Highest Interest Rate* (rate drag) and *Highest Absolute Interest Cost* (rupee drain).
- **Refinancing Analyzer**: Evaluates rate reductions, deducting switching fees and prepayment penalties to calculate net savings and break-even tenure.

---

## 8. FINANCIAL PLANS & PROGRESS (PLAN → ACTUAL → PROJECTION → VARIANCE → EXPLANATION)

### The Core Progress Paradigm
```text
PLAN (User Target / Scheduled Milestone)
  ↓
ACTUAL (Recorded Payments / Contributions)
  ↓
PROJECTION (Estimated Payoff / Completion Date)
  ↓
VARIANCE (Difference Between Target & Projection)
  ↓
EXPLANATION (Neutral, Factual Financial Explanation)
```

### Deterministic Status Model
- **`AHEAD`**: Current projected completion is before the target date ($\text{variance} \le -1\text{ month}$).
- **`ON_TRACK`**: Current projected completion matches the target date ($\text{variance} = 0$).
- **`SLIGHTLY_BEHIND`**: Deviation between 1–4 months. Explanation: *"Your recorded extra prepayment is below the current plan."* or *"Your current contribution pace projects completion about X months after your target."*
- **`BEHIND`**: Deviation $> 4$ months.
- **`AT_RISK`**: Target date has passed or $> 12$ months behind.
- **`NO_TARGET`**: User has not set a target closure/completion date. Never marks ahead/behind without a target.
- **`INSUFFICIENT_DATA`**: Critical parameters missing (e.g. balance or EMI) to project completion date.

### Core Architectural Invariants
1. **Dynamic Recovery**: Status recalculates dynamically with each extra prepayment or contribution (no permanent "failure" labels).
2. **Explainability**: Always explain deviations using neutral factual financial terms.
3. **Dashboard Integration**: Shows consolidated portfolio totals and top 1–3 prioritized cards (prioritized by attention needs, target dates, and workspace purpose context).
4. **Foundation for Trade-Off Intelligence**: Directly prepares the platform for future Loan Prepayment vs. Goal Investment Trade-Offs (Phase 3B).

---

---

## 9. HOME — YOUR FINANCIAL COMMAND CENTER

### The Master Command Center Flow
$$\text{UNDERSTAND} \longrightarrow \text{SELECT} \longrightarrow \text{NAVIGATE} \longrightarrow \text{ACT}$$

### Core Architecture & Hierarchy
1. **Workspace Context Header**: Active workspace name, user greeting, and quick onboarding action.
2. **Section 1: Current Financial Situation (`FinancialSituationCard`)**:
   - Total Net Balance, Monthly Income, Monthly Expenses, Remaining Cash Flow.
   - Compact Accounts Summary card (active count, assets vs liabilities) linking to `/accounts`.
3. **Section 2 & 3: Goals & Loans Portfolio (`FinancialPlansDashboardSection`)**:
   - Top 1–3 prioritized goals & loans with progress bars, EMIs, target vs projected dates, status chips, and deep links (`/loans/:loanId`, `/goals`).
4. **Section 4: 🧠 FINAURA Suggests (`AssistantSuggestionsSection`)**:
   - Deterministic, explainable, neutral, and factual assistant guidance derived strictly from confirmed user data (0ms, 100% offline, ₹0 cost).
   - Contextual navigation button per suggestion card.
5. **Section 5: 🔔 Upcoming (`UpcomingRemindersSection`)**:
   - Scheduled EMIs and planned expenses due in the next 30 days with due date pills and direct item navigation.
6. **Section 6: Recent Activity (`RecentActivitySection`)**:
   - 3–5 recent transactions with signed MoneyText and `[View All]` action to `/transactions`.

### Domain Service
- `CommandCenterService`: Pure Dart service generating suggestions, upcoming reminders, and accounts summary without new Firestore reads.

---

## 10. LOCAL-FIRST STORAGE EVALUATION & STATUS

- **Investigation Status**: Evaluated moving primary persistence from Cloud Firestore + IndexedDB to a local-first relational database (Drift / SQLite WASM).
- **Current Decision**: **Storage architecture remains 100% UNCHANGED (Firestore + IndexedDB web client persistence)**.
- **Migration Invariant**: Any future local-first migration must be proven simple, reliable, and invisible to users before adoption. Domain services are already 100% pure Dart and decoupled from storage.
- **Beta Data Invariant**: FINAURA is in Beta. If local-first is ever implemented, beta data can start clean (no complex production migration system required).

---

## 11. FIRESTORE DATA MODEL & SECURITY

```text
users/{userId}
├── workspaces/{workspaceId}
├── accounts/{accountId}
├── account_types/{typeId}
├── categories/{categoryId}
├── transactions/{transactionId}
├── planned_expenses/{planId}
├── planned_expense_overrides/{overrideId}
├── loans/{loanId}
└── goals/{goalId}
```

### Security Rules Invariant
```javascript
match /users/{userId}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```
*Strict user isolation enforced at database level. Never weaken rules.*

---

## 12. PERFORMANCE GUARDRAILS & ARCHITECTURAL RULES

1. **Firestore Client Persistence**: Must remain enabled (`Settings(persistenceEnabled: true)`) in `main.dart` for instant cache reads.
2. **0ms Save Validation**: Save and update methods validate in memory without executing remote network queries.
3. **Instant Dropdown & Chip Fallbacks**: In-memory defaults (`AccountTypeDefinition.defaultTypes`, `Category.generateDefaults`) prevent loading delays in dialogs.
4. **AppShell Tab Isolation**: Inactive tabs are lazily mounted and paused via `TickerMode`/`Offstage`.
5. **No Full-Screen Loading Spinners**: Stream builders use `skipLoadingOnReload: true` and `skipLoadingOnRefresh: true`.
6. **Responsive UI Guardrails**: All pages use `PageHeader` (breakpoint 600px) and `ResponsiveCenter` (`width: double.infinity`) to prevent single-character text collapse across 320px–1440px viewports.

