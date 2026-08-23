import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/features/categories/category.dart';
import 'package:personal_financial_assistant/features/categories/presentation/providers/category_providers.dart';
import 'package:personal_financial_assistant/features/categories/presentation/screens/categories_screen.dart';

void main() {
  final now = DateTime.parse('2026-08-23T06:00:00.000Z');
  final testCategories = [
    Category(
      id: 'cat_inc_1',
      userId: 'user_1',
      createdAt: now,
      updatedAt: now,
      name: 'Salary',
      type: CategoryType.income,
      active: true,
      isDefault: true,
      sortOrder: 0,
    ),
    Category(
      id: 'cat_exp_1',
      userId: 'user_1',
      createdAt: now,
      updatedAt: now,
      name: 'Food',
      type: CategoryType.expense,
      active: true,
      isDefault: true,
      sortOrder: 0,
    ),
  ];

  testWidgets(
    'CategoriesScreen renders Income and Expense tabs and default categories',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesStreamProvider.overrideWith(
              (ref) => Stream.value(testCategories),
            ),
          ],
          child: const MaterialApp(home: CategoriesScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);

      // Switch to Expense tab
      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
    },
  );

  testWidgets(
    'CategoriesScreen displays empty state when category list is empty',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoriesStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: CategoriesScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Income Categories'), findsOneWidget);
    },
  );
}
