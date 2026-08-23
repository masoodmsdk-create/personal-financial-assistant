import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/core/services/firestore_service.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/domain/repositories/account_repository.dart';

class FirestoreAccountRepository implements AccountRepository {
  final FirestoreService _firestoreService;
  final FirebaseAuth _firebaseAuth;

  static const String _collectionName = 'accounts';

  FirestoreAccountRepository({
    FirestoreService? firestoreService,
    FirebaseAuth? firebaseAuth,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  String _requireCurrentUserId() {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw const AuthException('User is not authenticated');
    }
    return uid;
  }

  @override
  Future<List<Account>> getAccounts(String userId) async {
    final currentUid = _requireCurrentUserId();
    final dataList = await _firestoreService.queryCollection(
      userId: currentUid,
      collection: _collectionName,
      params: const QueryParams(orderBy: 'createdAt', descending: true),
    );
    return dataList.map((data) => Account.fromJson(data)).toList();
  }

  @override
  Stream<List<Account>> watchAccounts(String userId) {
    final currentUid = _requireCurrentUserId();
    return _firestoreService
        .watchCollection(
          userId: currentUid,
          collection: _collectionName,
          params: const QueryParams(orderBy: 'createdAt', descending: true),
        )
        .map(
          (dataList) => dataList.map((data) => Account.fromJson(data)).toList(),
        );
  }

  @override
  Future<void> createAccount(Account account) async {
    final currentUid = _requireCurrentUserId();
    final secureAccount = account.copyWith(userId: currentUid);
    await _firestoreService.setData(
      userId: currentUid,
      collection: _collectionName,
      docId: secureAccount.id,
      data: secureAccount.toJson(),
    );
  }

  @override
  Future<void> updateAccount(Account account) async {
    final currentUid = _requireCurrentUserId();
    final secureAccount = account.copyWith(
      userId: currentUid,
      updatedAt: DateTime.now(),
    );
    await _firestoreService.setData(
      userId: currentUid,
      collection: _collectionName,
      docId: secureAccount.id,
      data: secureAccount.toJson(),
      merge: true,
    );
  }

  @override
  Future<void> deleteAccount({
    required String userId,
    required String accountId,
  }) async {
    final currentUid = _requireCurrentUserId();
    await _firestoreService.deleteData(
      userId: currentUid,
      collection: _collectionName,
      docId: accountId,
    );
  }
}
