import 'dart:io';

import 'package:device_calendar/device_calendar.dart';
import 'package:edit_calendar_event_view/edit_calendar_event_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'edit_calendar_event_view_platform_interface.dart';

enum ResultType {
  saved,
  deleted,
  canceled
}

/// An implementation of [EditCalendarEventViewPlatform] that uses method channels.
class MethodChannelEditCalendarEventView extends EditCalendarEventViewPlatform {
  /// The method channel used to interact with the native platform.
  final methodChannel = const MethodChannel('edit_calendar_event_view');


  @override
  Future<({ResultType resultType, Event? event})> addOrEditCalendarEvent(BuildContext context, {String? calendarId, String? title, String? description, int? startDate, int? endDate, bool?  allDay, List<Calendar>? availableCalendars, DatePickerType? datePickerType, Event? event, EventColor? eventColor, List<Reminder>? reminders}) async {
      if (((await DeviceCalendarPlugin(shouldInitTimezone: false).hasPermissions()).data == true || (await DeviceCalendarPlugin(shouldInitTimezone: false).requestPermissions()).data == true) && context.mounted) {
        var result = await EditCalendarEventPage.show(context, calendarId: calendarId,  title: title, description: description, startDate: startDate, endDate: endDate, allDay: allDay, datePickerType: datePickerType, availableCalendars: availableCalendars, event: event,
            eventColor: eventColor,
            reminders: reminders);
        return result as ({ResultType resultType, Event? event})? ?? (resultType: ResultType.canceled, event: event);
      } else {
        return  (resultType: ResultType.canceled, event: event);
      }
    }
}
