import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';
import 'package:personal_financial_assistant/features/goals/presentation/providers/goal_providers.dart';
import 'package:personal_financial_assistant/features/goals/presentation/screens/goals_screen.dart';

class _FakeUser implements User {
  @override
  final String uid = 'test_user_goals';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('GoalsScreen renders empty state when goals list is empty', (
    WidgetTester tester,
  ) async {
    final fakeUser = _FakeUser();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(fakeUser),
          goalsStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(home: GoalsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Financial Goals'), findsOneWidget);
    expect(find.text('No Goals Created Yet'), findsOneWidget);
    expect(find.text('Create Goal'), findsOneWidget);
  });

  testWidgets('GoalsScreen renders active goal cards and progress indicators', (
    WidgetTester tester,
  ) async {
    final fakeUser = _FakeUser();
    final now = DateTime.now();
    final sampleGoal = Goal(
      id: 'g1',
      userId: 'test_user_goals',
      name: 'Emergency Fund 2026',
      type: GoalType.emergencyFund,
      targetAmount: 100000.0,
      currentAmount: 50000.0,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(fakeUser),
          goalsStreamProvider.overrideWith((ref) => Stream.value([sampleGoal])),
        ],
        child: const MaterialApp(home: GoalsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Emergency Fund 2026'), findsOneWidget);
    expect(find.text('Emergency Reserve'), findsOneWidget);
    expect(find.text('50% Completed'), findsOneWidget);
  });
}
