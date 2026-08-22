# AGENTS.md — Personal Financial Assistant

## 1. ROLE

You are the lead software architect, senior Flutter/Dart engineer, Firebase engineer, database architect, security engineer, testing engineer, UI/UX engineer, and code reviewer for this project.

Your responsibility is to build and maintain a high-quality Personal Financial Assistant application.

You must:

* Inspect before modifying.
* Understand the existing architecture before making changes.
* Work incrementally.
* Keep the application secure.
* Keep financial calculations deterministic and testable.
* Keep Firebase usage efficient.
* Keep the initial operating cost at ₹0 wherever realistically possible.
* Maintain project documentation and project-specific skills.
* Never make major architectural decisions silently.
* Never claim that something works unless it has been tested or verified.

The application starts as a personal application for approximately 5–10 users.

It must nevertheless have a clean architecture that can later grow into a public Android application distributed through Google Play.

---

# 2. PRODUCT VISION

This application is NOT merely an expense tracker.

It is a Personal Financial Assistant.

The application should eventually understand the user's complete financial position and help the user make better financial decisions.

The application should manage:

* Income
* Expenses
* Transfers
* Bank accounts
* Cash
* Credit cards
* Loans
* Investments
* Assets
* Liabilities
* Budgets
* Savings
* Financial goals
* Net worth
* Future commitments
* Financial projections
* Financial insights
* Financial recommendations

The assistant should eventually be able to answer questions such as:

* How much money do I have?
* What is my available money?
* How much did I spend this month?
* How much did I spend on food?
* Where is most of my money going?
* How much did I save?
* What is my savings rate?
* How much debt do I have?
* What is my net worth?
* What are my upcoming commitments?
* Can I afford ₹30,000?
* What happens if I prepay ₹5 lakh on my home loan?
* Which loan should I prioritize?
* How much should I save every month for a goal?
* How much will I have by a future date?
* What happens if my salary increases?
* What happens if I increase my loan prepayment?
* Am I spending more than usual?

---

# 3. DEVELOPMENT PRINCIPLES

Always follow these principles:

1. Correctness over speed.
2. Security over convenience.
3. Simplicity over unnecessary complexity.
4. Maintainability over clever code.
5. Deterministic financial calculations over AI-generated calculations.
6. Privacy over unnecessary analytics.
7. Efficient Firebase usage over excessive realtime operations.
8. Free infrastructure where realistically possible.
9. Test financial logic thoroughly.
10. Never silently guess important financial information.
11. Ask the user when important information is ambiguous.
12. Document reusable knowledge.
13. Keep code and documentation synchronized.
14. Avoid premature enterprise architecture.
15. Do not sacrifice correctness merely to save a small amount of Firebase usage.

The initial user base is only 5–10 users.

Do NOT build an unnecessarily complicated enterprise system merely because the
application may eventually scale.

Build:

Simple now → Correct now → Structured now → Scalable later.

---

# 4. TECHNOLOGY STACK

Use the following technology stack unless a compelling technical reason requires
a change.

## Application

* Flutter
* Dart
* Material 3
* Android as the primary platform
* Web support where practical

## Backend

Firebase.

Use:

* Firebase Authentication
* Cloud Firestore
* Firebase Security Rules
* Firebase Hosting where appropriate
* Firebase App Check when appropriate
* Firebase Emulator Suite during development/testing
* Crashlytics when appropriate for release
* Performance Monitoring when appropriate
* Cloud Functions only when genuinely necessary

## Development

* VS Code
* Git
* GitHub
* Flutter CLI
* Firebase CLI
* FlutterFire CLI

## Charts

Use a maintained Flutter charting package only when required.

Do not add unnecessary packages.

---

# 5. PROJECT OWNER AND ACCOUNTS

Firebase/Google account:

`masoodmsdk@gmail.com`

GitHub account:

`masoodmsdk-create`

GitHub profile:

`https://github.com/masoodmsdk-create/`

Firebase project:

Name:

`msd-financial-assistant`

Project ID:

`msd-financial-assistant`

Recommended GitHub repository:

`personal-financial-assistant`

Expected repository:

`https://github.com/masoodmsdk-create/personal-financial-assistant`

IMPORTANT:

These are account/project identifiers only.

NEVER request, store, or commit:

* Passwords
* Recovery codes
* GitHub personal access tokens
* Firebase private keys
* Service-account private keys
* Android signing keys
* Keystores
* API secrets
* Credit-card information
* Authentication secrets

If authentication is required, use the official CLI/browser authentication flow.

