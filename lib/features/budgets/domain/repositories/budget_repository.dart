import 'package:personal_financial_assistant/features/budgets/domain/models/budget.dart';

abstract class BudgetRepository {
  Future<void> createBudget(Budget budget);
  Future<void> updateBudget(Budget budget);
  Future<void> deleteBudget(String userId, String budgetId);
  Stream<List<Budget>> watchBudgets(String userId, {int? year, int? month});
  Future<List<Budget>> getBudgets(String userId, {int? year, int? month});
}
