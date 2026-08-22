import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Stream<String?> get userIdChanges =>
      _auth.authStateChanges().map((user) => user?.uid);

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
        await credential.user?.reload();
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<void> updateEmail(String email) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(email);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<void> updatePassword(String password) async {
    try {
      await _auth.currentUser?.updatePassword(password);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<void> reload() async {
    try {
      await _auth.currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  AuthException _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthException(
          'No user found with this email',
          code: 'USER_NOT_FOUND',
        );
      case 'wrong-password':
        return const AuthException(
          'Incorrect password',
          code: 'WRONG_PASSWORD',
        );
      case 'email-already-in-use':
        return const AuthException(
          'An account already exists with this email',
          code: 'EMAIL_IN_USE',
        );
      case 'weak-password':
        return const AuthException(
          'Password is too weak',
          code: 'WEAK_PASSWORD',
        );
      case 'invalid-email':
        return const AuthException(
          'Invalid email address',
          code: 'INVALID_EMAIL',
        );
      case 'user-disabled':
        return const AuthException(
          'This account has been disabled',
          code: 'USER_DISABLED',
        );
      case 'too-many-requests':
        return const AuthException(
          'Too many attempts. Please try again later',
          code: 'TOO_MANY_REQUESTS',
        );
      case 'operation-not-allowed':
        return const AuthException(
          'Email/password authentication is not enabled',
          code: 'OPERATION_NOT_ALLOWED',
        );
      case 'requires-recent-login':
        return const AuthException(
          'Please log in again to continue',
          code: 'REQUIRES_RECENT_LOGIN',
        );
      default:
        return AuthException(
          e.message ?? 'Authentication failed',
          code: e.code,
        );
    }
  }
}
