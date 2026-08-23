import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';

void main() {
  group('Account Model Tests', () {
    final now = DateTime.parse('2026-08-23T06:00:00.000Z');
    final sampleAccount = Account(
      id: 'acc_123',
      userId: 'user_456',
      createdAt: now,
      updatedAt: now,
      name: 'HDFC Bank',
      type: AccountType.bank,
      openingBalance: 15000.50,
      currency: 'INR',
      active: true,
    );

    test('serializes to JSON correctly', () {
      final json = sampleAccount.toJson();
      expect(json['id'], 'acc_123');
      expect(json['userId'], 'user_456');
      expect(json['name'], 'HDFC Bank');
      expect(json['type'], 'bank');
      expect(json['openingBalance'], 15000.50);
      expect(json['currency'], 'INR');
      expect(json['active'], true);
    });

    test('deserializes from JSON correctly', () {
      final json = sampleAccount.toJson();
      final deserialized = Account.fromJson(json);
      expect(deserialized.id, sampleAccount.id);
      expect(deserialized.name, sampleAccount.name);
      expect(deserialized.type, sampleAccount.type);
      expect(deserialized.openingBalance, sampleAccount.openingBalance);
    });

    test('calculates effective balance correctly', () {
      expect(sampleAccount.effectiveBalance, 15000.50);
    });

    test('identifies credit account correctly', () {
      expect(sampleAccount.isCreditAccount, false);

      final creditCard = sampleAccount.copyWith(type: AccountType.creditCard);
      expect(creditCard.isCreditAccount, true);
    });

    test('AccountType extensions return proper display names', () {
      expect(AccountType.bank.displayName, 'Bank Account');
      expect(AccountType.cash.displayName, 'Cash');
      expect(AccountType.creditCard.displayName, 'Credit Card');
      expect(AccountType.other.displayName, 'Other');
    });
  });
}
