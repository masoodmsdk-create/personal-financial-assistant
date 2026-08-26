# Development Rules & Principles

## 1. Golden Rule
- **MSD FINAURA MUST BE AS SIMPLE AS POSSIBLE FOR THE USER**: Maximum financial usefulness with minimum user complexity.
- Do not build complexity that we do not currently need.
- Prefer simple over complex, one obvious action over multiple duplicate actions, connected workflows over isolated features, and user-friendly language over technical jargon.
- Always reuse existing screens, models, services, and providers before creating new components.
- The application begins with 5–10 users. Build cleanly, securely, and deterministically now; scale later.

---

## 2. Before Making Any Code Changes
1. **Read `AGENTS.md` and `docs/project-dna/PROJECT_DNA.md` first.**
2. Inspect only the files and models relevant to the specific task.
3. Understand existing architecture before modifying it.
4. **Never rewrite or recreate existing services, providers, or models.**
5. Check whether the requested functionality already exists.
6. Prefer the **SMALLEST SAFE CHANGE**.

---

## 3. Financial & Accounting Rules
1. All financial calculations must be implemented deterministically in Dart domain services (`FinancialAggregationService`, `LoanForecastService`, etc.).
2. **Never use an AI model for financial calculations.**
3. **Transfers are Net-Zero**: Moving money between accounts does not affect income, expense, or net cash flow.
4. **Credit Card Accounting**: Expenses increase liability debt; payments from bank to credit card decrease bank asset and decrease debt without creating duplicate expenses.
5. **Planned vs. Actual Invariant**: Planned expenses **NEVER** silently become actual transactions; actual transactions require explicit user action.
6. All financial logic must have automated unit tests.

---

## 4. Firebase Cost & Efficiency Rules (₹0 Spark Tier Target)
1. **Never intentionally introduce paid cloud services, paid AI APIs, or link billing.**
2. **Local Caching**: Maintain `FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true)` in `main.dart`.
3. Query only necessary date ranges and collections.
4. Do not poll Firestore or add redundant realtime listeners.
5. **Deterministic Save**: Do not execute remote network reads (`getAccounts()`, `getCategories()`) inside save/update validation methods.

---

## 5. Security & Isolation Invariant
1. All user financial data strictly resides under `users/{userId}/*`.
2. `firestore.rules` must enforce `request.auth.uid == userId` for all subcollections.
3. Never weaken security rules or allow cross-user access.
4. Never log or commit secrets, credentials, or private tokens.

---

## 6. UI & Responsive Guidelines
1. Material 3 design system, responsive across `320px` to `1440px`.
2. Main content must be centered and width-constrained (`ResponsiveCenter`).
3. Always use `PageHeader` (breakpoint 600px) for titles; never allow page titles to vertically collapse into character-by-character columns.
4. Dialogs must have instant in-memory fallbacks (`AccountTypeDefinition.defaultTypes`, `Category.generateDefaults`) so dropdowns/chips render with 0ms delay.
5. `AppShell` uses lazy tab mounting and `TickerMode`/`Offstage` to pause inactive tabs during user interactions.
6. **Mandatory Action (Submit) Buttons**: Any user input feature (forms, dialogs, smart entry input, review cards, filter bars) where data is submitted, saved, parsed, searched, applied, or confirmed **MUST** have an explicit, prominent, clearly labeled primary action button (e.g. `[Submit]`, `[Understand]`, `[Save Transaction]`, `[Save Recurring Rule]`, `[Confirm & Save]`). Relying solely on keyboard Enter or background implicit triggers is forbidden.

---

## 7. Milestone Verification Workflow
1. **DO NOT run `flutter test` or `flutter build web --release` after every small change.**
2. During active development, prioritize inspection, local reasoning, and targeted checks.
3. At the end of a milestone, run the complete verification suite ONCE:
   ```bash
   dart format .
   dart analyze
   flutter test
   flutter build web --release
   ```
4. **DO NOT commit or push to Git unless explicitly instructed by the user.**
