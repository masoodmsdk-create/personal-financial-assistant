import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/workspaces/workspace.dart';

void main() {
  group('Workspace Domain Model Tests', () {
    test('Workspace.createDefault initializes personal finances workspace', () {
      final ws = Workspace.createDefault('user_123');

      expect(ws.id, 'ws_default_user_123');
      expect(ws.userId, 'user_123');
      expect(ws.name, 'Personal Finances');
      expect(ws.purpose, contains('Manage daily personal income'));
      expect(ws.isDefault, isTrue);
      expect(ws.priorities, contains('Understand cash flow'));
    });

    test('toJson and fromJson preserves all fields', () {
      final now = DateTime(2026, 8, 23, 12, 0, 0);
      final original = Workspace(
        id: 'ws_family_01',
        userId: 'user_456',
        createdAt: now,
        updatedAt: now,
        name: 'Family Finances',
        purpose: 'Manage household expenses and reduce home loan faster.',
        priorities: const ['Control spending', 'Reduce debt'],
        isDefault: false,
      );

      final json = original.toJson();
      final reconstructed = Workspace.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.userId, original.userId);
      expect(reconstructed.name, original.name);
      expect(reconstructed.purpose, original.purpose);
      expect(reconstructed.priorities, original.priorities);
      expect(reconstructed.isDefault, isFalse);
    });

    test(
      'copyWith produces updated instance with new purpose and priorities',
      () {
        final ws = Workspace.createDefault('user_789');
        final updated = ws.copyWith(
          name: 'Rental Property',
          purpose: 'Track rental income and loan repayment profitability.',
          priorities: ['Track property / rental profit'],
        );

        expect(updated.name, 'Rental Property');
        expect(updated.purpose, contains('profitability'));
        expect(updated.priorities, contains('Track property / rental profit'));
        expect(updated.userId, 'user_789');
      },
    );
  });
}
