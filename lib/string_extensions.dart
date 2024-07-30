
import 'edit_event_localization.dart';

extension StringExtensions on String {
  String localize({String? testLocale}) {
    return EditEventLocalization.localize(this, testLocale: testLocale);
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