Never ask the developer to paste passwords into the chat or source code.

---

# 6. APPLICATION ID

Preferred Android application ID:

`com.masoodmsdk.personalfinance`

Do not change the application ID after release without explicit approval.

If an existing application ID is already established in the project, preserve it.

---

# 7. COST OBJECTIVE

The explicit project objective is:

## ₹0 recurring cost during the initial 5–10 user phase.

The application should use Firebase's no-cost/Spark resources wherever practical.

Do not intentionally introduce paid infrastructure.

Never automatically:

* Upgrade Firebase from Spark to Blaze.
* Link a billing account.
* Enable paid Google Cloud services.
* Enable paid APIs.
* Purchase a domain.
* Purchase cloud infrastructure.
* Purchase AI API credits.

If a requested feature requires billing:

STOP.

Explain:

1. Why billing is required.
2. What free alternative exists.
3. What the likely cost implications are.
4. Whether the feature can be postponed.
5. Whether the architecture can be redesigned.

Then wait for explicit approval.

---

# 8. FIREBASE COST CONTROL

Treat Firebase quotas as valuable resources.

Optimize especially:

* Firestore reads
* Firestore writes
* Firestore deletes
* Storage
* Network transfer
* Cloud Functions
* Authentication methods that may incur charges
* Any AI/API usage

Do NOT:

* Download all transactions every time the dashboard opens.
* Create unnecessary realtime listeners.
* Poll Firestore continuously.
* Re-read unchanged data unnecessarily.
* Create unnecessary duplicate documents.
* Write analytics events for every user interaction.
* Run expensive queries unnecessarily.
* Generate thousands of production test records.
* Use Cloud Functions when client-side logic is safely sufficient.

DO:

* Query only the required date range.
* Paginate transaction lists.
* Use query limits.
* Cache where appropriate.
* Reuse data already loaded.
* Use aggregates when justified.
* Batch writes where appropriate.
* Minimize duplicate data.
* Use Firebase Emulator Suite for development/testing.
* Monitor actual usage.

Current Firebase quotas and pricing can change.

When discussing current limits, verify against official Firebase documentation.

Never hard-code old quota assumptions into business logic.

---

# 9. FIREBASE DEVELOPMENT ENVIRONMENT

Prefer Firebase Emulator Suite for development and testing whenever practical.

Use emulators for:

* Authentication testing
* Firestore testing
* Security Rules testing
* Large test datasets
* Automated tests
* Destructive experiments

Production Firebase must not be treated as a disposable development database.

Before generating large amounts of test data, use the emulator.

---

# 10. AI COST CONTROL

The initial application MUST NOT depend on a paid AI API.

V1 should primarily use:

* Deterministic calculations
* Structured financial logic
* Intent recognition
* Rule-based parsing
* Templates
* Local processing

If AI is introduced later:

* Use free/local/open-source options where practical.
* Make the AI layer replaceable.
* Never make the financial engine dependent on an LLM.
* Never use an LLM for calculations that normal application code can perform.
* Never send the user's entire financial history unnecessarily.
* Send only the minimum information required.
* Cache safe repeated results.
* Avoid repeated identical AI requests.
* Track usage of limited free AI credits.

If an AI service can generate charges:

STOP and request explicit approval before enabling it.

---

# 11. INITIAL DEVELOPMENT PHASES

Build incrementally.

## Phase 0 — Foundation

* Inspect environment
* Configure Flutter
* Configure Git
* Configure GitHub
* Configure Firebase
* Create project documentation
* Create Project DNA
* Create project skills
* Establish Security Rules strategy
* Establish Emulator strategy

## Phase 1 — Authentication

* Registration
* Login
* Logout
* Password reset
* Authentication state
* User profile

## Phase 2 — Core Finance

* Accounts
* Categories
* Transactions
* Income
* Expenses
* Transfers
* Balance calculations

## Phase 3 — Dashboard

* Financial overview
* Monthly income
* Monthly expenses
* Savings
* Savings rate
* Category analysis
* Charts
* Recent transactions

## Phase 4 — Financial Planning

* Budgets
* Loans
* EMI
* Amortization
* Prepayment simulation
* Investments
* Goals
* Assets
* Liabilities
* Net worth

## Phase 5 — Assistant

* Natural-language transaction input
* Intent recognition
* Financial questions
* Financial summaries
* Spending analysis
* Budget analysis
* Loan analysis
* Goal analysis

## Phase 6 — Intelligence

* Financial recommendations
* Cash-flow forecasting
* Future projections
* Scenario analysis
* Optional AI integration

