import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/views/screens/startInfoCollect/cuisine_interests_screen.dart';

void main() {
  group('CuisineInterestsScreen', () {
    testWidgets('allows multiple cuisine selections', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CuisineInterestsScreen(),
        ),
      );

      // Find all cuisine tiles
      final italianFinder = find.text('Italian');
      final asianFinder = find.text('Asian');
      final africanFinder = find.text('African');
      final otherFinder = find.text('Other');

      // Verify all options are present
      expect(italianFinder, findsOneWidget);
      expect(asianFinder, findsOneWidget);
      expect(africanFinder, findsOneWidget);
      expect(otherFinder, findsOneWidget);

      // Tap on Italian and Asian
      await tester.tap(italianFinder);
      await tester.tap(asianFinder);
      await tester.pump();

      // Verify both are selected (checking for the checkboxes)
      final checkedBoxes = find.byWidgetPredicate(
        (Widget widget) =>
            widget is Container &&
            widget.decoration != null &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == Colors.deepOrange,
      );

      // Should have 2 checked boxes
      expect(checkedBoxes, findsNWidgets(2));
    });

    testWidgets('can deselect a selected cuisine', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CuisineInterestsScreen(),
        ),
      );

      // Tap on Italian to select it
      await tester.tap(find.text('Italian'));
      await tester.pump();

      // Verify it's selected
      final checkedBox = find.byWidgetPredicate(
        (Widget widget) =>
            widget is Container &&
            widget.decoration != null &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == Colors.deepOrange,
      );
      expect(checkedBox, findsOneWidget);

      // Tap on Italian again to deselect it
      await tester.tap(find.text('Italian'));
      await tester.pump();

      // Verify it's deselected
      expect(checkedBox, findsNothing);
    });
  });
}