import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/accounts/account.dart';
import 'package:personal_financial_assistant/features/accounts/presentation/providers/account_providers.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/smart_entry/presentation/screens/smart_entry_screen.dart';

void main() {
  final mockAccounts = [
    Account(
      id: 'acc_1',
      userId: 'user_1',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      name: 'HDFC Bank',
      type: AccountType.bank,
      openingBalance: 5000.0,
      currency: 'INR',
      active: true,
    ),
  ];

  final mockCategories = [
    Category(
      id: 'cat_1',
      userId: 'user_1',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      name: 'Food & Dining',
      type: CategoryType.expense,
      active: true,
    ),
  ];

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        accountsStreamProvider.overrideWith(
          (ref) => Stream.value(mockAccounts),
        ),
        categoriesStreamProvider.overrideWith(
          (ref) => Stream.value(mockCategories),
        ),
      ],
      child: const MaterialApp(home: SmartEntryScreen()),
    );
  }

  group('SmartEntryScreen Tests', () {
    testWidgets(
      'Renders input, prompt chips, and disabled Understand button when input is empty',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Smart Financial Assistant'), findsOneWidget);
        expect(find.text('Smart Assistant Entry'), findsOneWidget);
        expect(find.text('Understand'), findsOneWidget);
        expect(find.text('Quick Examples (tap to test)'), findsOneWidget);

        // Verify button is disabled initially
        final understandBtn = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Understand'),
        );
        expect(understandBtn.onPressed, isNull);
      },
    );

    testWidgets(
      'Typing input enables Understand button, clicking triggers parsing and displays drafts with Confirm & Save buttons',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Enter text into TextField
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);
        await tester.enterText(textField, 'Lunch 450 cash');
        await tester.pumpAndSettle();

        // Verify button is now enabled
        final understandBtn = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Understand'),
        );
        expect(understandBtn.onPressed, isNotNull);

        // Tap Understand button
        await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'Understand'),
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Understand'));
        await tester.pumpAndSettle();

        // Verify parsed transaction draft appears
        expect(find.text('Detected Transactions (1)'), findsOneWidget);
        expect(find.text('EXPENSE'), findsOneWidget);
        expect(find.text('Confirm & Save All (1)'), findsOneWidget);
        expect(find.text('Confirm & Save'), findsOneWidget);
      },
    );

    testWidgets('Tapping sample prompt chip auto-populates and parses drafts', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap a sample prompt chip
      final promptChip = find.text('Bought groceries 1400 cash');
      expect(promptChip, findsOneWidget);
      await tester.ensureVisible(promptChip);
      await tester.tap(promptChip);
      await tester.pumpAndSettle();

      // Verify parsed transaction draft appears
      expect(find.text('Detected Transactions (1)'), findsOneWidget);
      expect(find.text('EXPENSE'), findsOneWidget);
      expect(find.text('Confirm & Save All (1)'), findsOneWidget);
    });

    for (final size in [
      const Size(360, 800),
      const Size(390, 844),
      const Size(430, 932),
      const Size(1280, 800),
    ]) {
      testWidgets(
        'Renders cleanly without overflow on ${size.width}x${size.height}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          expect(find.text('Smart Assistant Entry'), findsOneWidget);
          expect(find.text('Understand'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
