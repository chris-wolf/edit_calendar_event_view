
import 'edit_event_localization.dart';

extension StringExtensions on String {
  String localize() {
    return EditEventLocalization.localize(this);
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