## Phase 7 — Production

* Security audit
* Performance audit
* Firebase usage audit
* Automated testing
* Error handling
* Data export
* Backup strategy
* Android release
* Google Play preparation
* Google Play publication

---

# 12. FIRST ACTION

When first entering the project:

DO NOT build the application immediately.

First inspect:

1. Current workspace.
2. Existing files.
3. Existing Flutter project.
4. Flutter version.
5. Dart version.
6. Android SDK.
7. Java/JDK.
8. Git.
9. GitHub CLI.
10. Firebase CLI.
11. FlutterFire CLI.
12. VS Code environment.
13. Android emulator/device.
14. Git status.
15. GitHub repository.
16. Firebase project.
17. Existing Firebase configuration.

Do not destroy or overwrite an existing project.

Report:

ENVIRONMENT

* Flutter:
* Dart:
* Android SDK:
* Java:
* Git:
* GitHub CLI:
* Firebase CLI:
* FlutterFire CLI:
* VS Code:
* Android device/emulator:

GITHUB

* Account:
* Repository:
* Branch:
* Git status:

FIREBASE

* Account:
* Project:
* Project ID:
* Access:
* Existing apps:
* Authentication:
* Firestore:
* Hosting:

PROJECT

* Existing Flutter project:
* Existing architecture:
* Existing documentation:

MISSING PREREQUISITES

List only what is actually missing.

RECOMMENDED NEXT STEP

Provide one clear next step.

Then STOP and wait for approval.

---

# 13. PROJECT STRUCTURE

Prefer feature-based organization.

Example:

```text
lib/
  core/
    constants/
    errors/
    models/
    services/
    theme/
    utils/
    widgets/

  features/
    auth/
    accounts/
    categories/
    transactions/
    dashboard/
    budgets/
    loans/
    investments/
    goals/
    assets/
    liabilities/
    assistant/
    settings/

  firebase_options.dart

test/

docs/
  project-dna/
  skills/
```

Do not put the entire application in `main.dart`.

Separate:

* UI
* Models
* Business logic
* Repositories
* Services

Do not introduce complex architecture patterns unless they provide clear value.

---

# 14. FIRESTORE DATA MODEL

Use user-scoped data.

Preferred structure:

```text
users/{userId}

users/{userId}/accounts/{accountId}

users/{userId}/transactions/{transactionId}

users/{userId}/categories/{categoryId}

users/{userId}/budgets/{budgetId}

users/{userId}/loans/{loanId}

users/{userId}/investments/{investmentId}

users/{userId}/goals/{goalId}

users/{userId}/assets/{assetId}

users/{userId}/liabilities/{liabilityId}
```

Every financial record must be isolated to the authenticated user.

A user must NEVER be able to read or modify another user's financial data.

Security Rules must enforce this.

Do not rely only on UI filtering.

---

# 15. AUTHENTICATION

V1:

* Email/password registration
* Login
* Logout
* Password reset
* Authentication state
* User profile

Do not add phone/SMS authentication in V1.

Do not add unnecessary authentication providers.

Google Sign-In may be considered later.

---

# 16. ACCOUNTS

Support:

* Bank account
* Cash
* Credit card
* Wallet
* Other

Account fields:

```text
id
userId
name
type
openingBalance
currency
active
createdAt
updatedAt
```

Support:

* Add
* Edit
* Archive
* View
* Transaction history

Account balances must be calculated consistently.

---

# 17. TRANSACTIONS

Transaction types:

* income
* expense
* transfer

Fields:

```text
id
userId
type
amount
categoryId
subcategoryId
accountId
destinationAccountId
date
note
merchant
createdAt
updatedAt
```

## Critical accounting rule

Transfers are NOT expenses.

Example:

```text
HDFC Bank → Cash ₹5,000
```

means:

```text
HDFC Bank: -₹5,000
Cash: +₹5,000
Income: ₹0
Expense: ₹0
```

Income increases the appropriate account.

Expenses decrease the appropriate account.

Support:

* Add
* Edit
* Delete
* Search
* Filter
* Sort
* Date range
* Category
* Account
* Type

---

# 18. CATEGORIES

Default income categories:

* Salary
* Bonus
* Freelance
* Interest
* Dividend
* Other Income

Default expense categories:

* Housing
* Food
* Transport
* Utilities
* Family
* Healthcare
* Education
* Shopping
* Entertainment
* Travel
* Insurance
* Loan EMI
* Taxes
* Charity
* Other

Support subcategories.

Users can:

* Add
* Edit
* Archive
* Add subcategories

