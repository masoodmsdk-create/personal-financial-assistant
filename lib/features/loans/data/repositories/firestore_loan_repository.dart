import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/core/services/firestore_service.dart';
import 'package:personal_financial_assistant/features/loans/domain/repositories/loan_repository.dart';
import 'package:personal_financial_assistant/features/loans/loan.dart';

class FirestoreLoanRepository implements LoanRepository {
  final FirestoreService _firestoreService;
  final FirebaseAuth _firebaseAuth;

  static const String _collectionName = 'loans';

  FirestoreLoanRepository({
    FirestoreService? firestoreService,
    FirebaseAuth? firebaseAuth,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  String _requireCurrentUserId() {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw const AuthException('User is not authenticated');
    }
    return uid;
  }

  @override
  Future<List<Loan>> getLoans(String userId) async {
    final currentUid = _requireCurrentUserId();
    final dataList = await _firestoreService.queryCollection(
      userId: currentUid,
      collection: _collectionName,
      params: const QueryParams(orderBy: 'createdAt', descending: true),
    );
    return dataList.map((data) => Loan.fromJson(data)).toList();
  }

  @override
  Stream<List<Loan>> watchLoans(String userId) {
    final currentUid = _requireCurrentUserId();
    return _firestoreService
        .watchCollection(
          userId: currentUid,
          collection: _collectionName,
          params: const QueryParams(orderBy: 'createdAt', descending: true),
        )
        .map(
          (dataList) => dataList.map((data) => Loan.fromJson(data)).toList(),
        );
  }

  @override
  Future<void> createLoan(Loan loan) async {
    final currentUid = _requireCurrentUserId();
    final secureLoan = loan.copyWith(userId: currentUid);
    await _firestoreService.setData(
      userId: currentUid,
      collection: _collectionName,
      docId: secureLoan.id,
      data: secureLoan.toJson(),
    );
  }

  @override
  Future<void> updateLoan(Loan loan) async {
    final currentUid = _requireCurrentUserId();
    final secureLoan = loan.copyWith(
      userId: currentUid,
      updatedAt: DateTime.now(),
    );
    await _firestoreService.setData(
      userId: currentUid,
      collection: _collectionName,
      docId: secureLoan.id,
      data: secureLoan.toJson(),
      merge: true,
    );
  }

  @override
  Future<void> archiveLoan({
    required String userId,
    required String loanId,
  }) async {
    final currentUid = _requireCurrentUserId();
    await _firestoreService.setData(
      userId: currentUid,
      collection: _collectionName,
      docId: loanId,
      data: {
        'active': false,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      merge: true,
    );
  }

  @override
  Future<void> deleteLoan({
    required String userId,
    required String loanId,
  }) async {
    final currentUid = _requireCurrentUserId();
    await _firestoreService.deleteData(
      userId: currentUid,
      collection: _collectionName,
      docId: loanId,
    );
  }
}

