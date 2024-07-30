import 'dart:io';

import 'package:device_calendar/device_calendar.dart';
import 'package:edit_calendar_event_view/edit_calendar_event_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'edit_calendar_event_view_platform_interface.dart';

enum ResultType {
  saved,
  deleted,
  unknown,
  canceled
}

/// An implementation of [EditCalendarEventViewPlatform] that uses method channels.
class MethodChannelEditCalendarEventView extends EditCalendarEventViewPlatform {
  /// The method channel used to interact with the native platform.
  final methodChannel = const MethodChannel('edit_calendar_event_view');


  @override
  Future<({ResultType resultType, String? eventId})> addOrEditCalendarEvent(BuildContext context, {String? calendarId, String? eventId, String? title, String? description, int? startDate, int? endDate, bool?  allDay}) async {
      if (((await DeviceCalendarPlugin().hasPermissions()).data == true || (await DeviceCalendarPlugin().requestPermissions()).data == true) && context.mounted) {
        var result = await EditCalendarEventPage.show(context, calendarId: calendarId, eventId: eventId, title: title, description: description, startDate: startDate, endDate: endDate, allDay: allDay, datePickerType: DatePickerType.cupertino);
        return result as ({ResultType resultType, String? eventId})? ?? (resultType: ResultType.canceled, eventId: eventId);
      } else {
        return  (resultType: ResultType.canceled, eventId: eventId);
      }
    }
}
