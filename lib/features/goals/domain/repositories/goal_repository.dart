import 'package:personal_financial_assistant/features/goals/goal.dart';

abstract class GoalRepository {
  Future<List<Goal>> getGoals(String userId);
  Stream<List<Goal>> watchGoals(String userId);
  Future<void> createGoal(Goal goal);
  Future<void> updateGoal(Goal goal);
  Future<void> archiveGoal({required String userId, required String goalId});
  Future<void> deleteGoal({required String userId, required String goalId});
}
