# Workspace Customization Rules

- **Targeted Testing**: Only run tests relevant to the specific pages, components, or logic files that were changed during a task (e.g., `flutter test test/path/to/specific_test.dart`). Do not run the full test suite.
- **No Direct Reading or Editing of `localized_map.dart`**: NEVER read, search through, or modify `lib/common/localized_map.dart` directly. When adding or updating localized strings, ONLY ADD THE ROW INTO localization.csv AND ONLY WRITE VALUES FOR KEY, CONTEXT, EN!!!.
