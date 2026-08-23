# MSD FINAURA — MASTER PROJECT DNA

> **Persistent Architectural Memory & Future Agent Context**
> 
> *The actual codebase is ALWAYS the source of truth.*

---

## 1. PRODUCT IDENTITY & PHILOSOPHY

- **Product Name**: MSD FINAURA
- **Tagline**: *"Your Money. Your Goals. Our Assistant."*
- **Purpose**: FINAURA is a personal financial assistant designed to help users organize, understand, forecast, and improve their finances using user-provided information.
- **Core Philosophy**:
  1. **User's Money, User's Goals**: The assistant assists, calculates, and guides; the user remains in complete control.
  2. **Minimal Unnecessary Data Entry**: Never force users to repeatedly enter recurring information that can already be derived.
  3. **Progressive Information Collection**: Forecasts and insights work with whatever data is currently available without blocking the user.
  4. **Never Fabricate Data**: Never invent financial figures or accuracy percentages.
  5. **Actual vs. Forecast Separation**: Clear visual and architectural distinction between confirmed historical transactions and future planned/forecast numbers.
  6. **Explicit User Action Required**: Planned expenses **NEVER** silently become actual transactions; recording an actual transaction always requires an explicit user action.

---

## 2. REAL TECHNOLOGY STACK

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

## 3. PROJECT ARCHITECTURE & LAYER INTERACTION

The project follows a clean, feature-driven, layered architecture:

```text
Presentation Layer (Screens, Widgets, Dialogs)
       ↓ (watches/reads)
Riverpod Providers / StateNotifiers (State management, Memoized aggregations)
       ↓ (invokes)
Domain Layer (Entities, Pure calculation services, Repository interfaces)
       ↓ (implemented by)
Data Layer (Firestore repositories, FirestoreService wrapper)
       ↓ (persists to)
Firebase (Cloud Firestore with local offline caching enabled)
```

### Directory Structure
```text
lib/
├── core/
│   ├── constants/       # AppConstants, String labels
│   ├── errors/          # AppException, AuthException, ValidationException, FirestoreException
│   ├── models/          # Entity base interface
│   ├── routing/         # GoRouter configuration & auth guards (app_router.dart)
│   ├── services/        # FirestoreService base CRUD & batch write abstractions
│   ├── theme/           # AppTheme (Light & Dark Material 3 theme definitions)
│   ├── utils/           # Formatters, helpers
│   └── widgets/         # FinancialWidgets (MoneyText, PageHeader, EmptyStateWidget, etc.), ResponsiveCenter
├── features/
│   ├── accounts/        # Account models, types, providers, dialogs, screens
│   ├── analytics/       # Period aggregations, category breakdowns, chart widgets
│   ├── auth/            # Auth models, controllers, login/register screens, consent
│   ├── categories/      # Category entity, defaults generator, categories screen
│   ├── dashboard/       # AppShell (adaptive navigation), DashboardScreen, overview cards
│   ├── goals/           # Goal models, goal controller, dialogs, goals screen
│   ├── legal/           # Privacy notice, Terms of service, Financial disclaimer
│   ├── loans/           # Loan entity, LoanForecastService, What-If engine, loan dialogs, screens
│   ├── planned_expenses/# PlannedExpense, overrides, monthly forecast, dialogs
│   ├── profile/         # ProfileScreen, display name editor
│   ├── review/          # MonthlyReviewService, MonthlyReviewScreen, review widgets
│   ├── settings/        # SettingsScreen
│   └── transactions/    # Transaction model, FinancialAggregationService, dialogs, screen
├── firebase_options.dart # Auto-generated FlutterFire options
└── main.dart            # App entry point, Firebase init & Firestore cache settings
```

---

## 4. FEATURE MAP & RESPONSIBILITIES

