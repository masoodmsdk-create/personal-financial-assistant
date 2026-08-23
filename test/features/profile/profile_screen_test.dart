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
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> updateDisplayName(String displayName) async {}
}

void main() {
  testWidgets('ProfileScreen renders user information and read-only email', (
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

    expect(find.text('User Profile'), findsOneWidget);
    expect(find.text('Masood Test'), findsWidgets);
    expect(find.text('user@example.com'), findsWidgets);
    expect(find.text('Read Only'), findsOneWidget);
    expect(find.text('test_uid_12345'), findsOneWidget);
  });

  testWidgets('ProfileScreen opens edit form when Edit button is tapped', (
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

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Display Name'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });
}
