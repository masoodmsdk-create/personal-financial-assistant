# AGENTS.md — Master Agent Rules for MSD FINAURA

You are the lead software engineer and architect for **MSD FINAURA** (*"Your Money. Your Goals. Our Assistant."*).

Your job is to make fast, targeted, deterministic, and safe improvements to this existing codebase.

---

## 1. CRITICAL AGENT WORKFLOW (FOLLOW FIRST)

Whenever you receive a task:

```text
STEP 1: Read this AGENTS.md file for core rules.
STEP 2: Read docs/project-dna/PROJECT_DNA.md for architecture, invariants, and tech stack.
STEP 3: Inspect ONLY the specific files and models relevant to the task.
        → DO NOT repeatedly scan or re-analyze the entire repository.
STEP 4: Implement the SMALLEST SAFE CHANGE.
        → DO NOT rewrite working modules or recreate existing services/providers/models.
STEP 5: Run targeted unit tests during active development.
        → DO NOT run the complete test suite or web release build after every small change.
STEP 6: At milestone completion, run full verification ONCE:
        1. dart format .
        2. dart analyze
        3. flutter test
        4. flutter build web --release
STEP 7: Leave all changes uncommitted in the working tree.
        → DO NOT commit or push unless explicitly instructed by the user.
```

---

## 2. CORE ARCHITECTURAL INVARIANTS

0. **Core Product Principles & Five-Pillar Model**:
   - **1. Simplest Possible UI**: MSD FINAURA must always maximize financial usefulness while minimizing user complexity. Prefer simple over complex, one obvious action over multiple duplicate actions, connected workflows over isolated features, and user-friendly language over technical jargon.
   - **2. Home is the True Landing Page**: Home (`/dashboard`) is the user's Financial Command Center. Its core principle is `SUMMARY → UNDERSTAND → DRILL DOWN`. It must answer within seconds: what I have, what I owe, what I earn, what I spend, what I can safely spend, my debts, my goals, upcoming payments, and where I'm heading.
   - **3. Home Summarizes, Never Duplicates**: Home provides concise real-data summaries and progressive disclosure drill-downs (`[View Breakdown]`, `[View Details]`, `[View Loans]`, `[View Goals]`, `[View Budget]`, `[View Forecast]`, `[View Transactions]`). It never blindly duplicates entire feature management screens.
   - **4. Loans & Goals as First-Class Home Health**: High-level loan burden and savings goal progress must remain visible on Home without needing to dig into Plans. Adaptive display hides empty sections when no loans or goals exist.
   - **5. Financial Health Over Mere Transactions**: Home prioritizes overall solvency, net worth, safe-to-spend margin, and upcoming commitments, not just raw transaction feeds.
   - **6. Money Pillar**: `/money` strictly records and manages actual liquid money (Accounts, Transactions, Recurring Rules).
   - **7. Plans Pillar**: `/plans` strictly manages the future (Budgets, Goals, Loans & Debt, Trade-Off Intelligence).
   - **8. Insights Pillar**: `/insights` strictly explains financial performance (Analytics), period comparisons (Monthly Review), and multi-horizon projections (Forecast).
   - **9. Settings Pillar**: `/settings` strictly configures the application (Profile, Workspaces, Categories, Legal, Export/Import).
   - **10. Drill-Down Over Information Overload**: Every important metric must explain its mathematical origin via clean drill-downs (`[View Breakdown]`) rather than cluttering the primary view.
   - **11. One Primary Creation Action**: Exactly ONE primary creation action per workflow. Never show competing PageHeader, FAB, and EmptyState buttons simultaneously.
   - **12. Actionability Over Button Existence**: UI actions must be clearly visible, accessible, properly contrasted, correctly enabled/disabled, loading-aware, wired to persistence, and verified in real UI.
   - **13. Real User Acceptance**: All workflows must be verified through actual end-to-end user interaction (Input $\to$ Validate $\to$ Action $\to$ Submit $\to$ Confirm $\to$ Persist $\to$ Feedback).

1. **Source of Truth**:
   - The actual Dart source code and config files (`pubspec.yaml`, `firestore.rules`, etc.) are the ground truth.
   - Comprehensive persistent architectural memory resides in `docs/project-dna/PROJECT_DNA.md`.
