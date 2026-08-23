import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/domain/models/account_type_definition.dart';

void main() {
  final now = DateTime(2026, 8, 23);

  group('Extensible Custom Account Types & Financial Semantics Unit Tests', () {
    test('System Default Account Types retain correct natures', () {
      final bank = AccountTypeDefinition.defaultTypes.firstWhere(
        (t) => t.id == 'bank',
      );
      final cash = AccountTypeDefinition.defaultTypes.firstWhere(
        (t) => t.id == 'cash',
      );
      final card = AccountTypeDefinition.defaultTypes.firstWhere(
        (t) => t.id == 'credit_card',
      );
      final other = AccountTypeDefinition.defaultTypes.firstWhere(
        (t) => t.id == 'other',
      );

      expect(bank.nature, equals(AccountNature.asset));
      expect(cash.nature, equals(AccountNature.asset));
      expect(card.nature, equals(AccountNature.liability));
      expect(other.nature, equals(AccountNature.asset));
    });

    test('Custom Asset account contributes positively to Net Balance', () {
      final customAssetAccount = Account(
        id: 'acc_asset_1',
        userId: 'user_1',
        createdAt: now,
        updatedAt: now,
        name: 'Provident Fund',
        type: AccountType.other,
        accountTypeId: 'type_pf',
        nature: AccountNature.asset,
        openingBalance: 150000.0,
        currency: 'INR',
        active: true,
      );

      expect(customAssetAccount.isLiabilityAccount, isFalse);
      expect(customAssetAccount.effectiveBalance, equals(150000.0));
    });

    test('Custom Liability account reduces Net Balance', () {
      final customLiabilityAccount = Account(
        id: 'acc_liab_1',
        userId: 'user_1',
        createdAt: now,
        updatedAt: now,
        name: 'Personal Loan Account',
        type: AccountType.other,
        accountTypeId: 'type_loan',
        nature: AccountNature.liability,
        openingBalance: 50000.0,
        currency: 'INR',
        active: true,
      );

      expect(customLiabilityAccount.isLiabilityAccount, isTrue);
    });

    test('Legacy Credit Card account continues working as liability', () {
      final legacyCard = Account(
        id: 'acc_card_1',
        userId: 'user_1',
        createdAt: now,
        updatedAt: now,
        name: 'HDFC Credit Card',
        type: AccountType.creditCard,
        openingBalance: 25000.0,
        currency: 'INR',
        active: true,
      );

      expect(legacyCard.isCreditAccount, isTrue);
      expect(legacyCard.isLiabilityAccount, isTrue);
    });
  });
}
