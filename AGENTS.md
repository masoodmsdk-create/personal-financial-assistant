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
