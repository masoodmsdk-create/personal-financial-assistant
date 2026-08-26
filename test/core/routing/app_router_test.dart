import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/core/routing/app_router.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/loans/presentation/providers/loan_providers.dart';
import 'package:personal_financial_assistant/features/planned_expenses/presentation/providers/planned_expense_providers.dart';
import 'package:personal_financial_assistant/features/transactions/presentation/providers/transaction_providers.dart';
import 'package:personal_financial_assistant/features/workspaces/presentation/providers/workspace_providers.dart';
import 'package:personal_financial_assistant/features/workspaces/workspace.dart';

class _FakeUser extends Fake implements User {
  @override
  String get uid => 'u1';
  @override
  String? get email => 'test@finaura.com';
  @override
  String? get displayName => 'Test User';
}

void main() {
  final fakeUser = _FakeUser();
  final mockWorkspace = Workspace.createDefault('u1');

  testWidgets(
    'Direct route navigation resolves successfully for all key app destinations',
    (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(fakeUser),
          ),
          currentUserProvider.overrideWith((ref) => fakeUser),
          workspacesStreamProvider.overrideWith(
            (ref) => Stream.value([mockWorkspace]),
          ),
          activeWorkspaceProvider.overrideWithValue(mockWorkspace),
          accountsStreamProvider.overrideWith((ref) => Stream.value([])),
          transactionsStreamProvider.overrideWith((ref) => Stream.value([])),
          loansStreamProvider.overrideWith((ref) => Stream.value([])),
          goalsStreamProvider.overrideWith((ref) => Stream.value([])),
          plannedExpensesStreamProvider.overrideWith((ref) => Stream.value([])),
          categoriesStreamProvider.overrideWith((ref) => Stream.value([])),
          incomeCategoriesProvider.overrideWith(
            (ref) => const AsyncValue.data(<Category>[]),
          ),
          expenseCategoriesProvider.overrideWith(
            (ref) => const AsyncValue.data(<Category>[]),
          ),
          accountTypesStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      final routesToVerify = [
        '/dashboard',
        '/accounts',
        '/transactions',
        '/analytics',
        '/settings',
        '/loans',
        '/goals',
        '/trade-off',
        '/categories',
        '/account-types',
        '/smart-entry',
        '/planned-expenses',
        '/monthly-review',
      ];

      for (final route in routesToVerify) {
        router.go(route);
        expect(router.routeInformationProvider.value.uri.path, route);
      }

      await tester.pump(Duration.zero);
      await tester.pumpAndSettle();
    },
  );
}
