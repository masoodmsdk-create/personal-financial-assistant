import 'package:personal_financial_assistant/features/workspaces/workspace.dart';

abstract class WorkspaceRepository {
  Future<List<Workspace>> getWorkspaces(String userId);
  Stream<List<Workspace>> watchWorkspaces(String userId);
  Future<Workspace?> getWorkspace(String userId, String workspaceId);
  Future<void> createWorkspace(Workspace workspace);
  Future<void> updateWorkspace(Workspace workspace);
  Future<void> deleteWorkspace(String userId, String workspaceId);
}
