import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  User? get currentUser;
  Stream<User?> get authStateChanges;
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  );
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  );
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
}
