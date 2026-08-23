import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/goals/data/repositories/firestore_goal_repository.dart';
import 'package:personal_financial_assistant/features/goals/domain/repositories/goal_repository.dart';
import 'package:personal_financial_assistant/features/goals/goal.dart';

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return FirestoreGoalRepository();
});

final goalsStreamProvider = StreamProvider<List<Goal>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value(const []);
  }
  final repository = ref.watch(goalRepositoryProvider);
  return repository.watchGoals(user.uid);
});

class GoalController extends StateNotifier<AsyncValue<void>> {
  final GoalRepository _repository;
  final Ref _ref;

  GoalController(this._repository, this._ref) : super(const AsyncData(null));

  String? _getCurrentUserId() {
    return _ref.read(currentUserProvider)?.uid;
  }

  Future<bool> createGoal({
    required String name,
    required GoalType type,
    required double targetAmount,
    double currentAmount = 0.0,
    DateTime? targetDate,
    String? linkedLoanId,
    String? linkedAccountId,
    String? notes,
  }) async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    final now = DateTime.now();
    final goal = Goal(
      id: 'goal_${now.microsecondsSinceEpoch}',
      userId: userId,
      name: name,
      type: type,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      targetDate: targetDate,
      linkedLoanId: linkedLoanId,
      linkedAccountId: linkedAccountId,
      notes: notes,
      active: true,
      createdAt: now,
      updatedAt: now,
    );

    state = await AsyncValue.guard(() => _repository.createGoal(goal));
    return !state.hasError;
  }

  Future<bool> updateGoal(Goal goal) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.updateGoal(goal));
    return !state.hasError;
  }

  Future<bool> archiveGoal(String goalId) async {
    final userId = _getCurrentUserId();
    if (userId == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.archiveGoal(userId: userId, goalId: goalId),
    );
    return !state.hasError;
  }

  Future<bool> deleteGoal(String goalId) async {
    final userId = _getCurrentUserId();
    if (userId == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.deleteGoal(userId: userId, goalId: goalId),
    );
    return !state.hasError;
  }
}

final goalControllerProvider =
    StateNotifierProvider<GoalController, AsyncValue<void>>((ref) {
      return GoalController(ref.watch(goalRepositoryProvider), ref);
    });