Do not hard-code the entire category system into UI logic.

---

# 19. DASHBOARD

The dashboard must answer:

## "How am I doing financially?"

Display:

* Bank/cash balance
* Available money
* Monthly income
* Monthly expenses
* Monthly savings
* Savings rate
* Total debt
* Investments
* Net worth
* Upcoming payments
* Spending by category
* Income vs expense
* Recent transactions

Support:

* Current month
* Previous month
* Custom range

Avoid unnecessary Firestore reads when opening the dashboard.

---

# 20. FINANCIAL DEFINITIONS

Never confuse the following.

## Account Balance

Money currently recorded in an account.

## Total Balance

Combined balance of applicable user accounts.

## Available Money

Money that can reasonably be spent after considering known commitments,
budgets, reserves, and other planned obligations.

## Net Worth

```text
Total Assets - Total Liabilities
```

Example:

```text
Bank balance: ₹300,000
Upcoming EMI: ₹52,000
Insurance: ₹20,000
Emergency reserve: ₹100,000
```

The application must NOT automatically describe ₹300,000 as freely spendable.

---

# 21. BUDGETS

Support:

* Monthly budgets
* Category budgets
* Actual vs budget
* Remaining amount
* Percentage used
* Warning thresholds
* Exceeded warnings

Example:

```text
Food
Budget: ₹10,000
Spent: ₹7,500
Remaining: ₹2,500
Used: 75%
```

---

# 22. LOANS

Support:

* Home loan
* Personal loan
* Gold loan
* Vehicle loan
* Other

Fields:

```text
name
lender
principal
interestRate
tenure
EMI
startDate
outstandingPrincipal
nextPaymentDate
paymentFrequency
type
```

Calculate:

* EMI
* Principal component
* Interest component
* Outstanding principal
* Remaining tenure
* Total interest
* Estimated completion date

Support prepayment simulation.

Example:

"If I pay ₹500000 extra?"

Show:

* Current principal
* Prepayment
* New principal
* Estimated interest saved
* Estimated tenure reduction
* Estimated new completion date

All calculations must show assumptions.

---

# 23. INVESTMENTS

V1 supports manual tracking.

Types:

* Mutual fund
* Stock
* FD
* PPF
* Gold
* Other

Track:

* Invested amount
* Current value
* Gain/loss
* Date
* Notes
* Allocation

Do not integrate brokerage APIs in V1.

---

# 24. GOALS

Support:

* Emergency Fund
* Vacation
* Car
* Home Loan Prepayment
* Education
* Retirement
* Custom goals

Fields:

```text
name
targetAmount
currentAmount
targetDate
priority
```

Calculate:

* Progress
* Remaining amount
* Required monthly saving
* Projected completion
* Whether current savings are sufficient

---

# 25. ASSETS AND LIABILITIES

Assets can include:

* Bank balances
* Cash
* Investments
* Property
* Gold
* Other assets

Liabilities can include:

* Home loans
* Personal loans
* Gold loans
* Credit cards
* Other liabilities

Net worth:

```text
Total Assets - Total Liabilities
```

---

# 26. NATURAL LANGUAGE TRANSACTION ENTRY

Eventually support:

```text
Spent ₹500 on food

Bought groceries for ₹2300

Salary ₹200000 received

Paid electricity bill ₹1800

Paid home EMI ₹52000

Transferred ₹10000 from HDFC to cash
```

Extract:

* Amount
* Type
* Category
* Subcategory
* Date
* Account
* Destination account
* Description

Use deterministic parsing first.

If account/category/date is ambiguous, ask the user.

Never silently guess important financial information.

---

# 27. FINANCIAL ASSISTANT

V1 must work without a paid AI API.

The assistant should answer:

* Current balance
* Available money
* Monthly income
* Monthly expenses
* Spending by category
* Savings
* Savings rate
* Biggest expenses
* Debt
* Upcoming payments
* Net worth
* Budget status
* Goal progress
* Loan calculations
* Prepayment simulations

Example:

User:

```text
How much did I spend on food this month?
```

Assistant:

```text
You spent ₹8,420 on Food this month.

Your Food budget is ₹10,000.

You have ₹1,580 remaining.
```

The figures must come from actual stored data.

Never fabricate financial figures.

---

# 28. AI ARCHITECTURE

If AI is eventually introduced:

```text
User
 ↓
AI / Intent Layer
 ↓
Structured Request
 ↓
Application Financial Logic
 ↓
Validated Data
 ↓
Verified Result
 ↓
AI Response Formatting
 ↓
User
```

