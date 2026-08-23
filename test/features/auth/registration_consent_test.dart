import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/auth/domain/repositories/auth_repository.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/auth/presentation/screens/register_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> get authStateChanges => Stream.value(null);

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
  testWidgets(
    'RegisterScreen renders safety warning card and consent checkboxes',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          ],
          child: const MaterialApp(home: RegisterScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Check Safety Card
      expect(find.text('🔐 Stay Safe'), findsOneWidget);
      expect(
        find.textContaining('We will never ask you for your OTP'),
        findsOneWidget,
      );

      // Check Policy Checkboxes
      expect(find.textContaining('Terms of Service'), findsWidgets);
      expect(find.textContaining('Privacy Notice'), findsWidgets);

      // Verify Create My Account button is initially disabled (checkboxes unchecked)
      final buttonFinder = find.widgetWithText(
        FilledButton,
        'Create My Account',
      );
      expect(buttonFinder, findsOneWidget);
      final button = tester.widget<FilledButton>(buttonFinder);
      expect(button.onPressed, isNull);
    },
  );
}
