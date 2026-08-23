import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_financial_assistant/core/errors/app_exception.dart';
import 'package:personal_financial_assistant/core/services/firestore_service.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/domain/repositories/category_repository.dart';

class FirestoreCategoryRepository implements CategoryRepository {
  final FirestoreService _firestoreService;
  final FirebaseAuth _firebaseAuth;

  static const String _collectionName = 'categories';
  static const int maxCategoryNameLength = 50;

  FirestoreCategoryRepository({
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

  void _validateCategory(Category category, List<Category> existingCategories) {
    final trimmedName = category.name.trim();
    if (trimmedName.isEmpty) {
      throw const ValidationException('Category name cannot be empty');
    }
    if (trimmedName.length > maxCategoryNameLength) {
      throw ValidationException(
        'Category name cannot exceed $maxCategoryNameLength characters',
      );
    }

    final duplicate = existingCategories.any(
      (c) =>
          c.id != category.id &&
          c.type == category.type &&
          c.name.trim().toLowerCase() == trimmedName.toLowerCase(),
    );

    if (duplicate) {
      throw ValidationException(
        'A ${category.type.displayName.toLowerCase()} category with the name "$trimmedName" already exists',
      );
    }
  }

  @override
  Future<void> seedDefaultCategories(String userId) async {
    final currentUid = _requireCurrentUserId();
    final existingData = await _firestoreService.queryCollection(
      userId: currentUid,
      collection: _collectionName,
    );
    final existingIds = existingData.map((d) => d['id'] as String).toSet();

    final defaults = Category.generateDefaults(currentUid);
    final missingDefaults = defaults
        .where((cat) => !existingIds.contains(cat.id))
        .toList();

    if (missingDefaults.isEmpty) return;

    final operations = missingDefaults
        .map(
          (cat) => BatchOperation.set(
            collection: _collectionName,
            docId: cat.id,
            data: cat.toJson(),
          ),
        )
        .toList();

    await _firestoreService.batchWrite(
      userId: currentUid,
      operations: operations,
    );
  }

  @override
  Future<List<Category>> getCategories(String userId) async {
    final currentUid = _requireCurrentUserId();
    var dataList = await _firestoreService.queryCollection(
      userId: currentUid,
      collection: _collectionName,
      params: const QueryParams(orderBy: 'sortOrder', descending: false),
    );

    if (dataList.isEmpty) {
      await seedDefaultCategories(currentUid);
      dataList = await _firestoreService.queryCollection(
        userId: currentUid,
        collection: _collectionName,
        params: const QueryParams(orderBy: 'sortOrder', descending: false),
      );
    }

    return dataList.map((data) => Category.fromJson(data)).toList();
  }

  @override
  Stream<List<Category>> watchCategories(String userId) {
    final currentUid = _requireCurrentUserId();
    return _firestoreService
        .watchCollection(
          userId: currentUid,
          collection: _collectionName,
          params: const QueryParams(orderBy: 'sortOrder', descending: false),
        )
        .map((dataList) {
          if (dataList.isEmpty) {
            // Trigger background seeding without stalling the stream
            seedDefaultCategories(currentUid).ignore();
            return Category.generateDefaults(currentUid);
          }
          return dataList.map((data) => Category.fromJson(data)).toList();
        });
  }

  @override
  Future<void> createCategory(Category category) async {
    final currentUid = _requireCurrentUserId();
    final existing = await getCategories(currentUid);

    final cleanCategory = category.copyWith(
      userId: currentUid,
      name: category.name.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _validateCategory(cleanCategory, existing);

    await _firestoreService.setData(
      userId: currentUid,
      collection: _collectionName,
      docId: cleanCategory.id,
      data: cleanCategory.toJson(),
    );
  }

  @override
  Future<void> updateCategory(Category category) async {
    final currentUid = _requireCurrentUserId();
    final existing = await getCategories(currentUid);

    final cleanCategory = category.copyWith(
      userId: currentUid,
      name: category.name.trim(),
      updatedAt: DateTime.now(),
    );

    _validateCategory(cleanCategory, existing);

    await _firestoreService.setData(
      userId: currentUid,
      collection: _collectionName,
      docId: cleanCategory.id,
      data: cleanCategory.toJson(),
      merge: true,
    );
  }

  @override
  Future<void> archiveCategory({
    required String userId,
    required String categoryId,
  }) async {
    final currentUid = _requireCurrentUserId();
    final existing = await getCategories(currentUid);
    final target = existing.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => throw const ValidationException('Category not found'),
    );

    final updated = target.copyWith(active: false, updatedAt: DateTime.now());

    await _firestoreService.setData(
      userId: currentUid,
      collection: _collectionName,
      docId: categoryId,
      data: updated.toJson(),
      merge: true,
    );
  }

  @override
  Future<void> restoreCategory({
    required String userId,
    required String categoryId,
  }) async {
    final currentUid = _requireCurrentUserId();
    final existing = await getCategories(currentUid);
    final target = existing.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => throw const ValidationException('Category not found'),
    );

    final updated = target.copyWith(active: true, updatedAt: DateTime.now());

    await _firestoreService.setData(
      userId: currentUid,
      collection: _collectionName,
      docId: categoryId,
      data: updated.toJson(),
      merge: true,
    );
  }
}
