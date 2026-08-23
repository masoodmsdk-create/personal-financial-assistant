import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/core/services/firestore_service.dart';
import 'package:personal_financial_assistant/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';

class FirestoreGoalRepository implements GoalRepository {
  final FirestoreService _firestoreService;
  final FirebaseAuth _firebaseAuth;

  static const String _collectionName = 'goals';

  FirestoreGoalRepository({
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
  Future<List<Goal>> getGoals(String userId) async {
    final currentUid = _requireCurrentUserId();
    final dataList = await _firestoreService.queryCollection(
      userId: currentUid,
      collection: _collectionName,
      params: const QueryParams(orderBy: 'createdAt', descending: true),
    );
    return dataList.map((data) => Goal.fromJson(data)).toList();
  }

  @override
  Stream<List<Goal>> watchGoals(String userId) {
    final currentUid = _requireCurrentUserId();
    return _firestoreService
        .watchCollection(
          userId: currentUid,
          collection: _collectionName,
          params: const QueryParams(orderBy: 'createdAt', descending: true),
        )
        .map(
          (dataList) => dataList.map((data) => Goal.fromJson(data)).toList(),
        );
  }

  @override
  Future<void> createGoal(Goal goal) async {
    final currentUid = _requireCurrentUserId();
    final secureGoal = goal.copyWith(userId: currentUid);
    await _firestoreService.setData(
      userId: currentUid,
      collection: _collectionName,
      docId: secureGoal.id,
      data: secureGoal.toJson(),
    );
  }

  @override
  Future<void> updateGoal(Goal goal) async {
    final currentUid = _requireCurrentUserId();
    final secureGoal = goal.copyWith(
      userId: currentUid,
      updatedAt: DateTime.now(),
    );
    await _firestoreService.setData(
      userId: currentUid,
      collection: _collectionName,
      docId: secureGoal.id,
      data: secureGoal.toJson(),
      merge: true,
    );
  }

  @override
  Future<void> archiveGoal({
    required String userId,
    required String goalId,
  }) async {
    final currentUid = _requireCurrentUserId();
    await _firestoreService.setData(
      userId: currentUid,
      collection: _collectionName,
      docId: goalId,
      data: {'active': false, 'updatedAt': DateTime.now().toIso8601String()},
      merge: true,
    );
  }

  @override
  Future<void> deleteGoal({
    required String userId,
    required String goalId,
  }) async {
    final currentUid = _requireCurrentUserId();
    await _firestoreService.deleteData(
      userId: currentUid,
      collection: _collectionName,
      docId: goalId,
    );
  }
}
