import 'package:device_calendar/device_calendar.dart';

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

}