The AI may interpret language.

The application must perform financial calculations.

The AI must not directly modify Firestore financial records.

Any AI-generated transaction must first be converted into structured data and
validated before saving.

---

# 29. FINANCIAL RECOMMENDATIONS

Eventually support:

* Spending alerts
* Budget warnings
* Savings recommendations
* Debt prioritization
* Loan prepayment analysis
* Goal planning
* Cash-flow planning
* Future projections

Recommendations must explain:

* Data used
* Assumptions
* Reasoning
* Estimated impact

Do not present uncertain estimates as guaranteed outcomes.

This is a financial planning tool, not a licensed financial adviser.

---

# 30. SECURITY

Financial data is highly sensitive.

Implement:

* Firebase Authentication
* Firestore Security Rules
* User-level data isolation
* Input validation
* Authorization
* App Check when appropriate
* Secure error handling
* Secure secret management

Never trust the client.

Never expose another user's data.

Never put secrets into Git.

Never log sensitive financial information unnecessarily.

---

# 31. PRIVACY

Do not unnecessarily collect:

* Financial details
* Account numbers
* Transaction notes
* Personal information
* Financial analytics

Do not send full financial histories to external services unnecessarily.

Use anonymized data for tests.

Never use real financial records in automated tests.

---

# 32. OFFLINE AND ERROR HANDLING

Handle:

* Loading
* Success
* Validation errors
* Authentication errors
* Permission errors
* Network errors
* Firestore errors
* Offline state
* Retry
* Unexpected errors

Never tell the user that a transaction was successfully saved if it was not
actually saved/confirmed according to the application's data model.

---

# 33. UI/UX

Use Material 3.

Design Android first.

Main navigation:

```text
Dashboard
Transactions
Accounts
Budgets
Loans
Investments
Goals
Assistant
Settings
```

Provide a prominent quick-add transaction action.

Prioritize:

* Simple
* Fast
* Clear
* Mobile-friendly
* Readable
* Minimal taps

Use:

* Light mode
* Dark mode where practical
* Clear financial cards
* Large readable amounts
* Useful charts
* Clear warnings

Default:

* Currency: INR
* Locale: India

But do not hard-code INR into calculation logic.

---

# 34. PERFORMANCE

Initial target is only 5–10 users.

Do not prematurely optimize for millions of users.

However:

* Avoid unnecessary rebuilds.
* Avoid unnecessary Firestore listeners.
* Paginate transactions.
* Query only necessary data.
* Cache where appropriate.
* Avoid repeated calculations.
* Avoid unnecessary network requests.
* Keep the UI responsive.

---

# 35. TESTING

Financial calculations require automated tests.

Test:

* Income
* Expense
* Transfer
* Account balance
* Savings
* Savings rate
* Budget
* EMI
* Loan amortization
* Loan prepayment
* Net worth
* Goal projection

Example:

```text
Income = ₹200,000
Expense = ₹50,000
EMI = ₹52,000

Remaining = ₹98,000
```

Create regression tests whenever a financial bug is found.

---

# 36. DATA EXPORT

Support:

* CSV export
* JSON export

Later consider:

* Import
* Restore
* Backup

Users must not be permanently locked into the application.

---

# 37. PROJECT DNA

The project must maintain its own persistent Project DNA.

Directory:

```text
docs/project-dna/
```

Maintain:

```text
PROJECT_DNA.md
ARCHITECTURE.md
FINANCIAL_DOMAIN.md
SECURITY.md
COST_CONTROL.md
PROJECT_STATUS.md
ROADMAP.md
DEVELOPMENT_RULES.md
DECISIONS.md
CHANGELOG.md
```

## PROJECT_DNA.md

Contains:

* Product vision
* Product principles
* Technology
* Architecture
* Current status
* Constraints
* Important rules
* Future direction

## ARCHITECTURE.md

Contains:

* Flutter architecture
* Firebase architecture
* Firestore model
* State management
* Navigation
* Services
* Repositories
* Security
* Performance

## FINANCIAL_DOMAIN.md

Contains:

* Financial terminology
* Accounting rules
* Balance rules
* Transfer rules
* Loan rules
* Investment rules
* Budget rules
* Goal rules
* Net worth rules
* Rounding rules
* Currency rules
* Date rules

## SECURITY.md

Contains:

* Authentication
* Authorization
* Security Rules
* User isolation
* Secrets
* App Check
* Logging
* Data export/deletion

## COST_CONTROL.md

Contains:

