# MSD FINAURA — NEXT SESSION HANDOFF
*"Your Money. Your Goals. Our Assistant."*

> **CRITICAL DIRECTIVE FOR NEXT AGENT**:
> **DO NOT RE-SCAN OR RE-ANALYZE THE ENTIRE REPOSITORY.**
> Read this `SESSION_HANDOFF.md`, then `docs/project-dna/PROJECT_DNA.md`, and `AGENTS.md`.
> Inspect ONLY the specific models, services, and widgets relevant to your assigned task.

---

## 1. CURRENT STAGE & LAST COMPLETED

- **Current Stage**: Phase 3B Complete $\longrightarrow$ Ready for **Phase 3C: Loan vs Goal Trade-Off Intelligence**.
- **Last Completed Milestone**: **Home — Your Financial Command Center** (`DashboardScreen` redesign).
  - Answering: *Where do I stand?*, *How are goals/loans progressing?*, *What does FINAURA suggest?*
  - Composed of 6 modular sections:
    1. `FinancialSituationCard`: Live Net Balance, Income, Expense, Cash Flow + Compact Assets vs Liabilities summary pill (`/accounts`).
    2. `FinancialPlansDashboardSection` (Goals Summary): Top 1–3 prioritized goals with progress bars, targets, and dates (`/goals`).
    3. `FinancialPlansDashboardSection` (Loans Summary): Top 1–3 prioritized loans with EMIs, closure variance, and prepayment pace (`/loans/:id`).
    4. `AssistantSuggestionsSection` (🧠 FINAURA Suggests): Deterministic, explainable, actionable guidance cards with deep links.
    5. `UpcomingRemindersSection` (🔔 Upcoming): Next 30-day scheduled EMIs and planned expenses.
    6. `RecentActivitySection`: 3–5 recent transactions with `[View All]` link.
  - Domain Service: `CommandCenterService` (pure Dart, 0ms, 100% offline, ₹0 cost).
  - Providers: `commandCenterServiceProvider`, `assistantSuggestionsProvider`, `upcomingRemindersProvider`, `accountsSummaryDataProvider`.

---

## 2. CURRENT DEPLOYMENT & VERIFICATION STATUS

- **Live Beta Hosting**: [https://msd-financial-assistant.web.app](https://msd-financial-assistant.web.app) (Firebase Spark Tier, ₹0 cost).
- **Test Suite**: **167 / 167 tests passing (100% pass rate)**.
- **Static Analysis**: `dart analyze` $\rightarrow$ **0 issues found**.
- **Formatting**: `dart format .` $\rightarrow$ **Clean (167 files formatted)**.
- **Release Build**: `flutter build web --release` $\rightarrow$ **Verified (63.4s, WASM dry run clean)**.

---

## 3. WORKING TREE STATUS

- **Working Tree State**:
  - `git status` shows:
    - Staged for commit: `deleted: .firebase/hosting.YnVpbGRcd2Vi.cache` (untracked from git repo).
    - Changes not staged: `modified: .gitignore` (added `.firebase/` so generated hosting caches are permanently ignored).
  - All application code and tests from today's milestone are clean.
  - Changes left uncommitted per AGENTS.md rules until explicit user instruction.

---

## 4. ARCHITECTURE & STORAGE DECISION

- **Current Architecture**: **Cloud Firestore + IndexedDB Web Client Persistence (`Settings(persistenceEnabled: true)`)**.
- **Local-First Assessment**: Evaluated Drift / SQLite WASM. **NO MIGRATION APPROVED**. Keep current Firestore architecture.
- **Beta Data Invariant**: FINAURA is in Beta. If Local-First is ever implemented in the future, the local database will start clean (no complex production migration engine needed).
- **Domain Layer Decoupling**: All calculation services (`FinancialAggregationService`, `DebtIntelligenceService`, `LoanForecastService`, `PlanProgressService`, `CommandCenterService`, `FinancialSituationParser`) are pure, 100% testable Dart classes completely independent of the database layer.

---

## 5. IMPORTANT INVARIANTS (MUST NEVER BREAK)

1. **Deterministic Calculations First**: NEVER use an LLM or external AI API for financial calculations or accounting aggregations.
2. **Transfers are Net-Zero**: Transfers between accounts never create income or expense and have zero effect on Net Cash Flow.
3. **No Data Fabrication**: Never invent figures, balances, interest rates, or fake precision health scores.
4. **Planned vs. Actual Separation**: Planned expenses, loan forecasts, and suggestions NEVER automatically create `Transaction` documents without explicit user confirmation.
5. **No Silent Data Mutation**: `User Natural Language → Structured Draft / Blueprint → Clarification (if needed) → Review → Explicit User Confirmation → Persistence`.
6. **₹0 Operating Cost**: Strict Firebase Spark tier compliance. Never introduce paid external APIs or enable paid GCP services.
7. **Responsive UI Guardrails**: Always use `PageHeader` (breakpoint 600px) and `ResponsiveCenter` (`width: double.infinity`) to prevent letter-by-letter vertical wrapping across 320px–1440px viewports.

---

## 6. NEXT SESSION PRIMARY TASK

### Phase 3C — Loan vs Goal Trade-Off Intelligence
**Goal**: Empower the user to make optimal, transparent, and explainable decisions for extra available monthly cash flow.

**Scenario**: *"I have ₹30,000 extra this month / recurringly. Should I prepay my home loan, invest in my emergency fund, or split?"*

**Key Requirements**:
1. **Multi-Strategy Comparison Engine** (`TradeOffIntelligenceService` — pure Dart):
   - **Strategy 1 (Loan-First)**: Maximize lifetime interest savings, accelerate closure date, compute tenure reduction.
   - **Strategy 2 (Goal-First)**: Maximize liquidity / safety margin, accelerate goal target date, compute loan interest opportunity cost.
   - **Strategy 3 (Balanced 50/50)**: Equal split between debt reduction and asset accumulation.
   - **Strategy 4 (Custom Split)**: User-configured slider / percentage split.
2. **Transparent "Why" Explanations**:
   - Compare lifetime interest saved vs liquidity gained.
   - Ground recommendations in the active Workspace priorities (e.g. if priority is *"Reduce debt"*, weight Loan-First higher).
3. **Safe Execution**:
   - Comparison $\rightarrow$ Review $\rightarrow$ User Confirmation before any goal or loan target is modified.

---

## 7. STRATEGIC ROADMAP BEYOND PHASE 3C

- **Phase 4**: Category Budgets & Variance (Monthly category budget allocation, 50%/80%/100% threshold indicators, variance tracking).
- **Phase 5**: Net Worth & Balance Sheet (Authoritative Assets $-$ Liabilities $=$ Net Worth, historical trajectory).
- **Phase 6**: Financial Intelligence & Commitment Forecasts (Emergency fund adequacy, safety margins, next-month cash flow forecast).
- **Phase 7**: Ask FINAURA (Conversational assistant layer powered by deterministic financial engines).

---

## 8. DO NOT DO

- **DO NOT** scan or re-analyze the entire codebase.
- **DO NOT** rewrite working domain models, providers, or services.
- **DO NOT** start a local-first / SQLite migration.
- **DO NOT** run `flutter test` or `flutter build web --release` after every small incremental edit (run targeted tests during dev, full verification once at milestone end).
- **DO NOT** commit or push to Git without explicit user command.
- **DO NOT** deploy without explicit user command.