| Feature | Key Domain Models | Key Services & Repositories | Key Providers / Controllers | Key Screens / Dialogs |
| :--- | :--- | :--- | :--- | :--- |
| **Auth** | `User` (Firebase) | `FirebaseAuthRepository` | `authControllerProvider`, `currentUserProvider`, `authStateChangesProvider` | `LoginScreen`, `RegisterScreen` |
| **Accounts** | `Account`, `AccountTypeDefinition`, `AccountNature` | `FirestoreAccountRepository`, `FirestoreAccountTypeRepository` | `accountsStreamProvider`, `accountTypesStreamProvider`, `accountControllerProvider` | `AccountsScreen`, `AddEditAccountDialog`, `AccountTypesScreen` |
| **Transactions** | `Transaction`, `TransactionType` | `FirestoreTransactionRepository`, `FinancialAggregationService` | `transactionsStreamProvider`, `transactionFilterProvider`, `transactionControllerProvider` | `TransactionsScreen`, `AddEditTransactionDialog` |
| **Categories** | `Category`, `CategoryType` | `FirestoreCategoryRepository` | `categoriesStreamProvider`, `incomeCategoriesProvider`, `expenseCategoriesProvider` | `CategoriesScreen`, `AddEditCategoryDialog` |
| **Planned Expenses** | `PlannedExpense`, `PlannedExpenseOverride`, `RecurrenceFrequency` | `FirestorePlannedExpenseRepository` | `plannedExpensesStreamProvider`, `monthlyOverridesStreamProvider`, `monthlyForecastProvider` | `PlannedExpensesScreen`, `AddEditPlannedExpenseDialog`, `MonthlyOverrideDialog` |
| **Loans** | `Loan`, `LoanType`, `InterestRateType`, `LoanForecastResult`, `WhatIfScenarioResult` | `FirestoreLoanRepository`, `LoanForecastService` | `loansStreamProvider`, `selectedLoanProvider`, `loanForecastProvider`, `whatIfScenarioResultProvider` | `LoansScreen`, `AddEditLoanDialog` |
| **Goals** | `Goal`, `GoalType` | `FirestoreGoalRepository` | `goalsStreamProvider`, `goalControllerProvider` | `GoalsScreen`, `AddEditGoalDialog` |
| **Dashboard** | `MonthlySummaryData` | `FinancialAggregationService` | `calculatedTotalBalanceProvider`, `monthlyFinancialSummaryProvider` | `AppShell`, `DashboardScreen` |
| **Analytics** | `CategoryBreakdownItem`, `PeriodFinancialSummary`, `FinancialInsight` | `FinancialAggregationService`, `FinancialInsightsService` | `periodSummaryProvider`, `expenseCategoryBreakdownProvider`, `financialInsightsProvider` | `AnalyticsScreen` |
| **Monthly Review** | `MonthlyReviewData`, `CashFlowSummary`, `LoanForecastSummaryItem` | `FinancialReviewService` | `selectedReviewDateProvider`, `monthlyReviewDataProvider` | `MonthlyReviewScreen` |
| **Profile & Settings** | User Profile metadata | `FirebaseAuthRepository` | `profileControllerProvider` | `ProfileScreen`, `SettingsScreen` |

---

## 5. FINANCIAL DOMAIN & ACCOUNTING INVARIANTS

### Core Definitions
- **Income**: Total sum of incoming transactions assigned to an Income category.
- **Expense**: Total sum of outgoing transactions assigned to an Expense category.
- **Net Cash Flow**: `Total Income - Total Expense`.
- **Transfers**: Moving money between two accounts (`From Account → To Account`).
  - **Transfer Invariant**: Transfers **NEVER** create income or expense and have **ZERO** effect on Net Cash Flow.
- **Transaction Date**: Always use `transaction.date` for monthly/period aggregation. Never substitute `createdAt`.

### Dynamic Balance Calculation (No Stored Balance Fields)
Account balances are **NOT** stored as static mutable fields in Firestore. They are computed deterministically in memory via `FinancialAggregationService`:

$$\text{Asset Account Balance} = \text{Opening Balance} + \text{Income} - \text{Expense} - \text{Transfers Out} + \text{Transfers In}$$

$$\text{Credit Card (Liability) Balance} = \text{Opening Balance} + \text{Expense} - \text{Income} - \text{Transfers In} + \text{Transfers Out}$$

$$\text{Total Net Balance} = \sum \text{Asset Balances} - \sum \text{Credit Card / Liability Balances}$$

### Credit Card Accounting Rules
- Credit card expenses increase credit card debt (liability).
- A transfer from `Bank Account → Credit Card`:
  - Decreases Bank asset balance.
  - Decreases Credit Card debt.
  - Does **NOT** create an expense or income.
  - Does **NOT** alter Net Cash Flow.

