import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:edit_calendar_event_view/color_picker_dialog.dart';
import 'package:edit_calendar_event_view/event_attendee_page.dart';
import 'package:edit_calendar_event_view/extensions.dart';
import 'package:edit_calendar_event_view/recurrency_frequency.dart';
import 'package:edit_calendar_event_view/string_extensions.dart';
import 'package:edit_calendar_event_view/time_unit.dart';
import 'package:edit_calendar_event_view/time_zone_search_delegate.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:sprintf/sprintf.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'calendar_selection_dialog.dart';
import 'common/constants.dart';
import 'custom_recurrency_page.dart';
import 'edit_calendar_event_view_method_channel.dart';
import 'multi_platform_dialog.dart';
import 'multi_platform_scaffold.dart';


enum DatePickerType {
  material,
  cupertino
}

class EditCalendarEventPage extends StatefulWidget {
  static String? currentTimeZone;

  static Future<dynamic> show(BuildContext context,
      {String? calendarId,
        String? eventId,
        Event? event,
      String? title,
      String? description,
      int? startDate,
      int? endDate,
      bool? allDay, DatePickerType? datePickerType}) async {
    if (EditCalendarEventPage.currentTimeZone == null) {
      tz.initializeTimeZones();
      currentTimeZone = await FlutterTimezone.getLocalTimezone();
    }
    List<Calendar> calendars =
        (await DeviceCalendarPlugin().retrieveCalendars()).data?.toList() ?? [];
    if (eventId != null) {
      if (calendarId != null) {
        event = (await DeviceCalendarPlugin().retrieveEvents(
                calendarId, RetrieveEventsParams(eventIds: [eventId])))
            .data
            ?.firstOrNull();
      }
      if (event == null) {
        for (final cal in calendars) {
          final events = await DeviceCalendarPlugin().retrieveEvents(
              cal.id, RetrieveEventsParams(eventIds: [eventId]));
          final evnt = events.data?.firstOrNull();
          if (evnt != null) {
            event = evnt;
            break;
          }
        }
      }
    }
    calendars =
        calendars.where((element) => element.isReadOnly == false).toList();

    Calendar? calendar;

    if (calendarId != null) {
      calendar =
          calendars.firstWhereOrNull((element) => element.id == calendarId);
    }
    if (calendar == null && event?.calendarId != null) {
      calendar = calendars
          .firstWhereOrNull((element) => element.id == event?.calendarId);
    }
    calendar ??= calendars.firstWhereOrNull((element) =>
        !(element.isReadOnly ?? true) && (element.isDefault ?? false));
    calendar ??=
        calendars.firstWhereOrNull((element) => !(element.isReadOnly ?? true));
    if (!context.mounted) {
      return;
    }
    final page = EditCalendarEventPage(
      event: event,
      calendar: calendar,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      allDay: allDay,
      datePickerType: datePickerType ?? DatePickerType.material
    );
    if (MacosTheme.maybeOf(context) != null) {
      return MultiPlatformDialog.show(context, page,
          barrierDismissible: true, maxWidth: 500, maxHeight: 548);
    } else {
      return Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    }
  }

  final Event? event;
  final Calendar? calendar;
  final String? title;
  final String? description;
  final int? startDate;
  final int? endDate;
  final bool? allDay;
  final DatePickerType datePickerType;

  const EditCalendarEventPage(
      {super.key,
      this.event,
      this.calendar,
      this.title,
      this.description,
      this.startDate,
      this.endDate,
      this.allDay,
      required this.datePickerType
      });

  @override
  _EditCalendarEventPageState createState() => _EditCalendarEventPageState();
}

