import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/data/repositories/firestore_category_repository.dart';
import 'package:personal_financial_assistant/features/categories/domain/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return FirestoreCategoryRepository();
});

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const []);
  }
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.watchCategories(user.uid);
});

final incomeCategoriesProvider = Provider<AsyncValue<List<Category>>>((ref) {
  final categoriesAsync = ref.watch(categoriesStreamProvider);
  return categoriesAsync.whenData(
    (categories) =>
        categories.where((c) => c.type == CategoryType.income).toList(),
  );
});

final expenseCategoriesProvider = Provider<AsyncValue<List<Category>>>((ref) {
  final categoriesAsync = ref.watch(categoriesStreamProvider);
  return categoriesAsync.whenData(
    (categories) =>
        categories.where((c) => c.type == CategoryType.expense).toList(),
  );
});

class CategoryController extends StateNotifier<AsyncValue<void>> {
  final CategoryRepository _repository;
  final Ref _ref;

  CategoryController(this._repository, this._ref)
    : super(const AsyncData(null));

  String? _getCurrentUserId() {
    return _ref.read(currentUserProvider)?.uid;
  }

  Future<bool> createCategory({
    required String name,
    required CategoryType type,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    final now = DateTime.now();
    final category = Category(
      id: 'cat_${now.microsecondsSinceEpoch}',
      userId: userId,
      name: name,
      type: type,
      active: true,
      isDefault: false,
      sortOrder: 100, // custom categories placed after default categories
      createdAt: now,
      updatedAt: now,
    );

    state = await AsyncValue.guard(() => _repository.createCategory(category));
    return !state.hasError;
  }

  Future<bool> updateCategory(Category category) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.updateCategory(category));
    return !state.hasError;
  }

  Future<bool> archiveCategory(String categoryId) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.archiveCategory(userId: userId, categoryId: categoryId),
    );
    return !state.hasError;
  }

  Future<bool> restoreCategory(String categoryId) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.restoreCategory(userId: userId, categoryId: categoryId),
    );
    return !state.hasError;
  }
}

final categoryControllerProvider =
    StateNotifierProvider<CategoryController, AsyncValue<void>>((ref) {
      return CategoryController(ref.watch(categoryRepositoryProvider), ref);
    });
