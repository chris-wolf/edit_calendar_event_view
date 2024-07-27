import 'package:device_calendar/device_calendar.dart';
import 'package:edit_calendar_event_view/string_extensions.dart';

enum RecurrenceFrequency {
  Daily,
  Weekly,
  Monthly,
  Yearly;



  Frequency toFrequency() {
    switch(this) {

      case RecurrenceFrequency.Daily:
        return Frequency.daily;
      case RecurrenceFrequency.Weekly:
        return Frequency.weekly;
      case RecurrenceFrequency.Monthly:
        return Frequency.monthly;
      case RecurrenceFrequency.Yearly:
        return Frequency.yearly;
    }
  }

  String localize(int? inverval) {
    String string = name;

    if (inverval != null) {
      switch(this) {
        case RecurrenceFrequency.Daily:
          string = 'day';
        case RecurrenceFrequency.Weekly:
          string = 'week';
        case RecurrenceFrequency.Monthly:
          string = 'month';
        case RecurrenceFrequency.Yearly:
          string = 'year';
      }
      if (inverval != 1) {
        string = '${string}s';
      }
    }
    return string.localize();
  }

}
