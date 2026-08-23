import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/widgets/balance_info_card.dart';

void main() {
  testWidgets(
    'BalanceInfoCard renders title, account type explanations, and note',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: BalanceInfoCard())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('How your balance works'), findsOneWidget);
      expect(find.text('Bank Account'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Credit Card'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      expect(find.textContaining('Adds to balance'), findsWidgets);
      expect(find.textContaining('Reduces net balance'), findsOneWidget);
      expect(
        find.textContaining('Credit card balances represent amounts owed'),
        findsOneWidget,
      );
    },
  );
}
