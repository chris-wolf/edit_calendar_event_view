
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/cupertino.dart';

import 'edit_calendar_event_page.dart';
import 'edit_calendar_event_view_method_channel.dart';
import 'edit_calendar_event_view_platform_interface.dart';

 class EditCalendarEventView {

   /// Adds or edits a calendar event and returns the event id.
   /// If [eventId] is provided, the existing event will be edited. Otherwise, a new event will be created.
   /// [calendarId] is the ID of the calendar to add or edit the event on.
   /// [title] is the title of the event.
   /// [description] is the description of the event.
   /// [startDate] is the start date and time of the event.
   /// [endDate] is the end date and time of the event.
   /// [allDay] does the event last all day
   ///
   /// Returns the event ID of the newly created or edited event as a string.
  static Future<({ResultType resultType, Event? event})> addOrEditCalendarEvent(BuildContext context,{String? calendarId, String? eventId, String? title, String? description, int? startDate, int? endDate, bool?  allDay, DatePickerType? datePickerType, List<Calendar>? availableCalendars, Event? event, EventColor? eventColor, List<Reminder>? reminders}) async {
    return EditCalendarEventViewPlatform.instance.addOrEditCalendarEvent(context,
      calendarId: calendarId,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      allDay: allDay,
      datePickerType: datePickerType,
      availableCalendars: availableCalendars,
      event: event,
        eventColor: eventColor,
        reminders: reminders,
    );
  }
}
