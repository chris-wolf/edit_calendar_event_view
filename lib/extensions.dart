

import 'package:device_calendar/device_calendar.dart';
import 'package:edit_calendar_event_view/string_extensions.dart';
import 'package:edit_calendar_event_view/time_unit.dart';
import 'package:sprintf/sprintf.dart';

extension ListExtensions<T> on List<T> {
  T? firstOrNull() {
    try {
      return first;
    } catch (e) {
      return null;
    }
  }

  T? atIndexOrNull(int index) {
    try {
      return this[index];
    } catch (e) {
      return null;
    }
  }

  List<List<T>> splitWhere(bool Function(T element) predicate) {
    List<List<T>> result = [];
    List<T> currentList = [];
    for (T element in this) {
      if (predicate(element)) {
        result.add(currentList);
        currentList = [];
      } else {
        currentList.add(element);
      }
    }
    result.add(currentList);
    return result;
  }
}

extension DateTimeExtension on DateTime {
  bool isBeforeOrSame(DateTime date) {
    return !isAfter(date);
  }

  bool isAfterOrSame(DateTime date) {
    return !isBefore(date);
  }

  bool isBeforeOrSameDay(DateTime date) {
    return year < date.year ||
        year == date.year &&
            (month < date.month || month == date.month && day <= date.day);
  }

  bool isSameDay(DateTime date) {
    return year == date.year && month == date.month && day == date.day;
  }

  bool isAfterOrSameDay(DateTime date) {
    return year > date.year ||
        year == date.year &&
            (month > date.month || month == date.month && day >= date.day);
  }

  bool isBeforeDay(DateTime date) {
    return year < date.year ||
        year == date.year &&
            (month < date.month || month == date.month && day < date.day);
  }

  DateTime beginningOfDay() {
    return DateTime(year, month, day);
  }

  DateTime endOfDay() {
    return DateTime(
        year,
        month,
        day,
        23,
        59,
        59,
        999);
  }

  DateTime beginningOfMonth() {
    return DateTime(year, month, 1);
  }
}


extension TimeUnitExtension on TimeUnit {
  int inMinutes() {
    switch (this) {
      case TimeUnit.minutes:
        return 1;
      case TimeUnit.hours:
        return 60; // 60 minutes in an hour
      case TimeUnit.days:
        return 1440; // 24 hours * 60 minutes
      case TimeUnit.weeks:
        return 10080; // 7 days * 24 hours * 60 minutes
    }
  }
}



extension ReminderExtension on Reminder {
  String title() {
    String resultString = "";
    int minutes = this.minutes ?? 0;
    for (final timeUnit in TimeUnit.values.reversed) {
      final timeUnitMinutes = timeUnit.inMinutes();
      if (minutes >= timeUnitMinutes) {
        final count = minutes ~/ timeUnitMinutes;
        resultString += sprintf(
            "${count == 1 ? '1' : 'n'}_${timeUnit.name}".localize(), [count]);
        minutes = minutes % timeUnitMinutes;
      }
    }
    return sprintf('s_before'.localize(), [resultString.trim()]);
  }
}
