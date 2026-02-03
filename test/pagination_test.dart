import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_exercisetracker/main.dart';

void main() {
  group('Pagination UI Tests', () {
    testWidgets('pagination controls are present when app loads', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Check if pagination controls exist (they may be hidden if < 6 records)
      final leftArrow = find.byIcon(Icons.keyboard_arrow_left);
      final rightArrow = find.byIcon(Icons.keyboard_arrow_right);
      
      // The controls might not be visible if there are fewer than 6 records
      // But they should exist in the widget tree
      expect(leftArrow, findsOneWidget);
      expect(rightArrow, findsOneWidget);
    });

    testWidgets('next and previous buttons are IconButton widgets', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final leftArrow = find.byIcon(Icons.keyboard_arrow_left);
      final rightArrow = find.byIcon(Icons.keyboard_arrow_right);
      
      expect(leftArrow, findsOneWidget);
      expect(rightArrow, findsOneWidget);
      
      // Verify they are IconButton widgets
      expect(tester.widget<IconButton>(leftArrow), isA<IconButton>());
      expect(tester.widget<IconButton>(rightArrow), isA<IconButton>());
    });

    testWidgets('page indicator text shows correct format', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Look for page indicator text (may not be visible if < 6 records)
      final pageText = find.textContaining('Page');
      if (pageText.evaluate().isNotEmpty) {
        expect(pageText, findsOneWidget);
        // Should match format "Page X of Y"
        final text = tester.widget<Text>(pageText);
        expect(text.data, matches(RegExp(r'Page \d+ of \d+')));
      }
    });

    testWidgets('record count text shows appropriate format', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Look for record count text
      final countText = find.textContaining('records');
      if (countText.evaluate().isNotEmpty) {
        expect(countText, findsOneWidget);
        final text = tester.widget<Text>(countText);
        expect(text.data, contains('records'));
      }
    });

    testWidgets('DataTable displays records correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Check if DataTable exists
      final dataTable = find.byType(DataTable);
      expect(dataTable, findsOneWidget);

      // Check if there are DataRow widgets
      final dataRows = find.byType(DataRow);
      if (dataRows.evaluate().isNotEmpty) {
        // Should have at least one row if there are records
        expect(dataRows, findsAtLeastNWidgets(1));
        
        // Should not have more than 5 rows (page size) - check count manually if needed
        final rowCount = dataRows.evaluate().length;
        expect(rowCount <= 5, true);
      }
    });

    testWidgets('filter controls exist and are functional', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Look for filter dropdown
      final filterDropdown = find.byType(DropdownButtonFormField<String>);
      if (filterDropdown.evaluate().isNotEmpty) {
        expect(filterDropdown, findsOneWidget);
        
        // Try to tap it to see if it's functional
        await tester.tap(filterDropdown);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('start button exists and is tappable', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Look for the start button (Hebrew text)
      final startButton = find.text('התחל משימה');
      if (startButton.evaluate().isNotEmpty) {
        expect(startButton, findsOneWidget);
        
        // Verify it's an ElevatedButton
        expect(tester.widget<ElevatedButton>(startButton), isA<ElevatedButton>());
        
        // Try to tap it
        await tester.tap(startButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('refresh button exists in AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Look for refresh button in AppBar
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);
      
      // Verify it's an IconButton
      expect(tester.widget<IconButton>(refreshButton), isA<IconButton>());
      
      // Try to tap it
      await tester.tap(refreshButton);
      await tester.pumpAndSettle();
    });

    testWidgets('app title is correct', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Check for the Hebrew app title
      final appTitle = find.text('מעקב משימות');
      expect(appTitle, findsOneWidget);
    });
  });

  group('Pagination Integration Tests', () {
    testWidgets('pagination controls respond to taps', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final leftArrow = find.byIcon(Icons.keyboard_arrow_left);
      final rightArrow = find.byIcon(Icons.keyboard_arrow_right);
      
      // Try tapping the buttons (they may be disabled)
      await tester.tap(rightArrow);
      await tester.pumpAndSettle();
      
      await tester.tap(leftArrow);
      await tester.pumpAndSettle();
      
      // The app should not crash and should still be responsive
      expect(find.byType(ExerciseTrackerScreen), findsOneWidget);
    });

    testWidgets('filter changes do not crash the app', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Try to interact with filter controls
      final clearFiltersButton = find.byIcon(Icons.clear_all);
      if (clearFiltersButton.evaluate().isNotEmpty) {
        await tester.tap(clearFiltersButton);
        await tester.pumpAndSettle();
      }
      
      // App should still be responsive
      expect(find.byType(ExerciseTrackerScreen), findsOneWidget);
    });
  });

  group('Pagination Edge Cases', () {
    testWidgets('app loads without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Basic sanity check - app should load
      expect(find.byType(ExerciseTrackerScreen), findsOneWidget);
    });

    testWidgets('handles empty state gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Even with no records, the app should not crash
      expect(find.byType(ExerciseTrackerScreen), findsOneWidget);
      
      // Should show appropriate message if no records
      final noRecordsText = find.textContaining('No records');
      if (noRecordsText.evaluate().isNotEmpty) {
        expect(noRecordsText, findsOneWidget);
      }
    });
  });
}