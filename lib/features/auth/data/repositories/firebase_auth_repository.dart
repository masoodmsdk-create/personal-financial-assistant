import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_financial_assistant/core/services/auth_service.dart';
import 'package:personal_financial_assistant/features/auth/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final AuthService _authService;

  FirebaseAuthRepository({AuthService? authService})
    : _authService = authService ?? AuthService();

  @override
  User? get currentUser => _authService.currentUser;

  @override
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  @override
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return _authService.signInWithEmailAndPassword(email.trim(), password);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return _authService.createUserWithEmailAndPassword(
      email.trim(),
      password,
      displayName: displayName?.trim(),
    );
  }

  @override
  Future<void> signOut() async {
    return _authService.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    return _authService.sendPasswordResetEmail(email.trim());
  }
}

