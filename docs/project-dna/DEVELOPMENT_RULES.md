# Development Rules

## Golden Rule

Do not build complexity that we do not currently need.

The application starts with 5–10 users.

Build cleanly and securely, but do not prematurely optimize for millions of
users.

## Before Coding

Always:

1. Inspect existing code.
2. Read relevant Project DNA.
3. Read relevant project skills.
4. Understand existing architecture.
5. Check whether the requested functionality already exists.
6. Avoid duplicating functionality.

## Before Adding a Dependency

Ask:

- Is it actually necessary?
- Is Flutter/Firebase already capable of doing this?
- Is the package maintained?
- Does it introduce security risk?
- Does it introduce licensing concerns?
- Does it introduce recurring cost?
- Can we implement it simply ourselves?

Prefer fewer dependencies.

## Financial Logic

Financial calculations must be implemented in application code.

Do not rely on an AI model to perform financial calculations.

All important calculations must have tests.

## Firebase

Before adding Firestore reads/writes, consider:

- How often will this execute?
- How many documents will it read?
- Can the query be narrower?
- Can data be cached?
- Is a realtime listener actually necessary?

Optimize for low Firebase usage.

## Security

Never trust the client.

Firestore Security Rules must enforce authorization.

Never assume hiding a UI element provides security.

## User Experience

Every important action should provide:

- Loading state
- Success state
- Error state

Never leave the user wondering whether a transaction was saved.

## Destructive Actions

Before:

- deleting financial data
- changing account balances
- deleting accounts
- deleting loans
- deleting investments

provide appropriate confirmation.

## Git

Make small, logical commits.

Do not mix unrelated changes in one commit.

Never commit secrets.

## Documentation

When a major architectural or financial rule changes:

1. Update Project DNA.
2. Update the relevant skill.
3. Add/update tests.
4. Update CHANGELOG.

## Completion

A feature is not complete merely because the UI exists.

A feature is complete when:

- UI works
- Business logic works
- Data persists correctly
- Security is correct
- Error handling exists
- Tests pass
- Documentation is updated