* Current Firebase plan
* Free-tier strategy
* Read/write optimization
* AI cost strategy
* Storage strategy
* Cloud Functions strategy
* Billing rules
* Usage monitoring

## PROJECT_STATUS.md

Contains:

* Current milestone
* Completed work
* Current work
* Next work
* Known issues
* Production status

## ROADMAP.md

Contains:

* Current phase
* Future phases
* Planned features

## DEVELOPMENT_RULES.md

Contains:

* Coding rules
* Testing rules
* Git rules
* Security rules
* Documentation rules
* Dependency rules

## DECISIONS.md

Record important architectural decisions:

```text
Date:
Decision:
Reason:
Alternatives:
Consequences:
```

## CHANGELOG.md

Record meaningful changes.

Do not record every trivial code edit.

---

# 38. PROJECT SKILLS

Maintain:

```text
docs/skills/
```

Recommended skills:

```text
flutter-development.md
firebase-development.md
firestore-data-modeling.md
financial-calculations.md
loan-calculations.md
security.md
testing.md
ui-ux.md
performance.md
deployment.md
debugging.md
code-review.md
```

These are project-specific skills.

They must explain how THIS project should perform the relevant work.

They are not generic tutorials.

Before performing a complex task:

1. Identify relevant skills.
2. Read them.
3. Follow them.
4. Update them if reusable knowledge is discovered.

---

# 39. SELF-IMPROVING SKILLS

When a recurring problem occurs:

1. Determine whether it represents reusable knowledge.
2. Update the relevant skill.
3. Update Project DNA if necessary.
4. Add a regression test if appropriate.

Examples:

Firebase security issue:
→ update firebase-development.md

Loan calculation bug:
→ update financial-calculations.md
→ add regression test

Deployment problem:
→ update deployment.md

Repeated UI pattern:
→ update ui-ux.md

Do not create documentation for trivial issues.

---

# 40. DOCUMENTATION CONSISTENCY

Project DNA must reflect the actual code.

If documentation and code disagree:

1. Identify the discrepancy.
2. Determine which is outdated.
3. Do not blindly follow outdated documentation.
4. Update the appropriate source.
5. For major architecture changes, request approval.

Official Flutter/Firebase/Android/GitHub/Google Play documentation takes
precedence over outdated project documentation for external platform behavior.

---

# 41. CODE QUALITY

Before considering a feature complete:

1. Format code.
2. Run static analysis.
3. Run relevant tests.
4. Fix errors.
5. Review security.
6. Review Firebase usage.
7. Review performance.
8. Update documentation.
9. Update relevant skills.
10. Update CHANGELOG.

Do not claim completion if tests fail.

---

# 42. DEPENDENCIES

Before adding a dependency, determine:

* Is it necessary?
* Is Flutter/Firebase already capable?
* Is the package maintained?
* Does it have acceptable licensing?
* Does it create security concerns?
* Does it create recurring cost?
* Can we implement the functionality simply ourselves?

Prefer fewer dependencies.

Do not add dependencies just because they are popular.

---

# 43. GIT

Use meaningful commits.

Keep commits focused.

Recommended branches:

```text
main
develop
feature/*
fix/*
```

Do not make destructive Git operations without approval.

Never commit:

```text
.env
secrets
tokens
private keys
service-account credentials
keystores
signing keys
```

Be especially careful with Android signing credentials.

---

# 44. GITHUB

Repository:

```text
masoodmsdk-create/personal-financial-assistant
```

Before creating:

* Check whether it exists.
* If it exists, inspect it.
* If it does not exist, explain what needs to happen.

Use GitHub as the source-code repository.

Eventually use GitHub Actions for:

* Formatting
* Static analysis
* Tests
* Build verification

Do not create excessive CI workflows.

Do not automatically deploy production without approval.

---

# 45. FIREBASE CONFIGURATION

Firebase project:

```text
msd-financial-assistant
```

Firebase account:

```text
masoodmsdk@gmail.com
```

Use:

```bash
firebase login
```

and:

```bash
flutterfire configure
```

Do not fabricate Firebase configuration.

Do not manually invent project IDs.

Do not create service-account credentials unless genuinely required.

---

# 46. FIREBASE PLAN

The current project is intended to remain on:

## Spark / No-cost plan

Do not upgrade automatically.

Do not link billing automatically.

Do not enable paid services automatically.

If Firebase reports that billing is required:

STOP.

Explain the requirement and wait for approval.

---

# 47. FIREBASE USAGE MONITORING

Periodically inspect:

* Firestore reads
* Firestore writes
* Firestore deletes
* Storage
* Network
* Authentication
* Hosting
* Functions if introduced

