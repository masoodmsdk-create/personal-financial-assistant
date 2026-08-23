import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> userCollection(
    String userId,
    String collection,
  ) {
    return _firestore.collection('users').doc(userId).collection(collection);
  }

  DocumentReference<Map<String, dynamic>> userDoc(
    String userId,
    String collection,
    String docId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(collection)
        .doc(docId);
  }

  Future<void> setData({
    required String userId,
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    try {
      await userDoc(userId, collection, docId)
          .set(data, SetOptions(merge: merge))
          .timeout(
            const Duration(milliseconds: 100),
            onTimeout: () {
              // Local IndexedDB persistence captures write optimistically; background sync continues.
            },
          );
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  Future<Map<String, dynamic>?> getData({
    required String userId,
    required String collection,
    required String docId,
  }) async {
    try {
      final doc = await userDoc(userId, collection, docId).get().timeout(
        const Duration(seconds: 4),
        onTimeout: () => throw const FirestoreException('Request timed out'),
      );
      return doc.data();
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  Future<void> deleteData({
    required String userId,
    required String collection,
    required String docId,
  }) async {
    try {
      await userDoc(userId, collection, docId).delete().timeout(
        const Duration(milliseconds: 100),
        onTimeout: () {
          // Local IndexedDB persistence captures delete optimistically; background sync continues.
        },
      );
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  Future<List<Map<String, dynamic>>> queryCollection({
    required String userId,
    required String collection,
    QueryParams params = const QueryParams(),
  }) async {
    try {
      Query<Map<String, dynamic>> query = userCollection(userId, collection);

      if (params.filters != null) {
        for (final entry in params.filters!.entries) {
          query = query.where(entry.key, isEqualTo: entry.value);
        }
      }

      if (params.orderBy != null) {
        query = query.orderBy(params.orderBy!, descending: params.descending);
      }

      if (params.limit != null) {
        query = query.limit(params.limit!);
      }

      final snapshot = await query.get().timeout(
        const Duration(seconds: 4),
        onTimeout: () => throw const FirestoreException('Query timed out'),
      );
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  Stream<List<Map<String, dynamic>>> watchCollection({
    required String userId,
    required String collection,
    QueryParams params = const QueryParams(),
  }) {
    Query<Map<String, dynamic>> query = userCollection(userId, collection);

    if (params.filters != null) {
      for (final entry in params.filters!.entries) {
        query = query.where(entry.key, isEqualTo: entry.value);
      }
    }

    if (params.orderBy != null) {
      query = query.orderBy(params.orderBy!, descending: params.descending);
    }

    if (params.limit != null) {
      query = query.limit(params.limit!);
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
    );
  }

  Future<void> batchWrite({
    required String userId,
    required List<BatchOperation> operations,
  }) async {
    try {
      final batch = _firestore.batch();
      for (final op in operations) {
        final ref = userDoc(userId, op.collection, op.docId);
        switch (op.type) {
          case BatchOperationType.set:
            batch.set(ref, op.data!, SetOptions(merge: op.merge));
            break;
          case BatchOperationType.update:
            batch.update(ref, op.data!);
            break;
          case BatchOperationType.delete:
            batch.delete(ref);
            break;
        }
      }
      await batch.commit().timeout(
        const Duration(milliseconds: 100),
        onTimeout: () {
          // Local IndexedDB persistence captures batch write optimistically; background sync continues.
        },
      );
    } on FirebaseException catch (e) {
      throw _mapFirestoreException(e);
    }
  }

  FirestoreException _mapFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const FirestoreException(
          'Permission denied',
          code: 'PERMISSION_DENIED',
        );
      case 'not-found':
        return const FirestoreException(
          'Document not found',
          code: 'NOT_FOUND',
        );
      case 'already-exists':
        return const FirestoreException(
          'Document already exists',
          code: 'ALREADY_EXISTS',
        );
      case 'unavailable':
        return const FirestoreException(
          'Service unavailable',
          code: 'UNAVAILABLE',
        );
      case 'deadline-exceeded':
        return const FirestoreException(
          'Request timed out',
          code: 'DEADLINE_EXCEEDED',
        );
      default:
        return FirestoreException(e.message ?? 'Firestore error', code: e.code);
    }
  }
}

enum BatchOperationType { set, update, delete }

class BatchOperation {
  final BatchOperationType type;
  final String collection;
  final String docId;
  final Map<String, dynamic>? data;
  final bool merge;

  const BatchOperation({
    required this.type,
    required this.collection,
    required this.docId,
    this.data,
    this.merge = false,
  });

  factory BatchOperation.set({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = false,
  }) => BatchOperation(
    type: BatchOperationType.set,
    collection: collection,
    docId: docId,
    data: data,
    merge: merge,
  );

  factory BatchOperation.update({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) => BatchOperation(
    type: BatchOperationType.update,
    collection: collection,
    docId: docId,
    data: data,
  );

  factory BatchOperation.delete({
    required String collection,
    required String docId,
  }) => BatchOperation(
    type: BatchOperationType.delete,
    collection: collection,
    docId: docId,
  );
}

class QueryParams {
  final String? orderBy;
  final bool descending;
  final int? limit;
  final Map<String, dynamic>? filters;

  const QueryParams({
    this.orderBy,
    this.descending = true,
    this.limit,
    this.filters,
  });

  QueryParams copyWith({
    String? orderBy,
    bool? descending,
    int? limit,
    Map<String, dynamic>? filters,
  }) {
    return QueryParams(
      orderBy: orderBy ?? this.orderBy,
      descending: descending ?? this.descending,
      limit: limit ?? this.limit,
      filters: filters ?? this.filters,
    );
  }
}