---

## 6. TRANSACTION & CATEGORY CONSTRAINTS

### Transaction Constraints
- **Income**: Requires `accountId`, `categoryId` (must belong to an Income category).
- **Expense**: Requires `accountId`, `categoryId` (must belong to an Expense category).
- **Transfer**: Requires `fromAccountId`, `toAccountId` (`fromAccountId != toAccountId`). `categoryId` **MUST be null**.
- **Amount**: Must be strictly positive ($> 0$).

### Category Constraints
- Categories are divided into `CategoryType.income` and `CategoryType.expense`.
- System defaults are generated via `Category.generateDefaults(userId)` if Firestore is empty.
- Archived categories cannot be selected for new transactions, but historical transactions retain their references.

---

## 7. PLANNED EXPENSES & PROGRESSIVE FORECASTING

- **Recurring Planned Expenses**: Configured with `defaultAmount`, `frequency`, `startDate`, `endDate`, and `categoryId`.
- **Monthly Overrides**: Recorded in `users/{userId}/planned_expense_overrides/{overrideId}` for a specific `(year, month)`. Overrides modify only the targeted month and leave default recurring amounts intact for future months.
- **CRITICAL INVARIANT**: Planned expenses **NEVER** automatically create `Transaction` documents.
- **Progressive Information Philosophy**:
  - Forecasts run with whatever data is provided.
  - Never fabricate missing fields. If a user hasn't entered an interest rate or tenure, calculate what is possible and present actionable guidance (e.g., *"Adding your interest rate will unlock amortization breakdown"*).

---

## 8. LOAN ARCHITECTURE & WHAT-IF ENGINE

`LoanForecastService` provides deterministic loan amortization and scenario simulation:
- **Calculations**: Monthly EMI, interest component, principal component, remaining tenure, estimated closure date, total interest payable.
- **What-If Scenarios**:
  1. `extraMonthly`: Simulates additional recurring monthly prepayment.
  2. `annualPrepayment`: Simulates yearly lump sum payment.
  3. `lumpSum`: Simulates immediate one-off principal reduction.
  4. `increasedEmi`: Simulates higher monthly commitment.
  5. `interestRateChange`: Simulates market rate increases/decreases.
- **Presentation Rule**: All scenario outputs are explicitly labeled as *Estimated / Illustrative Forecasts*.

---

## 9. FINANCIAL SERVICES RESPONSIBILITY MATRIX

| Service Name | Source Location | Responsibility |
| :--- | :--- | :--- |
| `FinancialAggregationService` | `lib/features/transactions/domain/services/` | Computes income/expense totals, net cash flow, category breakdowns, period aggregations, dynamic account balances, and planned vs. actual differences. |
| `FinancialInsightsService` | `lib/features/analytics/domain/services/` | Evaluates rule-based in-app financial insights ("Things to Review") such as top spending category, cash flow alerts, and budget variance. |
| `FinancialReviewService` | `lib/features/review/domain/services/` | Compiles comprehensive monthly review packages comparing actual transactions, forecast obligations, loan commitments, and goal savings. |
| `LoanForecastService` | `lib/features/loans/domain/services/` | Computes standard amortization schedules, closure forecasts, and What-If prepayment simulations. |

> **Rule**: Never create duplicate financial calculation services. Reuse or extend these core services.

---

## 10. RIVERPOD STATE & PROVIDER ARCHITECTURE

- **Firestore Stream Providers**: Auto-scoped to `currentUserProvider.uid` (`accountsStreamProvider`, `transactionsStreamProvider`, `categoriesStreamProvider`, etc.).
- **Pure Derived Aggregations**: Memoized providers (`calculatedAccountBalancesProvider`, `calculatedTotalBalanceProvider`, `monthlyFinancialSummaryProvider`, `periodSummaryProvider`). They only recompute when underlying collections change.
- **Form & Controller State**: Managed via `StateNotifierProvider` (e.g., `transactionControllerProvider`, `accountControllerProvider`). Dialogs and text inputs use local controllers to prevent parent page rebuilds.

---

## 11. FIRESTORE DATA MODEL & SECURITY