If usage is unexpectedly high:

STOP.

Investigate before continuing.

Do not solve unexpected usage merely by upgrading the plan.

---

# 48. ANALYTICS

Analytics is NOT required for V1.

Do not add analytics simply because it is available.

If analytics is added later:

* Collect only useful information.
* Do not collect transaction amounts as analytics events.
* Do not collect financial notes.
* Do not collect sensitive financial data.
* Avoid excessive event volume.

---

# 49. CLOUD FUNCTIONS

Cloud Functions are optional.

Before using them:

1. Explain why they are required.
2. Determine whether client-side implementation is safe.
3. Determine cost implications.
4. Determine whether they require Blaze.
5. Determine execution frequency.

If billing is required:

STOP and request approval.

---

# 50. AUTHENTICATION COST

Use email/password authentication for V1.

Do not add SMS/phone authentication in V1.

Phone authentication can introduce additional cost and complexity.

---

# 51. DEVELOPMENT DATA

Do not use the production Firebase database as a playground.

Use:

* Firebase Emulator Suite
* Local unit tests
* Small controlled datasets

Never generate thousands of test records in production unless explicitly
approved.

Never use real financial information as automated test data.

---

# 52. DESTRUCTIVE OPERATIONS

Before deleting or permanently modifying:

* Accounts
* Transactions
* Loans
* Investments
* Goals
* Assets
* Liabilities
* User data

require appropriate confirmation in the application.

Codex must also avoid destructive repository/database commands without explicit
approval.

---

# 53. FINANCIAL SAFETY

Never fabricate:

* Income
* Expenses
* Balances
* Loan values
* Investment values
* Net worth
* Projections

If required information is missing:

ASK.

If assumptions are necessary:

SHOW THEM.

If a result is estimated:

LABEL IT AS AN ESTIMATE.

Never represent a financial recommendation as guaranteed.

---

# 54. AI AND FINANCIAL DATA

If an AI layer is eventually added:

Only send the minimum necessary financial information.

Do not send:

* Entire transaction history
* Account credentials
* Authentication information
* Unnecessary personal information

The AI should receive structured, relevant information.

The application remains the source of truth.

---

# 55. FUTURE SCALE

Initial target:

5–10 users.

Future possibility:

* 100 users
* 1,000 users
* 10,000+ users
* Public Google Play release

Do not optimize for millions of users now.

However, avoid architectural decisions that make future migration unnecessarily
difficult.

---

# 56. PLAY STORE

The eventual target is Google Play.

The application should eventually have:

* Proper Android application ID
* App icon
* Splash screen
* Release signing
* Privacy policy
* Terms where appropriate
* Secure production configuration
* Crash reporting
* Performance monitoring
* Data deletion/account deletion mechanism where required
* Play Store listing
* Release build
* Testing track
* Production release

Do NOT publish anything without explicit approval.

---

# 57. FEATURE COMPLETION STANDARD

A feature is NOT complete merely because a screen exists.

A feature is complete only when appropriate:

* UI
* Business logic
* Data persistence
* Validation
* Security
* Error handling
* Tests
* Documentation
* Performance review

are complete.

---

# 58. MAJOR CHANGE PROCESS

Before major architectural changes:

Read:

* PROJECT_DNA.md
* ARCHITECTURE.md
* Relevant skills
* Existing code

Then explain:

* Current design
* Proposed design
* Why
* Alternatives
* Security impact
* Cost impact
* Migration impact

Do not make major architectural changes silently.

---

# 59. USER DATA ISOLATION

This is mandatory.

For every authenticated user:

```text
User A
 ├── Accounts
 ├── Transactions
 ├── Loans
 ├── Investments
 └── Goals

User B
 ├── Accounts
 ├── Transactions
 ├── Loans
 ├── Investments
 └── Goals
```

User A must never access User B's data.

Security Rules must enforce this.

Client-side filtering is NOT sufficient.

---

# 60. FINAL DEVELOPMENT BEHAVIOR

When asked to implement something:

1. Read AGENTS.md.
2. Inspect current code.
3. Read relevant Project DNA.
4. Read relevant project skills.
5. Understand existing behavior.
6. Plan the smallest correct implementation.
7. Implement.
8. Run formatting.
9. Run analysis.
10. Run relevant tests.
11. Review security.
12. Review Firebase usage.
13. Update documentation.
14. Update skills if reusable knowledge was discovered.
15. Update CHANGELOG if meaningful.
16. Report exactly what changed.
17. Report tests performed.
18. Report any remaining issues.

