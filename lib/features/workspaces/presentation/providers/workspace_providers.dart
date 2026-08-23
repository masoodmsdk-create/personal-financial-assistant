import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_financial_assistant/features/auth/presentation/providers/auth_providers.dart';
import 'package:personal_financial_assistant/features/workspaces/data/repositories/firestore_workspace_repository.dart';
import 'package:personal_financial_assistant/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:personal_financial_assistant/features/workspaces/workspace.dart';

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return FirestoreWorkspaceRepository();
});

final workspacesStreamProvider = StreamProvider<List<Workspace>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value([Workspace.createDefault('guest')]);
  }
  final repository = ref.watch(workspaceRepositoryProvider);
  return repository.watchWorkspaces(user.uid);
});

final activeWorkspaceIdProvider = StateProvider<String?>((ref) => null);

final activeWorkspaceProvider = Provider<Workspace>((ref) {
  final user = ref.watch(currentUserProvider);
  final userId = user?.uid ?? 'guest';
  final defaultWorkspace = Workspace.createDefault(userId);

  final workspacesAsync = ref.watch(workspacesStreamProvider);
  final workspaces = workspacesAsync.value ?? [defaultWorkspace];

  final selectedId = ref.watch(activeWorkspaceIdProvider);
  if (selectedId != null) {
    final found = workspaces.where((w) => w.id == selectedId).firstOrNull;
    if (found != null) return found;
  }

  // Fallback to default or first available workspace
  return workspaces.where((w) => w.isDefault).firstOrNull ??
      (workspaces.isNotEmpty ? workspaces.first : defaultWorkspace);
});

class WorkspaceControllerState {
  final bool isLoading;
  final String? errorMessage;

  const WorkspaceControllerState({this.isLoading = false, this.errorMessage});

  WorkspaceControllerState copyWith({bool? isLoading, String? errorMessage}) {
    return WorkspaceControllerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class WorkspaceController extends StateNotifier<WorkspaceControllerState> {
  final WorkspaceRepository _repository;
  final Ref _ref;

  WorkspaceController(this._repository, this._ref)
    : super(const WorkspaceControllerState());

  Future<bool> createWorkspace({
    required String name,
    required String purpose,
    List<String> priorities = const [],
    bool copySetupFromActive = false,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = _ref.read(currentUserProvider);
      final userId = user?.uid ?? 'guest';
      final now = DateTime.now();
      final newWorkspace = Workspace(
        id: 'ws_${now.millisecondsSinceEpoch}',
        userId: userId,
        createdAt: now,
        updatedAt: now,
        name: name.trim(),
        purpose: purpose.trim(),
        priorities: priorities,
        isDefault: false,
      );

      await _repository.createWorkspace(newWorkspace);
      _ref.read(activeWorkspaceIdProvider.notifier).state = newWorkspace.id;
      state = const WorkspaceControllerState();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateWorkspace(Workspace workspace) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.updateWorkspace(workspace);
      state = const WorkspaceControllerState();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteWorkspace(String workspaceId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = _ref.read(currentUserProvider);
      final userId = user?.uid ?? 'guest';
      await _repository.deleteWorkspace(userId, workspaceId);

      // Reset active workspace ID if currently active
      if (_ref.read(activeWorkspaceIdProvider) == workspaceId) {
        _ref.read(activeWorkspaceIdProvider.notifier).state = null;
      }

      state = const WorkspaceControllerState();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final workspaceControllerProvider =
    StateNotifierProvider<WorkspaceController, WorkspaceControllerState>((ref) {
      final repository = ref.watch(workspaceRepositoryProvider);
      return WorkspaceController(repository, ref);
    });
