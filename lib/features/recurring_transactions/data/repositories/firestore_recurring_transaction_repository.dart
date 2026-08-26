import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/core/services/firestore_service.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/models/recurring_transaction_rule.dart';
import 'package:personal_financial_assistant/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';

class FirestoreRecurringTransactionRepository
    implements RecurringTransactionRepository {
  final FirestoreService _firestoreService;
  final FirebaseAuth _firebaseAuth;

  static const String _rulesCollection = 'recurring_transactions';
  static const int maxNameLength = 60;

  FirestoreRecurringTransactionRepository({
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

  void _validateRule(RecurringTransactionRule rule) {
    final name = rule.name.trim();
    if (name.isEmpty) {
      throw const ValidationException('Rule name is required');
    }
    if (name.length > maxNameLength) {
      throw const ValidationException('Rule name cannot exceed 60 characters');
    }
    if (rule.amount <= 0) {
      throw const ValidationException(
        'Recurring amount must be greater than zero',
      );
    }
    if (rule.categoryId.trim().isEmpty) {
      throw const ValidationException('Category is required');
    }
    if (rule.accountId.trim().isEmpty) {
      throw const ValidationException('Account is required');
    }
    if (rule.interval < 1) {
      throw const ValidationException('Interval must be at least 1');
    }
    if (rule.endDate != null && rule.endDate!.isBefore(rule.startDate)) {
      throw const ValidationException('End date cannot be before start date');
    }
  }

  @override
  Stream<List<RecurringTransactionRule>> getRecurringTransactions(
    String userId,
  ) {
    final currentUid = _requireCurrentUserId();
    return _firestoreService
        .watchCollection(
          userId: currentUid,
          collection: _rulesCollection,
          params: const QueryParams(orderBy: 'createdAt', descending: true),
        )
        .map(
          (dataList) => dataList
              .map((data) => RecurringTransactionRule.fromJson(data))
              .toList(),
        );
  }

  @override
  Future<RecurringTransactionRule?> getRecurringTransactionById(
    String userId,
    String id,
  ) async {
    final currentUid = _requireCurrentUserId();
    final data = await _firestoreService.getData(
      userId: currentUid,
      collection: _rulesCollection,
      docId: id,
    );
    if (data == null) return null;
    return RecurringTransactionRule.fromJson(data);
  }

  @override
  Future<void> createRecurringTransaction(RecurringTransactionRule rule) async {
    final currentUid = _requireCurrentUserId();
    final cleanRule = rule.copyWith(
      userId: currentUid,
      name: rule.name.trim(),
      note: rule.note?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _validateRule(cleanRule);

    await _firestoreService.setData(
      userId: currentUid,
      collection: _rulesCollection,
      docId: cleanRule.id,
      data: cleanRule.toJson(),
    );
  }

  @override
  Future<void> updateRecurringTransaction(RecurringTransactionRule rule) async {
    final currentUid = _requireCurrentUserId();
    final cleanRule = rule.copyWith(
      userId: currentUid,
      name: rule.name.trim(),
      note: rule.note?.trim(),
      updatedAt: DateTime.now(),
    );

    _validateRule(cleanRule);

    await _firestoreService.setData(
      userId: currentUid,
      collection: _rulesCollection,
      docId: cleanRule.id,
      data: cleanRule.toJson(),
      merge: true,
    );
  }

  @override
  Future<void> deleteRecurringTransaction(String userId, String id) async {
    final currentUid = _requireCurrentUserId();
    await _firestoreService.deleteData(
      userId: currentUid,
      collection: _rulesCollection,
      docId: id,
    );
  }

  @override
  Future<void> toggleRecurringTransactionStatus(
    String userId,
    String id,
    bool active,
  ) async {
    final currentUid = _requireCurrentUserId();
    await _firestoreService.setData(
      userId: currentUid,
      collection: _rulesCollection,
      docId: id,
      data: {'active': active, 'updatedAt': DateTime.now().toIso8601String()},
      merge: true,
    );
  }
}
