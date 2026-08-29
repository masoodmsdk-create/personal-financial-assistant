import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_financial_assistant/core/widgets/responsive_center.dart';

void main() {
  group('ResponsiveCenter Constraint Normalization Tests', () {
    const viewports = <String, Size>{
      '360px (Small Mobile)': Size(360, 800),
      '390px (Standard Mobile)': Size(390, 844),
      '430px (Large Mobile)': Size(430, 932),
      '600px (Tablet Portrait)': Size(600, 900),
      '1024px (Tablet Landscape)': Size(1024, 768),
      '1280px (Desktop HD)': Size(1280, 800),
      '1440px (Desktop Widescreen)': Size(1440, 900),
    };

    for (final entry in viewports.entries) {
      testWidgets('Normalizes constraints cleanly on ${entry.key}', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        BoxConstraints? observedConstraints;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ResponsiveCenter(
                  maxWidth: 1000,
                  padding: const EdgeInsets.all(16.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      observedConstraints = constraints;
                      return Container(
                        color: Colors.blue,
                        child: const Text('Responsive Child Content'),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(observedConstraints, isNotNull);
        expect(
          observedConstraints!.minWidth,
          lessThanOrEqualTo(observedConstraints!.maxWidth),
        );

        final expectedMaxWidth = entry.value.width > 1000.0
            ? 1000.0 - 32.0
            : entry.value.width - 32.0;

        expect(observedConstraints!.maxWidth, equals(expectedMaxWidth));

        final textFinder = find.text('Responsive Child Content');
        expect(textFinder, findsOneWidget);
        final textSize = tester.getSize(textFinder);
        expect(textSize.width, greaterThan(100.0));
        expect(textSize.height, lessThanOrEqualTo(50.0));

        expect(tester.takeException(), isNull);
      });
    }
  });
}
