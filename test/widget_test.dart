import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/auth/domain/repositories/auth_repository.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/screens/login_screen.dart';

class FakeAuthRepository implements AuthRepository {
  final User? _user;
  FakeAuthRepository([this._user]);

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
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}
}

void main() {
  testWidgets('LoginScreen displays title, input fields, and action buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
