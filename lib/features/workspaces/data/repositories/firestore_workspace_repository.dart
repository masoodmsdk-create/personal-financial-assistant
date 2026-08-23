import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/core/services/firestore_service.dart';
import 'package:personal_financial_assistant/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:personal_financial_assistant/features/workspaces/workspace.dart';

class FirestoreWorkspaceRepository implements WorkspaceRepository {
  final FirestoreService _firestoreService;
  final FirebaseAuth _firebaseAuth;

  static const String _collectionName = 'workspaces';

  FirestoreWorkspaceRepository({
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
  Future<List<Workspace>> getWorkspaces(String userId) async {
    final currentUid = _requireCurrentUserId();
    final dataList = await _firestoreService.queryCollection(
      userId: currentUid,
      collection: _collectionName,
      params: const QueryParams(orderBy: 'createdAt', descending: false),
    );
    if (dataList.isEmpty) {
      final defaultWs = Workspace.createDefault(currentUid);
      return [defaultWs];
    }
    return dataList.map((data) => Workspace.fromJson(data)).toList();
  }

  @override
  Stream<List<Workspace>> watchWorkspaces(String userId) {
    final currentUid = _requireCurrentUserId();
    return _firestoreService
        .watchCollection(
          userId: currentUid,
          collection: _collectionName,
          params: const QueryParams(orderBy: 'createdAt', descending: false),
        )
        .map((dataList) {
          if (dataList.isEmpty) {
            return [Workspace.createDefault(currentUid)];
          }
          return dataList.map((data) => Workspace.fromJson(data)).toList();
        });
  }

  @override
  Future<Workspace?> getWorkspace(String userId, String workspaceId) async {
    final currentUid = _requireCurrentUserId();
    final data = await _firestoreService.getData(
      userId: currentUid,
      collection: _collectionName,
      docId: workspaceId,
    );
    if (data == null) return null;
    return Workspace.fromJson(data);
  }

  @override
  Future<void> createWorkspace(Workspace workspace) async {
    final currentUid = _requireCurrentUserId();
    final secure = workspace.copyWith(userId: currentUid);
    await _firestoreService.setData(
      userId: currentUid,
      collection: _collectionName,
      docId: secure.id,
      data: secure.toJson(),
    );
  }

  @override
  Future<void> updateWorkspace(Workspace workspace) async {
    final currentUid = _requireCurrentUserId();
    final secure = workspace.copyWith(
      userId: currentUid,
      updatedAt: DateTime.now(),
    );
    await _firestoreService.setData(
      userId: currentUid,
      collection: _collectionName,
      docId: secure.id,
      data: secure.toJson(),
    );
  }

  @override
  Future<void> deleteWorkspace(String userId, String workspaceId) async {
    final currentUid = _requireCurrentUserId();
    await _firestoreService.deleteData(
      userId: currentUid,
      collection: _collectionName,
      docId: workspaceId,
    );
  }
}