### User-Scoped Collection Hierarchy
```text
users/{userId}
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
`firestore.rules` enforces owner-only access:
```javascript
match /users/{userId}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```
*Never weaken Firestore security rules or allow cross-user access.*

---

## 12. DECLARATIVE ROUTING TABLE (`app_router.dart`)

| Path | Route Name | Screen Component | Guard / Behavior |
| :--- | :--- | :--- | :--- |
| `/login` | `login` | `LoginScreen` | Redirects to `/dashboard` if authenticated |
| `/register` | `register` | `RegisterScreen` | Redirects to `/dashboard` if authenticated |
| `/dashboard` | `dashboard` | `AppShell` (Hosts top-level tabs) | Requires authenticated user |
| `/monthly-review`| `monthly-review` | `MonthlyReviewScreen` | Requires authenticated user |
| `/planned-expenses`| `planned-expenses`| `PlannedExpensesScreen` | Requires authenticated user |
| `/loans` | `loans` | `LoansScreen` | Requires authenticated user |
| `/goals` | `goals` | `GoalsScreen` | Requires authenticated user |
| `/categories` | `categories` | `CategoriesScreen` | Requires authenticated user |
| `/account-types` | `account-types` | `AccountTypesScreen` | Requires authenticated user |
| `/profile` | `profile` | `ProfileScreen` | Requires authenticated user |
| `/terms` | `terms` | `TermsOfServiceScreen` | Publicly accessible |
| `/privacy` | `privacy` | `PrivacyNoticeScreen` | Publicly accessible |
| `/disclaimer` | `disclaimer` | `FinancialDisclaimerScreen` | Publicly accessible |

---

## 13. RESPONSIVE UI & VIEWPORT ARCHITECTURE

- **Adaptive Shell (`AppShell`)**:
  - $\ge 720\text{px}$: `NavigationRail` on the left.
  - $< 720\text{px}$: `NavigationBar` on the bottom.
- **Centered Layout (`ResponsiveCenter`)**: Constrains content width (max `1000px` to `1100px`) and ensures `width: double.infinity` to prevent shrink-wrapping.
- **Header Pattern (`PageHeader`)**: Uses `LayoutBuilder` (breakpoint `600px`) to display title/subtitle and action side-by-side on wide screens and stacked on narrow screens.
- **Verified Viewport Range**: Tested across `320px`, `375px`, `430px`, `768px`, `1024px`, and `1440px`.

---

## 14. PERFORMANCE GUARDRAILS & LESSONS LEARNED

1. **Firestore Client Persistence**: Always preserve `Settings(persistenceEnabled: true)` in `main.dart` so streams resolve from local IndexedDB cache without waiting for remote network handshakes.
2. **Deterministic Save Operations**: Save and update methods must validate fields locally without executing redundant remote queries (`getAccounts()` or `getCategories()`).
3. **Instant Dropdown & Chip Fallbacks**: Always provide immediate in-memory fallbacks (`AccountTypeDefinition.defaultTypes`, `Category.generateDefaults`) in dialogs so choice chips and dropdowns render with 0ms delay.
4. **AppShell Tab Isolation**: Inactive tabs are lazily mounted and wrapped in `TickerMode(enabled: isSelected)` and `Offstage(offstage: !isSelected)` to pause inactive charts and rebuild passes.
5. **No Keystroke Rebuild Cascades**: Text inputs must use local `TextEditingController` state and never trigger global aggregations on every keystroke.
6. **No Title Truncation / Vertical Text Collapse**: Never place flexible title text inside unconstrained horizontal flex widgets. Always use `PageHeader`.

---

## 15. DEVELOPER & FUTURE AGENT WORKFLOW

Follow this exact workflow for all future coding tasks:

```text
STEP 1: Read AGENTS.md (Master Rules & Workflow).
STEP 2: Read docs/project-dna/PROJECT_DNA.md (Architecture & Domain invariants).
STEP 3: Read only the relevant feature models, providers, and screens.
STEP 4: Implement the smallest safe, targeted change.
STEP 5: Do NOT run full test suites or web release builds after every minor edit.
STEP 6: Run full verification ONCE at milestone completion:
        1. dart format .
        2. dart analyze
        3. flutter test
        4. flutter build web --release
STEP 7: Leave all changes uncommitted in the working tree for user review.
```

