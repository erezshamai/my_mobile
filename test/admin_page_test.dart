import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_exercisetracker/models/task_type.dart';
import 'package:my_flutter_exercisetracker/admin_page.dart';

void main() {
  testWidgets('addTaskType adds a new task type and shows it in the list', (WidgetTester tester) async {
    final List<TaskType> taskTypes = [
      TaskType(id: '1', name: 'Initial', description: 'initial', createdAt: DateTime.now()),
    ];

    Future<List<TaskType>> getTaskTypes() async => List<TaskType>.from(taskTypes);

    Future<TaskType> addTaskType(String name, String description) async {
      final newTask = TaskType(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, description: description, createdAt: DateTime.now());
      taskTypes.add(newTask);
      return newTask;
    }

    await tester.pumpWidget(MaterialApp(home: AdminPage(getTaskTypesFunc: getTaskTypes, addTaskTypeFunc: addTaskType)));

    // Authenticate
    await tester.enterText(find.byType(TextField).first, 'admin123');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Enter new task type details
    await tester.enterText(find.widgetWithText(TextField, 'Task Type Name'), 'TestType');
    await tester.enterText(find.widgetWithText(TextField, 'Description (Optional)'), 'desc');

    // Tap add
    await tester.tap(find.text('Add Task Type'));
    await tester.pumpAndSettle();

    expect(find.text('TestType'), findsOneWidget);
  });

  testWidgets('removeTaskType removes the selected task type from the list', (WidgetTester tester) async {
    final List<TaskType> taskTypes = [
      TaskType(id: 'a', name: 'TypeA', description: 'A', createdAt: DateTime.now()),
      TaskType(id: 'b', name: 'TypeB', description: 'B', createdAt: DateTime.now()),
    ];

    Future<List<TaskType>> getTaskTypes() async => List<TaskType>.from(taskTypes);

    Future<void> removeTaskType(String id) async {
      taskTypes.removeWhere((t) => t.id == id);
    }

    await tester.pumpWidget(MaterialApp(home: AdminPage(getTaskTypesFunc: getTaskTypes, removeTaskTypeFunc: removeTaskType)));

    // Authenticate
    await tester.enterText(find.byType(TextField).first, 'admin123');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Ensure both present
    expect(find.text('TypeA'), findsOneWidget);
    expect(find.text('TypeB'), findsOneWidget);

    // Find the ListTile for TypeA and tap its delete icon
    final tile = find.widgetWithText(ListTile, 'TypeA');
    final deleteButton = find.descendant(of: tile, matching: find.byIcon(Icons.delete));
    expect(deleteButton, findsOneWidget);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Confirm deletion in dialog
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('TypeA'), findsNothing);
    expect(find.text('TypeB'), findsOneWidget);
  });
}
