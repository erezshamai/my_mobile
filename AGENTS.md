# AGENTS.md - Flutter Exercise Tracker Development Guidelines

This document provides guidelines for agentic coding agents working on the Flutter Exercise Tracker project. Follow these conventions to maintain code consistency and quality.

## Development Commands

### Build and Test
```bash
# Analyze code for issues
flutter analyze

# Run all tests
flutter test

# Run specific test
flutter test test/widget_test.dart

# Build for different platforms
flutter build windows
flutter build android
flutter build ios

# Run app locally
flutter run -d windows
flutter run -d android
flutter run -d ios

# Clean build cache
flutter clean

# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade
```

### Linting and Formatting
```bash
# Auto-fix linting issues
dart fix --apply

# Format code
dart format .
```

## Code Style Guidelines

### File and Naming Conventions
- **Files:** `snake_case.dart` (e.g., `exercise_record.dart`, `task_type_service.dart`)
- **Classes:** `PascalCase` (e.g., `ExerciseTrackerScreen`, `TaskType`)
- **Variables:** `camelCase` with private `_` prefix (e.g., `_isExercising`, `_selectedTaskTypeId`)
- **Methods:** `camelCase` with descriptive names; private methods use `_` prefix
  - Handler methods: `_handle*` (e.g., `_handleStartExercise()`)
  - Builder methods: `_build*` (e.g., `_buildRecordsTable()`)
  - Fetch methods: `_fetch*` (e.g., `_fetchRecords()`)
- **Constants:** `UPPER_SNAKE_CASE` (e.g., `_csvHeaders`)
- **Booleans:** Use `is/has` prefixes (e.g., `_isLoading`, `_hasActiveFilters()`)

### Import Organization
```dart
// 1. Flutter core imports
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// 2. Project imports (alphabetical)
import 'package:my_flutter_exercisetracker/models/exercise_record.dart';
import 'package:my_flutter_exercisetracker/services/local_file_service.dart';
import 'package:my_flutter_exercisetracker/admin_page.dart';

// 3. Commented imports for reference
// import 'package:my_flutter_exercisetracker/services/google_sheets_service.dart';
```

## Architecture Patterns

### Model Layer (`lib/models/`)
```dart
class ExampleModel {
  final String id;
  final String name;
  final DateTime createdAt;

  const ExampleModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  // Immutable copy method
  ExampleModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return ExampleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ExampleModel.fromJson(Map<String, dynamic> json) => ExampleModel(
    id: json['id'],
    name: json['name'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  // Equality override for proper comparison
  @override
  bool operator ==(Object other) => /* equality logic */;
  
  @override
  int get hashCode => /* hash logic */;
}
```

### Service Layer (`lib/services/`)
```dart
class ExampleService {
  static Future<List<ExampleModel>> getData() async {
    try {
      final filePath = await _getFilePath();
      final file = File(filePath);
      
      if (!await file.exists()) {
        return _getDefaultData();
      }

      final content = await file.readAsString(encoding: utf8);
      // Parse and return data
    } catch (e) {
      debugPrint('Error loading data: $e');
      rethrow; // Let UI handle the error
    }
  }

  static Future<void> saveData(List<ExampleModel> data) async {
    // Save logic with proper error handling
  }

  static List<ExampleModel> _getDefaultData() {
    // Provide sensible defaults
  }
}
```

### UI Layer Patterns

#### State Management
```dart
class _ScreenState extends State<ScreenWidget> {
  bool _isLoading = false;
  List<DataModel> _data = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await DataService.getData();
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }
}
```

#### Widget Building
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Screen Title'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchData,
        ),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildContent(),
        ],
      ),
    ),
  );
}

Widget _buildHeader() {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildForm(),
    ),
  );
}
```

## Error Handling

### Standard Pattern
```dart
try {
  // Async operation
  final result = await SomeService.getData();
  
  if (!mounted) return; // Always check widget lifecycle
  
  setState(() {
    // Update state
  });
} catch (e) {
  debugPrint('Error in operation: $e');
  
  if (!mounted) return;
  
  // User feedback
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Operation failed: $e')),
  );
  
  // Optional: Reset state
  setState(() {
    _isLoading = false;
  });
}
```

## Data Management

### CSV Handling (Exercise Records)
```dart
const List<String> _csvHeaders = ['Date', 'Start Time', 'End Time', 'Duration', 'TaskType', 'Notes'];

// Write with UTF-8 BOM for Excel compatibility
final utf8Bom = [0xEF, 0xBB, 0xBF];
final csvBytes = utf8.encode(csvString);
Uint8List fileBytesWithBom = Uint8List.fromList(utf8Bom + csvBytes);

// Parse with explicit configuration
final csvList = const CsvToListConverter(
  fieldDelimiter: ',', 
  eol: '\n', 
  shouldParseNumbers: false
).convert(csvString);
```

### JSON Handling (Configuration)
```dart
// Service-level operations
final List<Map<String, dynamic>> jsonList = data.map((item) => item.toJson()).toList();
final jsonString = json.encode(jsonList);
await file.writeAsString(jsonString, encoding: utf8);
```

## Internationalization

### Hebrew/RTL Support
- Set locale in MaterialApp: `locale: const Locale('he', 'IL')`
- Use `TextDirection.rtl` for form fields: `textDirection: TextDirection.rtl`
- Mixed UI languages are acceptable (Hebrew labels, English code)

## Testing

### Test Structure
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_flutter_exercisetracker/main.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('Widget renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      
      expect(find.byType(ScreenWidget), findsOneWidget);
      expect(find.text('Expected Text'), findsOneWidget);
    });

    testWidgets('User interaction works', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      
      expect(find.text('New State Text'), findsOneWidget);
    });
  });
}
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── exercise_record.dart      # Exercise tracking data
│   └── task_type.dart          # Task type definitions
├── services/                    # Data management
│   ├── local_file_service.dart  # CSV file operations
│   └── task_type_service.dart   # Task type management
└── admin_page.dart             # Admin interface
```

## Key Principles

1. **Separation of Concerns:** Models, services, and UI are distinct layers
2. **Immutable State:** Use `copyWith` for state updates
3. **Error First Design:** Always handle errors gracefully with user feedback
4. **Internationalization Ready:** Built-in Hebrew/RTL support
5. **Local First:** Primary storage is local files (CSV for data, JSON for config)
6. **User Experience:** Loading states, error messages, and intuitive interactions

## Dependencies

When adding new dependencies:
1. Check if existing Flutter core packages can solve the problem first
2. Add to `pubspec.yaml` under appropriate section
3. Run `flutter pub get`
4. Test on target platforms before committing

## Git Workflow

1. Commit frequently with clear messages
2. Test before pushing
3. Use feature branches for significant changes
4. Keep `main` branch stable at all times

## Performance Considerations

- Use computed properties for derived state (`get _filteredRecords`)
- Implement proper loading states
- Avoid unnecessary widget rebuilds
- Use `const` widgets where possible
- Consider pagination for large datasets (>100 records)