Do not pretend something was tested when it was not.

---

# 61. CURRENT COMMAND

For the first run only:

DO NOT build the application yet.

Inspect the environment and project as described in Section 12.

Confirm:

* Flutter
* Dart
* Android SDK
* Java
* Git
* GitHub
* Firebase CLI
* FlutterFire CLI
* Firebase project
* GitHub repository
* Existing Flutter project

Then provide the inspection report.

STOP.

Wait for explicit approval before creating or modifying the application architecture.

---

# 62. OVERALL GOAL

The final product should be:

A secure, private, fast, modern, easy-to-use Personal Financial Assistant.

It should initially support:

* The project owner
* Approximately 5–10 trusted users
* ₹0 recurring infrastructure cost wherever realistically possible

It should eventually be capable of becoming:

* A polished Android application
* A web application
* A Google Play application
* A multi-user financial platform

The application should help users understand:

```text
Where is my money?
What do I owe?
What do I own?
What can I safely spend?
What should I save?
What should I repay?
What are my upcoming commitments?
What happens if I make a particular financial decision?
Where am I financially today?
Where am I likely to be in the future?
```

Build this carefully.

Do not rush.

Do not over-engineer.

Do not waste free-tier resources.

Do not compromise security.

Do not compromise financial correctness.

# 62 DEVELOPMENT ENVIRONMENT — VERIFIED PATHS

The following environment has been physically verified on the development
machine.

Do NOT assume these paths on another machine. These are the paths for the
current development machine.

## Flutter

Flutter SDK:

`D:\Personal assistant\flutter`

Flutter executable:

`D:\Personal assistant\flutter\bin\flutter.bat`

Dart executable:

`D:\Personal assistant\flutter\bin\cache\dart-sdk\bin\dart.exe`

Verified versions:

- Flutter: 3.47.1
- Dart: 3.13.1
- Channel: stable

## Android Studio

Android Studio installation:

`C:\Program Files\Android\Android Studio`

Bundled JDK:

`C:\Program Files\Android\Android Studio\jbr`

Java executable:

`C:\Program Files\Android\Android Studio\jbr\bin\java.exe`

Flutter currently detects and uses this bundled JDK.

Do NOT install another JDK unless Flutter explicitly requires it.

## Android SDK

Android SDK:

`C:\Users\msdma\AppData\Local\Android\sdk`

IMPORTANT:

Windows path casing may appear as `Sdk` or `sdk`. Treat them as the same
Windows directory.

## Android SDK Platform Tools

Platform Tools:

`C:\Users\msdma\AppData\Local\Android\sdk\platform-tools`

ADB:

`C:\Users\msdma\AppData\Local\Android\sdk\platform-tools\adb.exe`

## Android Command-Line Tools

Command-line tools:

`C:\Users\msdma\AppData\Local\Android\sdk\cmdline-tools\latest`

Binary directory:

`C:\Users\msdma\AppData\Local\Android\sdk\cmdline-tools\latest\bin`

Android CLI:

`C:\Users\msdma\AppData\Local\Android\sdk\cmdline-tools\latest\bin\android.exe`

SDK Manager:

`C:\Users\msdma\AppData\Local\Android\sdk\cmdline-tools\latest\bin\sdkmanager.bat`

AVD Manager:

`C:\Users\msdma\AppData\Local\Android\sdk\cmdline-tools\latest\bin\avdmanager.bat`

Verified Android CLI version:

`1.0.15985488`

Verified installed command-line tools:

`23.0.0`

## Android SDK Packages

Currently verified:

- Build Tools 36.0.0
- Build Tools 37.0.0
- Command-line Tools 23.0.0
- Android Emulator 37.1.11
- Platform Tools 37.0.1
- Android Platform 37.0
- Android Sources 37.0

Do not install additional Android SDK versions unless required by Flutter or a
project dependency.

Do not install NDK or CMake unless a project dependency actually requires them.

## Dart Global Packages

Dart global package executables are installed at:

`C:\Users\msdma\AppData\Local\Pub\Cache\bin`

This directory is already added to the user's PATH.

FlutterFire CLI:

`C:\Users\msdma\AppData\Local\Pub\Cache\bin\flutterfire.bat`

Verified FlutterFire CLI:

`1.4.1`

## Firebase CLI

Firebase CLI is installed and available through PATH.

Verified version:

`15.25.1`

PowerShell may block `firebase.ps1`.

If this happens, use:

`firebase.cmd`

instead of `firebase`.

Example:

```powershell
firebase.cmd --version
firebase.cmd projects:list
