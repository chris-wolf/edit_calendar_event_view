import 'package:device_calendar/device_calendar.dart';
import 'package:edit_calendar_event_view/extensions.dart';
import 'package:flutter/material.dart';
import 'edit_calendar_event_page.dart';

class CalendarSelectionDialog {
  static Future<Calendar?> showCalendarDialog(
    BuildContext context,
    String title,
    String? notSetString,
    List<Calendar> calendars,
    Calendar? selected,
  ) async {

    return showDialog<Calendar>(
      context: context,
      builder: (BuildContext context) {
        final startIndex = notSetString == null ? 0 : 1;
        return AlertDialog(
          backgroundColor: EditCalendarEventPage.backgroundColor,
          title: Text(title),
          contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: calendars.length + startIndex,
              itemBuilder: (BuildContext context, int index) {
                final calendar = calendars.atIndexOrNull(index - startIndex);
                return RadioListTile<Calendar?>.adaptive(
                  title: Row(
                    children: [
                      if (calendar != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Container(
                            alignment: Alignment.center,
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(calendar.color ?? 0)),
                          ),
                        ),
                      Text(calendar?.name ?? notSetString ?? '')
                    ],
                  ),
                  value: calendar,
                  groupValue: selected,
                  onChanged: (Calendar? value) {
                    if (value == null) {
                      Navigator.pop(context, Calendar());
                    } else {
                      Navigator.pop(context, value);
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
