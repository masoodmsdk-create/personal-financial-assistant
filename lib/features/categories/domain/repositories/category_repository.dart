import 'package:personal_financial_assistant/features/categories/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories(String userId);
  Stream<List<Category>> watchCategories(String userId);
  Future<void> seedDefaultCategories(String userId);
  Future<void> createCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> archiveCategory({
    required String userId,
    required String categoryId,
  });
  Future<void> restoreCategory({
    required String userId,
    required String categoryId,
  });
}