class _EditCalendarEventPageState extends State<EditCalendarEventPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  late Event event;

  final horizontalPadding = 16.0;
  Calendar? calendar;

  FocusNode? titleFocusNode;
  FocusNode descriptionFocusNode = FocusNode();
  FocusNode locationFocusNode = FocusNode();
  FocusNode websiteFocusNode = FocusNode();
  List<EventColor> eventColors = [];

  @override
  void initState() {
    super.initState();
    print(tz.local);
    tz.setLocalLocation(
        tz.getLocation(EditCalendarEventPage.currentTimeZone ?? 'UTC'));
    print(tz.local);
    calendar = widget.calendar;
    if (widget.event != null) {
      event = widget.event!;
    } else {
      event = Event(widget.calendar?.id,
          start: TZDateTime.from(DateTime.now(), tz.local),
          end: TZDateTime.from(
              DateTime.now().add(const Duration(hours: 1)), tz.local));
    }
    if (widget.title != null) {
      event.title = widget.title;
    }
    if (widget.description != null) {
      event.description = widget.description;
    }
    if (widget.allDay != null) {
      event.allDay = widget.allDay;
    }
    if (widget.startDate != null) {
      event.start = epochMillisToTZDateTime(widget.startDate!);
    }
    if (widget.endDate != null) {
      event.end = epochMillisToTZDateTime(widget.endDate!);
    }
    if (calendar != null) {
      event.calendarId = calendar?.id;
    }
    _titleController.text = event.title ?? '';
    _descriptionController.text = event.description ?? '';
    _locationController.text = event.location ?? '';
    _websiteController.text = event.url?.toString() ?? '';
    loadEventColors();
    if (calendar?.isReadOnly ?? false) {
      Future.delayed(const Duration(milliseconds: 100)).then((_) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('read_only_event'.localize()), duration: const Duration(seconds: 60))));
    }
  }

  void loadEventColors() {
    if (calendar != null) {
      DeviceCalendarPlugin().retrieveEventColors(calendar!).then((eventColors) {
        setState(() {
          this.eventColors = eventColors ?? [];
        });
      });
    }
  }

  TZDateTime epochMillisToTZDateTime(int epochMillis) {
    // Initialize timezone data; required if you haven't done it elsewhere in your app.
    // Convert epoch milliseconds to a DateTime object.
    final dateTime = DateTime.fromMillisecondsSinceEpoch(epochMillis);
    // Convert DateTime to TZDateTime in the local timezone.
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  Color? buttonTextColor;

  @override
  Widget build(BuildContext context) {


    buttonTextColor ??= Theme.of(context).primaryColor;
    final title =
        (widget.event == null ? 'add_event' : 'edit_event').localize();
    return PopScope(
      canPop: true,
      onPopInvoked : (didPop){
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    },
      child: MultiPlatformScaffold(
          title: title,
          macOsLeading: MacosIconButton(
            icon: const Icon(Icons.close, color: Color(0xff808080)),
            onPressed: () => Navigator.pop(context),
            padding: const EdgeInsets.all(5.0),
          ),
          actions: [
            if (widget.event != null)
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: IconButton(
                  icon: const Icon(
                    Icons.delete,
                  ),
                  tooltip: 'delete'.localize(),
                  onPressed: () async {
                    await deleteEvent(context);
                  },
                ),
              ),
          ],
          macOsActions: [
            if (widget.event != null)
              ToolBarIconButton(
                  label: 'delete'.localize(),
                  icon: const MacosIcon(
                    CupertinoIcons.delete,
                  ),
                  onPressed: () {
                    deleteEvent(context);
                  },
                  showLabel: false),
          ],
          body: Stack(
            children: [
              content(),
              if (MacosTheme.maybeOf(context) != null)
                Positioned(
                  right: 16.0,
                  bottom: 16.0,
                  child: PushButton(
                    controlSize: ControlSize.large,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 5.0),
                    child: Text('save'.localize()),
                    onPressed: () {
                      confirmPress(context);
                    },
                  ),
                ),
            ],
          ),
          floatingActionButton: calendar?.isReadOnly ?? false ? null : FloatingActionButton(
            tooltip: 'save'.localize(),
            onPressed: () async {
              await confirmPress(context);
            },
            backgroundColor: Colors.green,
            child: const Icon(
              Icons.check,
              color: Colors.white,
            ),
          )),
    );
  }

  Future<void> deleteEvent(BuildContext context) async {
    final event = widget.event;
    if (event != null) {
      DeviceCalendarPlugin().deleteEvent(event.calendarId, event.eventId);
      Navigator.pop(
          context, (resultType: ResultType.deleted, eventId: event.eventId));
    }
  }

  DateTime startDate() {
    return DateTime.fromMillisecondsSinceEpoch(
        event.start?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch);
  }

  DateTime endDate() {
    return DateTime.fromMillisecondsSinceEpoch(
        event.end?.millisecondsSinceEpoch ??
            startDate().add(const Duration(hours: 1)).millisecondsSinceEpoch);
  }

  bool allDay() {
    return event.allDay ?? false;
  }
  FocusNode contentFocusNode = FocusNode();

  Widget content() {
    return RawKeyboardListener(
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.enter) {
                confirmPress(context);
            }
          }
        },
        focusNode: contentFocusNode,
        child: Builder(builder: (context) {
          return Container(
              constraints: const BoxConstraints.expand(),
              child:  SingleChildScrollView(
                    child: AbsorbPointer(
                      absorbing: calendar?.isReadOnly ?? false,
                      child: Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                        child: Column(
                            children: <Widget>[
                              Card(
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8.0))),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(horizontalPadding),
                                      child: TextFormField(
                                        controller: _titleController,
                                        maxLines: 1,
                                        focusNode: event.title == null ? titleFocusNode ??= (FocusNode()..requestFocus()) : null,
                                        decoration: InputDecoration.collapsed(
                                            hintText: 'event_title'.localize(),
                                            hintStyle:
                                                const TextStyle(color: Colors.grey),
                                            border: InputBorder.none),
                                      ),
                                    ),
                                    divider(),
                                    Padding(
                                      padding: EdgeInsets.all(horizontalPadding),
                                      child: TextFormField(
                                        focusNode: descriptionFocusNode,
                                        controller: _descriptionController,
                                        maxLines: 100,
                                        minLines: 1,
                                        maxLengthEnforcement:
                                            MaxLengthEnforcement.enforced,
                                        decoration: InputDecoration.collapsed(
                                            hintText: 'event_description'.localize(),
                                            hintStyle:
                                                const TextStyle(color: Colors.grey),
                                            border: InputBorder.none),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Card(
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8.0))),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                        leading: const Icon(Icons.access_time_rounded),
                                        title: Row(
                                          children: <Widget>[
                                            Expanded(child: Text('all_day'.localize())),
                                            Switch.adaptive(
                                              value: allDay(),
                                              onChanged: (bool value) {
                                                setState(() {
                                                  event.allDay = value;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        onTap: () {
                                          setState(() {
                                            event.allDay = !allDay();
                                          });
                                        }),
                                    if (widget.datePickerType == DatePickerType.cupertino)
                                    SizedBox(
                                      height: 96,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 64,
                                            alignment: Alignment.center,
                                            child: Text('${'event_begin'.localize()}:', style: const TextStyle(fontSize: 16),),
                                          ),
                                          Expanded(
                                            child: CupertinoDatePicker(
                                                key: ValueKey((allDay(), updatedStartDate?.hashCode)),
                                                mode: allDay() ? CupertinoDatePickerMode.date : CupertinoDatePickerMode.dateAndTime,
                                                initialDateTime: startDate(),
                                                onDateTimeChanged: (dateTime) {
                                                  setStartDate(dateTime, null, null);
                                                }),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (widget.datePickerType == DatePickerType.cupertino)
                                      SizedBox(
                                        height: 96,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 64,
                                              alignment: Alignment.center,
                                              child: Text('${'event_end'.localize()}:', style: const TextStyle(fontSize: 16),),
                                            ),
                                            Expanded(
                                              child: CupertinoDatePicker(
                                                  key: ValueKey((allDay(), updatedEndDate?.hashCode)),
                                                  mode: allDay() ? CupertinoDatePickerMode.date : CupertinoDatePickerMode.dateAndTime,
                                                  initialDateTime: endDate(),
                                                  onDateTimeChanged: (dateTime) {
                                                    setEndDate(dateTime, null, null);
                                                  }),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (widget.datePickerType == DatePickerType.material)
                                    ListTile(
                                      title: Row(
                                        children: [
                                          const SizedBox(width: 26),
                                          TextButton(
                                              onPressed: () async {
                                                await startDatePicker(context);
                                              },
                                              child: Text(
                                                  DateFormat('EEE, MMM d, yyyy')
                                                      .format(startDate()),
                                                  style: const TextStyle(fontSize: 16))),
                                          const Expanded(
                                            child: SizedBox(),
                                          ),
                                          if (allDay() == false)
                                            TextButton(
                                                onPressed: () {
                                                  setStartTime(context);
                                                },
                                                child: Text(
                                                    DateFormat('h:mm a')
                                                        .format(startDate()),
                                                    style:
                                                        const TextStyle(fontSize: 16))),
                                        ],
                                      ),
                                      onTap: () async {
                                        await startDatePicker(context);
                                      },
                                    ),
                                    if (widget.datePickerType == DatePickerType.material)
                                    ListTile(
                                      title: Row(
                                        children: [
                                          const SizedBox(width: 26),
                                          TextButton(
                                              onPressed: () async {
                                                await endDatePicker(context);
                                              },
                                              child: Text(
                                                  DateFormat('EEE, MMM d, yyyy')
                                                      .format(endDate()),
                                                  style: const TextStyle(fontSize: 16))),
                                          const Expanded(
                                            child: SizedBox(),
                                          ),
                                          if (allDay() == false)
                                            TextButton(
                                              onPressed: () {
                                                setEndTime(context);
                                              },
                                              child: Text(
                                                  DateFormat('h:mm a').format(endDate()),
                                                  style: const TextStyle(fontSize: 16)),
                                            ),
                                        ],
                                      ),
                                      onTap: () async {
                                        await endDatePicker(context);
                                      },
                                    ),
                                    ListTile(
                                        leading: const Icon(Icons.refresh),
                                        title: Text(
                                            event.recurrenceRule == null
                                                ? 'repeat_once'.localize()
                                                : getRRuleString(event.recurrenceRule),
                                            style: const TextStyle(fontSize: 16)),
                                        onTap: () async {
                                          selectRecurrenceRule();
                                        }),
                                  ],
                                ),
                              ),
                              Card(
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8.0))),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ListTile(
                                            title: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Expanded(
                                                  child: Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Icon(Icons.calendar_month)),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(right: 4.0),
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    width: 10,
                                                    height: 10,
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color:
                                                            Color(calendar?.color ?? 0)),
                                                  ),
                                                ),
                                                Text(calendar?.name ??
                                                    'select_calendar'.localize()),
                                              ],
                                            ),
                                            onTap: () async {
                                              final calendars =
                                                  (await DeviceCalendarPlugin()
                                                              .retrieveCalendars())
                                                          .data
                                                          ?.where((element) =>
                                                              element.isReadOnly == false)
                                                          .toList() ??
                                                      [];
                                              if (!context.mounted) {
                                                return;
                                              }
                                              var result = await CalendarSelectionDialog
                                                  .showCalendarDialog(
                                                      context,
                                                      'select_calendar'.localize(),
                                                      null,
                                                      calendars,
                                                      calendars.firstWhereOrNull(
                                                          (element) =>
                                                              element.id ==
                                                              calendar?.id));
                                              if (result?.id != null) {
                                                setState(() {
                                                  calendar = result;
                                                  event.calendarId = result?.id;
                                                  event.updateEventColor(null);
                                                  loadEventColors();
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    if(eventColors.isNotEmpty)
                                      divider(),
                                    if(eventColors.isNotEmpty)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ListTile(
                                            title: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Expanded(
                                                  child: Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Icon(Icons.color_lens_outlined)),
                                                ),
                                                Text('${'event_color'.localize()}:'),
                                                SizedBox(width: 4,),
                                                if ((event.color ?? 0) != 0)
                                                Container(
                                                    alignment: Alignment.center,
                                                    width: 15,
                                                    height: 15,
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color:
                                                        Color(event.color ?? 0)),
                                                ),
                                                if ((event.color ?? 0) == 0)
                                                Text('not_set'.localize()),
                                              ],
                                            ),
                                            onTap: () async {
                                              final color = await ColorPickerDialog.selectColorDialog(eventColors.map((eventColor) => Color(eventColor.color)).toList(), context);
                                              final eventColor = eventColors.firstWhereOrNull((eventColor) => Color(eventColor.color) == color);
                                              if (eventColor != null) {
                                                setState(()  {
                                                   event.updateEventColor(eventColor);
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    divider(),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.fromLTRB(16, 16, 0, 20),
                                          child: Icon(Icons.alarm),
                                        ),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              for (final reminder
                                                  in event.reminders ?? [])
                                                ListTile(
                                                  title: Text(alarmTitle(reminder)),
                                                  trailing: IconButton(
                                                    icon: Icon(
                                                      semanticLabel: 'remove_reminder'.localize(),
                                                      Icons.close_rounded,
                                                      color: buttonTextColor,
                                                    ),
                                                    onPressed: () {
                                                      List<Reminder> newReminders = [
                                                        ...(event.reminders ?? [])
                                                      ];
                                                      newReminders.remove(reminder);
                                                      setState(() {
                                                        event.reminders = newReminders;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ListTile(
                                                title: Text(
                                                  'add_reminder'.localize(),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(color: buttonTextColor),
                                                ),
                                                onTap: () async {
                                                  addReminder();
                                                },
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              Card(
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8.0))),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.fromLTRB(16, 16, 4  , 20),
                                          child: Icon(Icons.public),
                                        ),
                                        TextButton(
                                            child: Text('${event.start?.timeZoneName} (UTC ${(event.start?.timeZone.offset ?? 0) >= 0 ? '+' : ''}${(event.start?.timeZone.offset ?? 0) ~/ (60 * 60 * 1000)})'),
                                            onPressed: () async {
                                              unFocus();
                                              final timezone = await showSearch(context: context, delegate: TimeZoneSearchDelegate());
                                            if (timezone is MapEntry<String, Location>) {
                                              setState(() {
                                                final start = event.start;
                                                final end = event.end;
                                                if (start != null) {
                                                  event.start = TZDateTime.from(start, timezone.value);
                                                }
                                                if (end != null) {
                                                  event.end = TZDateTime.from(end, timezone.value);
                                                }
                                              });
                                            }
                                            },
                                        )
                                      ],
                                    ),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.fromLTRB(16, 16, 16, 20),
                                          child: Icon(Icons.location_on_outlined),
                                        ),
                                        Expanded(
                                          child: TextFormField(
                                            focusNode: locationFocusNode,
                                            controller: _locationController,
                                            maxLines: 3,
                                            minLines: 1,
                                            maxLengthEnforcement:
                                            MaxLengthEnforcement.enforced,
                                            decoration: InputDecoration.collapsed(
                                                hintText: 'event_location'.localize(),
                                                hintStyle:
                                                const TextStyle(color: Colors.grey),
                                                border: InputBorder.none),
                                          ),
                                        )
                                      ],
                                    ),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.fromLTRB(16, 16, 16, 20),
                                          child: Icon(Icons.web_sharp),
                                        ),
                                        Expanded(
                                          child: TextFormField(
                                            focusNode: websiteFocusNode,
                                            controller: _websiteController,
                                            maxLines: 3,
                                            minLines: 1,
                                            maxLengthEnforcement:
                                            MaxLengthEnforcement.enforced,
                                            decoration: InputDecoration.collapsed(
                                                hintText: 'event_website'.localize(),
                                                hintStyle:
                                                const TextStyle(color: Colors.grey),
                                                border: InputBorder.none),
                                          ),
                                        )
                                      ],
                                    ),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.fromLTRB(16, 16, 4  , 20),
                                          child: Icon(Icons.question_mark),
                                        ),
                                        TextButton(
                                          child: Text(event.status?.enumToString.localize() ?? 'set_status'.localize()),
                                          onPressed: () async {
                                            selectStatus();
                                          },
                                        )
                                      ],
                                    ),

                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.fromLTRB(16, 16, 4  , 20),
                                          child: Icon(Icons.timelapse),
                                        ),
                                        TextButton(
                                          child: Text(event.availability.enumToString.localize()),
                                          onPressed: () async {
                                            selectAvailability();
                                          },
                                        )
                                      ],
                                    ),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.fromLTRB(16, 16, 0, 20),
                                          child: Icon(Icons.group),
                                        ),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              for (final attendee
                                                  in event.attendees ?? [])
                                                ListTile(
                                                  title: Text('${attendee.name} (${Platform.isAndroid ? (attendee.androidAttendeeDetails?.rolee.enumToString.toUpperCase() ?? 'NONE').localize() : attendee.iosAttendeeDetails })'),
                                                  subtitle: Text(attendee.emailAddress),
                                                  trailing: IconButton(
                                                    icon: Icon(
                                                      Icons.close_rounded,
                                                      color: buttonTextColor,
                                                    ),
                                                    onPressed: () {
                                                      List<Attendee> newAttendees = [
                                                        ...(event.attendees?.nonNulls ??
                                                            [])
                                                      ];
                                                      newAttendees.remove(attendee);
                                                      setState(() {
                                                        event.attendees = newAttendees;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ListTile(
                                                title: Text(
                                                  'add_attendee'.localize(),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(color: buttonTextColor),
                                                ),
                                                onTap: () async {
                                                  addAttendee();
                                                },
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 72,)
                            ]),
                      ),
                    ),

              ));
        }));
  }

  void addReminder() async {
    unFocus();
    Reminder? reminder = (await showDialog<Reminder>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            children: <Widget>[
              for (final reminder in defaultAlarmOptions
                  .map((mins) => Reminder(minutes: mins))
                  .where((element) =>
                      event.reminders
                          ?.none((p0) => p0.minutes == element.minutes) ??
                      true))
                SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, reminder);
                  },
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 24.0),
                  child: Text(alarmTitle(reminder)),
                ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, Reminder(minutes: 0));
                },
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 24.0),
                child: Text('custom'.localize()),
              ),
            ],
          );
        }));
    if (!context.mounted) {
      return;
    }
    if (reminder?.minutes == 0) {
      reminder = reminder = (await showDialog<Reminder>(
        context: context,
        builder: (BuildContext context) {
          TextEditingController numberController =
              TextEditingController(text: '10');
          int currentIndex = 0;
          return AlertDialog(
            title: Text('custom'.localize()),
            content: StatefulBuilder(
              builder: (BuildContext context,
                  void Function(void Function()) setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      focusNode: FocusNode()..requestFocus(),
                      controller: numberController,
                      keyboardType: TextInputType.number,
                    ),
                    for (final timeUnit in TimeUnit.values)
                      RadioListTile(
                        title: Text(sprintf('s_before'.localize(), [
                          sprintf("n_${timeUnit.name}".localize(), [0])
                        ]).replaceAll('0', '').trim()),
                        value: TimeUnit.values.indexOf(timeUnit),
                        groupValue: currentIndex,
                        onChanged: (int? value) {
                          setState(() => currentIndex = value ?? 0);
                        },
                      ),
                  ],
                );
              },
            ),
            actions: <Widget>[
              TextButton(
                child: Text('add'.localize()),
                onPressed: () {
                  int number = int.tryParse(numberController.text) ?? 0;
                  Navigator.of(context).pop(Reminder(
                      minutes:
                          number * TimeUnit.values[currentIndex].inMinutes()));
                },
              ),
            ],
          );
        },
      ));
    }
    if (reminder != null) {
      setState(() {
        event.reminders = (event.reminders ?? [])..add(reminder!);
      });
    }
  }

  void selectRecurrenceRule() async {
    unFocus();
    RecurrenceRule? rule = (await showDialog<RecurrenceRule>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(
                      context,
                      RecurrenceRule(
                          frequency: Frequency.daily,
                          interval: 0x7FFFFFFFFFFFFFFF));
                },
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 24.0),
                child: Text('repeat_once'.localize()),
              ),
              for (final recurrency in RecurrenceFrequency.values)
                SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context,
                        RecurrenceRule(frequency: recurrency.toFrequency()));
                  },
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 24.0),
                  child: Text(recurrency.name.localize()),
                ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context,
                      RecurrenceRule(frequency: Frequency.daily, interval: 1));
                },
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 24.0),
                child: Text('custom'.localize()),
              ),
            ],
          );
        }));

    if (rule == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    if (rule.interval == 1) {
      rule = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CustomRecurrencePage(event.start)),
      );
    }
    if (rule?.interval == 0x7FFFFFFFFFFFFFFF) {
      rule = null; // 'once' selected'
    }
    setState(() {
      event.recurrenceRule = rule;
    });
  }

  void setEndTime(BuildContext context) {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(endDate()),
    ).then((time) {
      if (time != null) {
        setState(() {
          event.end = event.end?.add(Duration(
              hours: time.hour - endDate().hour,
              minutes: time.minute - endDate().minute));
          if (endDate().isBefore(startDate())) {
            event.start = event.end?.subtract(Duration(hours: 1));
          }
        });
      }
    });
  }

  void setStartTime(BuildContext context) {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(startDate()),
    ).then((time) {
      if (time != null) {
        setState(() {
          event.start = event.start?.add(Duration(
              hours: time.hour - startDate().hour,
              minutes: time.minute - startDate().minute));
          if (startDate().isAfter(endDate())) {
            event.end = event.start?.add(const Duration(hours: 1));
          }
        });
      }
    });
  }

  Future<void> endDatePicker(BuildContext context) async {
    final hour = event.end?.hour;
    final minutes = event.end?.minute;
    unFocus();
    final newDate = await showDatePicker(
      context: context,
      initialDate: endDate(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(data: Theme.of(context).copyWith(), child: child!);
      },
    );
    if (newDate != null) {
      setEndDate(newDate, hour, minutes);
    }
  }

  void setEndDate(DateTime newDate, int? hour, int? minutes) {
    setState(() {
      event.end = epochMillisToTZDateTime(newDate
          .add(Duration(hours: hour ?? 0, minutes: minutes ?? 0))
          .millisecondsSinceEpoch);
      if (endDate().isBefore(startDate())) {
        event.start = event.end?.add(const Duration(hours: 1));
        updatedStartDate = event.start;
      }
    });
  }

  Future<void> startDatePicker(BuildContext context) async {
    final hour = event.start?.hour;
    final minutes = event.start?.minute;

    unFocus();
    final newDate = await showDatePicker(
      context: context,
      initialDate: endDate(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(data: Theme.of(context).copyWith(), child: child!);
      },
    );
    if (newDate != null) {
      setStartDate(newDate, hour, minutes);
    }
  }

  void setStartDate(DateTime newDate, int? hour, int? minutes) {
    setState(() {
      event.start = epochMillisToTZDateTime(newDate
          .add(Duration(hours: hour ?? 0, minutes: minutes ?? 0))
          .millisecondsSinceEpoch);
      if (endDate().isBefore(startDate())) {
        event.end = event.start?.add(const Duration(hours: 1));
        updatedEndDate = event.end;
      }
    });
  }

  TZDateTime? updatedEndDate;
  TZDateTime? updatedStartDate;

  Widget divider() {
    return Container(
      padding: const EdgeInsets.only(left: 12),
      height: 1,
      width: double.infinity,
      child: ColoredBox(color: Colors.grey.shade300),
    );
  }

  Future confirmPress(BuildContext context) async {
    event.title = _titleController.text;
    event.description = _descriptionController.text;
    event.location = _locationController.text;
    event.url = Uri.tryParse(_websiteController.text ?? '');


    final eventId = await DeviceCalendarPlugin().createOrUpdateEvent(event);
    if (context.mounted) {
      Navigator.pop(
          context, (resultType: ResultType.saved, eventId: eventId?.data));
    }
  }

  String getRRuleString(RecurrenceRule? recurrenceRule) {
    if (recurrenceRule == null) {
      return "repeat_once".localize();
    }

    final StringBuffer buffer = StringBuffer();
    final interval = recurrenceRule.interval ?? 1;

    if (interval > 1) {
      buffer.write("${'every'.localize()} $interval");
    } else {
      buffer.write('${'every'.localize()}');
    }
    switch (recurrenceRule.frequency) {
      case Frequency.daily:
        buffer.write( ' ${(interval == 1 ? "day" : 'days').localize()}');
        break;
      case Frequency.weekly:
        buffer.write(' ${(interval == 1 ? "week" : 'weeks').localize()}');
        final weekdays = recurrenceRule.byWeekDays;
        if (weekdays.isNotEmpty) {
          buffer.write(" on ${weekdays.join(", ")}");
        }
        break;
      case Frequency.monthly:
        buffer.write(' ${(interval == 1 ? "month" : 'months').localize()}');
        final monthDays = recurrenceRule.byMonthDays;
        final bySetPosition = recurrenceRule.bySetPositions;
        final byWeekdays = recurrenceRule.byWeekDays;
        if (monthDays.isNotEmpty) {
          buffer.write(" ${sprintf('on_day_s'.localize(), [monthDays.join(", ")])}");
        } else if (byWeekdays.isNotEmpty) {
          buffer.write(' ${sprintf('on_s'.localize(),[byWeekdays.map((weekDay) => DateFormat.E().format(DateTime(2018,1,1).add(Duration(days: weekDay.day - 1)))).join(", ")])}');
          if (bySetPosition.isNotEmpty) {
            buffer.write(" ${sprintf('for_s'.localize(), [bySetPosition.map((weekNmbr) => '${weekNmbr}_week'.localize()).join(', ')])}");
          }
        }
        break;
      case Frequency.yearly:
        buffer.write(' ${(interval == 1 ? "year" : 'years').localize()}');

        break;
      default:
        return "Unsupported frequency";
    }

    final byMonth = recurrenceRule.byMonths;
    if (byMonth.isNotEmpty) {
      buffer.write(" ${sprintf('in_s'.localize(), [byMonth.map((monthNmbr) => DateFormat.MMM().format(DateTime(2020,monthNmbr, 15))).join(", ")])}");
    }

    if (recurrenceRule.count != null) {
      buffer.write(" ${sprintf('for_n_events'.localize(), [recurrenceRule.count] )}");
    } else if (recurrenceRule.until != null) {
      buffer.write(" ${sprintf('until_s'.localize(), [DateFormat.yMMMMEEEEd().format(recurrenceRule.until!)])}");
    }
    buffer.write('.');
    return buffer.toString();
  }

  void addAttendee() async {
    final newAttendee = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EventAttendeePage()),
    );
    if (newAttendee is Attendee) {
      event.attendees ??= [];
      setState(() {
        event.attendees?.add(newAttendee);
      });
    }
  }

  void selectStatus() async {
    unFocus();
    EventStatus? eventStatus = (await showDialog<EventStatus>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            children: <Widget>[
              for (final eventStatus in EventStatus.values)
                SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, eventStatus);
                  },
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 24.0),
                  child: Text(eventStatus.enumToString.localize()),
                ),
            ],
          );
        }));

    if (eventStatus != null) {
      setState(() {
        event.status = eventStatus;
      });
    }
  }
  
  void selectAvailability() async {
    unFocus();
    Availability? availability = (await showDialog<Availability>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            children: <Widget>[
              for (final availability in Availability.values)
                SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context, availability);
                  },
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 24.0),
                  child: Text(availability.enumToString.localize()),
                ),
            ],
          );
        }));

    if (availability != null) {
      setState(() {
        event.availability = availability;
      });
    }
  }

  String alarmTitle(Reminder reminder) {
    return reminder.title();
  }


  /// clear focus so keyuboard doesnt appear after returnung from dialog
  void unFocus() {
    contentFocusNode.requestFocus();
  }
}