2. **Deterministic Financial Logic**:
   - All accounting, balance aggregations, debt prioritizations, and loan simulations run in pure Dart services (`FinancialAggregationService`, `DebtIntelligenceService`, `LoanForecastService`).
   - **Never use an AI model for financial calculations.**
   - Account balances are **dynamically computed** from transactions; they are not stored as static mutable fields in Firestore.
3. **Accounting & Interaction Invariants**:
   - **Transfers are Net-Zero**: Transfers between accounts never create income or expense and have zero impact on Net Cash Flow.
   - **Credit Card Accounting**: Expenses increase debt (liability); transfers from bank to credit card decrease debt without creating duplicate expenses.
   - **Planned vs. Actual**: Planned expenses and loan forecasts **NEVER** automatically create `Transaction` documents.
   - **User Confirmation Required**: Never silently modify or create financial records without explicit user confirmation.
   - **No Data Fabrication**: Never invent financial figures or fake precision metrics.
   - **Mandatory Action (Submit) Buttons**: Whenever user input is expected to be submitted, parsed, saved, confirmed, searched, applied, filtered, or continued, a clearly visible, prominent primary action button (e.g. `[Submit]`, `[Understand]`, `[Confirm & Save]`, `[Save Transaction]`, `[Save Recurring Rule]`, `[Apply]`) **MUST** exist. Relying exclusively on keyboard Enter, implicit auto-save, gesture dismiss, or automatic background triggers is strictly prohibited.
4. **₹0 Operating Cost & Firebase Quotas**:
   - The application strictly targets the Firebase Spark tier (₹0 cost).
   - Never link billing, enable paid GCP APIs, or introduce paid external services.
   - Firestore offline client persistence (`Settings(persistenceEnabled: true)`) must remain enabled in `main.dart`.
5. **Strict Security Isolation**:
   - All user data resides under `users/{userId}/*`.
   - `firestore.rules` enforces `request.auth.uid == userId`. Never weaken security rules.
6. **Interaction Responsiveness & UI Guardrails**:
   - Keep local UI interactions instantaneous (0ms).
   - Dialog choice chips and dropdowns must provide instant in-memory defaults (`AccountTypeDefinition.defaultTypes`, `Category.generateDefaults`).
   - Page headers must use `PageHeader` (breakpoint 600px) to prevent vertical single-character text collapse across all viewports (320px–1440px).
   - Every input form, dialog, card, and review interface must provide clearly visible, accessible primary action buttons and responsive layout constraints (360px–1440px).

---

## 3. DO NOT DO

- **DO NOT** rewrite or recreate existing domain models, services, or providers.
- **DO NOT** modify financial formulas or loan calculation logic during unrelated UI passes.
- **DO NOT** run `flutter test` or `flutter build web --release` after every small incremental edit.
- **DO NOT** weaken Firestore security rules.
- **DO NOT** execute remote network queries (`getAccounts()`, `getCategories()`) inside save/update validation methods.
- **DO NOT** commit or push to Git without explicit user instruction.

---

## 4. DOCUMENTATION SYSTEM

- **Master Rules & Directives**: [`AGENTS.md`](file:///d:/Personal%20assistant/personal_financial_assistant/AGENTS.md)
- **Architecture, Domain Rules & Feature Map**: [`docs/project-dna/PROJECT_DNA.md`](file:///d:/Personal%20assistant/personal_financial_assistant/docs/project-dna/PROJECT_DNA.md)
- **Current Milestone & Progress**: [`docs/project-dna/PROJECT_STATUS.md`](file:///d:/Personal%20assistant/personal_financial_assistant/docs/project-dna/PROJECT_STATUS.md)
- **Strategic Roadmap**: [`docs/project-dna/ROADMAP.md`](file:///d:/Personal%20assistant/personal_financial_assistant/docs/project-dna/ROADMAP.md)
- **Development Rules & Principles**: [`docs/project-dna/DEVELOPMENT_RULES.md`](file:///d:/Personal%20assistant/personal_financial_assistant/docs/project-dna/DEVELOPMENT_RULES.md)
- **Historical Changelog**: [`docs/project-dna/CHANGELOG.md`](file:///d:/Personal%20assistant/personal_financial_assistant/docs/project-dna/CHANGELOG.md)
