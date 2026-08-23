import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/auth/domain/repositories/auth_repository.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/profile/presentation/screens/profile_screen.dart';

class _FakeUser implements User {
  @override
  final String uid = 'test_uid_12345';
  @override
  final String? email = 'user@example.com';
  @override
  final String? displayName = 'Masood Test';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestAuthRepository implements AuthRepository {
  final User _user = _FakeUser();
  bool resetPasswordCalled = false;
  bool updateNameCalled = false;

  @override
  User? get currentUser => _user;

  @override
  Stream<User?> get authStateChanges => Stream.value(_user);

  @override
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetPasswordCalled = true;
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    updateNameCalled = true;
  }
}

void main() {
  testWidgets(
    'ProfileScreen renders user information, email, and security cards',
    (WidgetTester tester) async {
      final repo = _TestAuthRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            currentUserProvider.overrideWithValue(repo.currentUser),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('User Profile'), findsOneWidget);
      expect(find.text('Masood Test'), findsWidgets);
      expect(find.text('user@example.com'), findsWidgets);
      expect(find.text('Read Only'), findsOneWidget);
      expect(find.text('test_uid_12345'), findsOneWidget);
      expect(find.text('Reset Password'), findsWidgets);
    },
  );

  testWidgets(
    'ProfileScreen edit mode toggles Save Changes and Cancel buttons cleanly',
    (WidgetTester tester) async {
      final repo = _TestAuthRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            currentUserProvider.overrideWithValue(repo.currentUser),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      final editBtn = find.text('Edit Name');
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextFormField, 'Display Name'),
        findsOneWidget,
      );
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Save Changes'), findsNothing);
      expect(find.text('Edit Name'), findsOneWidget);
    },
  );

  testWidgets('ProfileScreen triggers Reset Password email action', (
    WidgetTester tester,
  ) async {
    final repo = _TestAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          currentUserProvider.overrideWithValue(repo.currentUser),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );

    await tester.pumpAndSettle();

    final resetBtn = find.widgetWithText(OutlinedButton, 'Reset Password');
    expect(resetBtn, findsOneWidget);

    await tester.ensureVisible(resetBtn);
    await tester.pumpAndSettle();
    await tester.tap(resetBtn);
    await tester.pumpAndSettle();

    expect(repo.resetPasswordCalled, isTrue);
  });

  testWidgets(
    'ProfileScreen renders cleanly on narrow mobile 320px viewport without overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = _TestAuthRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repo),
            currentUserProvider.overrideWithValue(repo.currentUser),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Edit Name'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
