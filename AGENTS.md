# AGENTS.md — Guidelines For Autonomous Agents

This repository is a Flutter app (Exercise Tracker). This file tells agentic coding
agents how to build, test, lint and follow the project's conventions. Keep changes
small and follow the patterns below.

1. Development commands

- Analyze code: `flutter analyze`
- Install deps: `flutter pub get`
- Run all tests: `flutter test`
- Run a single test file: `flutter test test/widget_test.dart` (or `flutter test test/<path>.dart`)
- Run a single test by name: `flutter test --name "My test name"`
- Run app locally (choose device): `flutter run -d windows` or `-d android` or `-d ios`
- Build for release: `flutter build windows|android|ios`
- Clean build artifacts: `flutter clean`

Formatting & linting

- Format: `dart format .`
- Auto-fix lints: `dart fix --apply`
- Keep the analyzer warnings clean; prefer fixing issues over ignoring them.

2. Project structure and naming

- Top-level layout:
  - `lib/main.dart` — app entry
  - `lib/models/` — immutable plain data models (JSON + copyWith)
  - `lib/services/` — file, persistence and external API logic
  - `lib/admin_page.dart` — admin UI

- Filenames: snake_case.dart (e.g., `exercise_record.dart`)
- Classes: PascalCase (e.g., `ExerciseRecord`)
- Variables & fields: camelCase; private fields start with `_` (e.g., `_isLoading`)
- Methods: camelCase; private methods start with `_` (handler methods `_handle*`, builders `_build*`, fetchers `_fetch*`)
- Constants: UPPER_SNAKE_CASE (e.g., `CSV_HEADERS` or `_CSV_HEADERS` if private)
- Booleans: use `is` / `has` prefix (e.g., `isActive`, `_hasActiveFilters`)

3. Import organization

- Order imports in three groups separated by a blank line:
  1. Flutter / Dart core (e.g. `package:flutter/material.dart`)
  2. Third-party packages (alphabetical)
  3. Project imports (alphabetical)

Example:

```dart
import 'package:flutter/material.dart';

import 'package:csv/csv.dart';

import 'package:my_flutter_exercisetracker/models/exercise_record.dart';
import 'package:my_flutter_exercisetracker/services/local_file_service.dart';
```

4. Models

- Models are immutable `const` classes where possible and implement `toJson()` / `fromJson()` and `copyWith()`.
- Use `DateTime` in UTC or ISO strings for serialization. Provide clear equality (`==`) and `hashCode` overrides.

5. Services

- Services handle IO, parsing and external APIs. They should:
  - Live under `lib/services/`
  - Use `Future` and `async`/`await`
  - Catch errors, log with `debugPrint`, and rethrow when the UI must decide how to notify the user
  - Keep side effects (file writes, network calls) centralized

Example error pattern:

```dart
try {
  final content = await file.readAsString(encoding: utf8);
} catch (e, st) {
  debugPrint('Failed reading file: $e\n$st');
  rethrow;
}
```

6. UI patterns

- Stateful widgets must check `if (!mounted) return;` after awaits before calling `setState`.
- Use small builder methods (`_buildHeader()`, `_buildRecordsTable()`) to keep `build()` readable.
- Favor `const` widgets when values are compile-time constant.

7. Error handling and user feedback

- Surface recoverable errors to the user via `ScaffoldMessenger.of(context).showSnackBar(...)`.
- Log details with `debugPrint` (include stack traces where helpful).
- Do not swallow exceptions silently; prefer rethrowing after logging so callers can react.

8. Data handling

- CSV: write with UTF-8 BOM for Excel compatibility when exporting. Parse with an explicit converter.
- JSON: store configuration as JSON using `json.encode`/`json.decode` and `File.writeAsString(..., encoding: utf8)`.

9. Tests

- Tests live under `test/` and use `flutter_test`.
- Run a single file: `flutter test test/widget_test.dart`.
- Run tests matching a name: `flutter test --name "partial test name"`.
- Tests should avoid hitting real file system/network. Use dependency injection or mocks for services.

10. Internationalization

- App supports RTL; set `locale` on `MaterialApp` (e.g., `Locale('he', 'IL')`). Use `TextDirection.rtl` where necessary.

11. Cursor / Copilot rules

- No `.cursor` rules or `.cursorrules` were found in the repository root.
- No `.github/copilot-instructions.md` was found. Agents should follow this AGENTS.md and standard GitHub Copilot behavior.

12. Adding dependencies

- Prefer Flutter/Dart core packages first. Add new dependencies to `pubspec.yaml` and run `flutter pub get`.
- Keep dependency upgrades small and test on target platforms before committing.

13. Git workflow for agents

- Do not push changes without human approval unless explicitly asked.
- Use feature branches for larger work and create clean commits with explanatory messages.

14. Safety and tips for autonomous edits

- Never delete or revert changes not introduced by you unless asked.
- Avoid destructive Git operations (`reset --hard`, force-push) unless user explicitly requests.

If you need more detailed rules (formatters, linters, or pre-commit hooks), open an issue or add project configuration files (`analysis_options.yaml`, `.editorconfig`, pre-commit hooks) and update this document.

Happy coding — keep changes small, tested and well-logged.
