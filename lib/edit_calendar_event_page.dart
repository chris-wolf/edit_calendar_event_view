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
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:sprintf/sprintf.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

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

final _deviceCalendarPlugin = DeviceCalendarPlugin(shouldInitTimezone: false);

class EditCalendarEventPage extends StatefulWidget {
  static String? currentTimeZone;
  static Color? backgroundColor;
  static List<Color> fallbackColors = [
  ]; // for iOS and local calendars no colors are savable for an event. use these as fallback, but they aren't stored in the calendar!

  static Future<dynamic> show(BuildContext context,
      {String? calendarId,
        Event? event,
        String? title,
        String? description,
        int? startDate,
        int? endDate,
        bool? allDay, DatePickerType? datePickerType, List<
          Calendar>? availableCalendars, EventColor? eventColor, List<
          Reminder>? reminders}) async {
    currentTimeZone = tz.local.toString();
    List<Calendar> calendars = availableCalendars ??
        (await _deviceCalendarPlugin.retrieveCalendars()).data?.toList() ?? [];
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
    if (calendar?.isReadOnly ?? false) {
      datePickerType = DatePickerType.material;
    }
    final page = EditCalendarEventPage(
      event: event,
      calendar: calendar,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      allDay: allDay,
      datePickerType: datePickerType ?? DatePickerType.material,
      availableCalendars: calendars.where((calendar) => calendar.isReadOnly == false).toList(),
      eventColor: eventColor,
      reminders: reminders
    );
    if (MacosTheme.maybeOf(context) != null) {
      return MultiPlatformDialog.show(context, page,
          barrierDismissible: true, maxWidth: 500, maxHeight: 548);
    } else {
      return Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page,
            settings: RouteSettings(name: 'EditCalendarEventPage')),
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
  final List<Calendar>? availableCalendars;
  final EventColor? eventColor;
  final List<Reminder>? reminders;

  const EditCalendarEventPage({super.key,
    this.event,
    this.calendar,
    this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.allDay,
    required this.datePickerType, this.availableCalendars,
    this.eventColor,
    this.reminders
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
  String? colorsFromCalendarId;

  @override
  void initState() {
    super.initState();
    if (tz.local == null) {
      tz.setLocalLocation(
          tz.getLocation(EditCalendarEventPage.currentTimeZone ?? 'UTC'));
    }
    calendar = widget.calendar;
    if (widget.event != null) {
      event = widget.event!;
      // make sure start and end hafve the same timezone
      event.end = tz.TZDateTime.from(
          event.end ?? DateTime.now().add(Duration(hours: 1)),
          event.start?.location ?? tz.local);
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
    if (widget.reminders != null) {
      event.reminders = widget.reminders;
    }
    if (widget.eventColor != null) {
      event.updateEventColor(widget.eventColor);
    }
    _titleController.text = event.title ?? '';
    _descriptionController.text = event.description ?? '';
    _locationController.text = event.location ?? '';
    _websiteController.text = event.url?.data?.contentText ?? '';
    _websiteController.text = event.url?.data?.contentText ?? '';
    loadEventColors(initialLoad: true);
    if (calendar?.isReadOnly ?? false) {
      Future.delayed(const Duration(milliseconds: 100)).then((_) =>
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
              content: Text('read_only_event'.localize()),
              duration: const Duration(seconds: 60))));
    }
  }

  Future<void> loadEventColors({bool initialLoad = false}) async {
    final currCalendar = calendar;
    List<EventColor>? retrievedColors;

    if (currCalendar != null) {
      retrievedColors = await _deviceCalendarPlugin.retrieveEventColors(currCalendar);
    }
    setState(() {

    if (retrievedColors?.isNotEmpty ?? false) {
      eventColors = retrievedColors ?? [];
    } else {
      eventColors = EditCalendarEventPage.fallbackColors.mapIndexed(
            (index, color) => EventColor(color.value, -1 - index),
      ).toList();
      if (initialLoad && event.color != null) {
        event.updateEventColor(eventColors.firstWhereOrNull((eventColor) => eventColor.color == event.color));
      }
    }
    });
  }

  TZDateTime epochMillisToTZDateTime(int epochMillis) {
    // Initialize timezone data; required if you haven't done it elsewhere in your app.
    // Convert epoch milliseconds to a DateTime object.
    return tz.TZDateTime.fromMillisecondsSinceEpoch(
        event.start?.location ?? tz.local, epochMillis);
  }

  Color? buttonTextColor;
  Color? iconColor;

  @override
  Widget build(BuildContext context) {
    buttonTextColor ??= Theme
        .of(context)
        .brightness == Brightness.light ? Theme
        .of(context)
        .primaryColor : Theme
        .of(context)
        .colorScheme
        .onSurface;
    iconColor ??= Theme
        .of(context)
        .colorScheme
        .onSurface
        .withOpacity(0.64);
    final title =
    (widget.event == null ? 'add_event' : (calendar?.isReadOnly ?? false)
        ? 'read_only'
        : 'edit_event').localize();
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
      },
      child: MultiPlatformScaffold(
          title: title,
          macOsLeading: MacosIconButton(
            icon: Icon(Icons.close, color: Color(0xff808080)),
            onPressed: () => Navigator.pop(context),
            padding: const EdgeInsets.all(5.0),
          ),
          actions: [
            if (widget.event != null && calendar?.isReadOnly == false)
              Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: IconButton(
                  icon: Icon(
                    Icons.delete,
                    semanticLabel: 'delete'.localize(),
                  ),
                  tooltip: 'delete'.localize(),
                  onPressed: () async {
                    await deleteEvent(context);
                  },
                ),
              ),
          ],
          macOsActions: [
            if (widget.event != null && calendar?.isReadOnly == false)
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
          body:
          Stack(
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
          floatingActionButton: calendar?.isReadOnly ?? false
              ? null
              : FloatingActionButton(
            tooltip: 'save'.localize(),
            onPressed: () async {
              await confirmPress(context);
            },
            backgroundColor: Colors.green,
            child: Icon(
              Icons.check,
              color: Colors.white,
              semanticLabel: 'save'.localize(),
            ),
          )),
    );
  }

  Future<void> deleteEvent(BuildContext context) async {
    final event = widget.event;
    if (event != null) {
      if (event.recurrenceRule != null ) {
        event.recurrenceRule = null;
        await _deviceCalendarPlugin.createOrUpdateEvent(event); // in local calendar deleting recurring events can cause other events to disappear, so remove recurring before deleting
      }
      await _deviceCalendarPlugin.deleteEvent(event.calendarId, event.eventId);
      Navigator.pop(
          context, (resultType: ResultType.deleted, event: event));
    }
  }

  DateTime startDate() {
    return event.start ?? DateTime.now();
  }

  DateTime endDate() {
    return event.end ?? startDate().add(const Duration(hours: 1));
  }

  bool allDay() {
    return event.allDay ?? false;
  }

  FocusNode contentFocusNode = FocusNode();
  bool controlPressed = false;

  Widget content() {
    return KeyboardListener(
        focusNode: contentFocusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            switch (event.logicalKey) {
              case LogicalKeyboardKey.escape:
                Navigator.pop(context);
              case LogicalKeyboardKey.keyS:
                if (controlPressed) {
                  confirmPress(context);
                }
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.control) {
            controlPressed = event is KeyDownEvent;
          }
        },
        child: Builder(builder: (context) {
          return SingleChildScrollView(child:
          Center(child: SizedBox(width: 500, child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
              child: Column(
                  children: <Widget>[
              AbsorbPointer(
              absorbing: calendar?.isReadOnly ?? false,
                  child: Card(
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
                              focusNode: event.title == null ?
                              titleFocusNode ??= (FocusNode()
                                ..requestFocus()) : null,
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
                    )),
            AbsorbPointer(
                absorbing: calendar?.isReadOnly ?? false,
                child: Card(
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0))),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                              leading: Icon(Icons.access_time_rounded,
                                color: iconColor,),
                              title: Row(
                                children: <Widget>[
                                  Expanded(child: Text('all_day'.localize(),
                                    style: Theme
                                        .of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: buttonTextColor),)),
                                  Switch.adaptive(
                                    value: allDay(),
                                    onChanged: (bool value) {
                                      setState(() {
                                        event.allDay = value;
                                        final end = event.end;
                                        final start = event.start;
                                        if (end != null && start != null) {
                                          if (end.day != start.day && end
                                              .difference(start)
                                              .inHours <
                                              10) { // user probably wanted just one day all day event
                                            event.end = TZDateTime(
                                                start.location, start.year,
                                                start.month, start.day, 23, 59);
                                          }
                                        }
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
                                  Expanded(
                                    child: CupertinoDatePicker(
                                        use24hFormat: MediaQuery
                                            .alwaysUse24HourFormatOf(context),
                                        key: ValueKey(
                                            (allDay(), updatedStartDate
                                                ?.hashCode)),
                                        mode: allDay() ? CupertinoDatePickerMode
                                            .date : CupertinoDatePickerMode
                                            .dateAndTime,
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
                                  Expanded(
                                    child: CupertinoDatePicker(
                                        key: ValueKey((allDay(), updatedEndDate
                                            ?.hashCode)),
                                        use24hFormat: MediaQuery
                                            .alwaysUse24HourFormatOf(context),
                                        mode: allDay() ? CupertinoDatePickerMode
                                            .date : CupertinoDatePickerMode
                                            .dateAndTime,
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
                                  Expanded(child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton(
                                          onPressed: () async {
                                            await startDatePicker(context);
                                          },
                                          child: Text(
                                              DateFormat('EEE, MMM d, yyyy')
                                                  .format(startDate()),
                                              style: const TextStyle(
                                                  fontSize: 16))))),
                                  if (allDay() == false)
                                    TextButton(
                                        onPressed: () {
                                          setStartTime(context);
                                        },
                                        child: Text(
                                            DateFormat.jm()
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
                                  Expanded(child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton(
                                          onPressed: () async {
                                            await endDatePicker(context);
                                          },
                                          child: Text(
                                              DateFormat('EEE, MMM d, yyyy')
                                                  .format(endDate()),
                                              style: const TextStyle(
                                                  fontSize: 16))))),
                                  if (allDay() == false)
                                    TextButton(
                                      onPressed: () {
                                        setEndTime(context);
                                      },
                                      child: Text(
                                          DateFormat.jm().format(endDate()),
                                          style: const TextStyle(fontSize: 16)),
                                    ),
                                ],
                              ),
                              onTap: () async {
                                await endDatePicker(context);
                              },
                            ),
                          ListTile(
                              leading: Icon(Icons.refresh,
                                  color: iconColor),
                              title: Text(
                                  event.recurrenceRule == null
                                      ? 'repeat_once'.localize()
                                      : getRRuleString(event.recurrenceRule),
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: buttonTextColor)
                              ),
                              onTap: () async {
                                selectRecurrenceRule();
                              }),
                        ],
                      ),
                    ),
            ),
            AbsorbPointer(
                absorbing: calendar?.isReadOnly ?? false,
                child: Card(
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0))),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(16, 16, 0, 20),
                                child: Icon(Icons.calendar_month,
                                    color: iconColor),
                              ),
                              Expanded(
                                child: ListTile(
                                  title: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text('${'calendar'.localize()}',
                                          maxLines: 1,
                                          style: Theme
                                              .of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                              color: buttonTextColor),),
                                      )),
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
                                    final calendars = widget
                                        .availableCalendars ??
                                        (await _deviceCalendarPlugin
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
                                    if (result?.id != null &&
                                        result?.id != event.calendarId) {
                                      event.updateEventColor(null);
                                      setState(() {
                                        calendar = result;
                                        event.calendarId = result?.id;
                                      });
                                      loadEventColors();
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
                                Padding(
                                  padding: EdgeInsets.fromLTRB(16, 16, 0, 20),
                                  child: Icon(Icons.color_lens_outlined,
                                      color: iconColor),
                                ),
                                Expanded(
                                  child: ListTile(
                                    title: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Expanded(child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '${'event_color'.localize()}',
                                            style: Theme
                                                .of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                color: buttonTextColor),),
                                        )),
                                        if ((event.color ?? 0) != 0)
                                          Container(
                                            alignment: Alignment.center,
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                Color(event.color ?? 0)),
                                          ),
                                        if ((event.color ?? 0) == 0)
                                          Text('not_set'.localize(),
                                          ),
                                      ],
                                    ),
                                    onTap: () async {
                                      final color = await ColorPickerDialog
                                          .selectColorDialog(
                                          eventColors.map((eventColor) =>
                                              Color(eventColor.color)).toList(),
                                          context,
                                          selectedColor: event.color == null
                                              ? null
                                              : Color(event.color!),
                                          canReset: colorsFromCalendarId ==
                                              null);
                                      final eventColor = eventColors
                                          .firstWhereOrNull((eventColor) =>
                                      Color(eventColor.color) == color);
                                      if (eventColor != null ||
                                          color == Colors.transparent) {
                                        setState(() {
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
                              Padding(
                                padding: EdgeInsets.fromLTRB(16, 16, 0, 20),
                                child: Icon(Icons.alarm,
                                    color: iconColor),
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
                                            semanticLabel: 'remove_reminder'
                                                .localize(),
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
                                        style: Theme
                                            .of(context)
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
            ),
                    Card(
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8.0))),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [Padding(
                              padding: EdgeInsets.fromLTRB(16, 16, 4, 20),
                              child: Icon(Icons.public,
                                  color: iconColor),
                            ),
                              Expanded(
                                child: AbsorbPointer(
                                  absorbing: calendar?.isReadOnly ?? false,
                                  child: ListTile(
                                  title: Text('${event.start
                                      ?.timeZoneName} (UTC ${(event.start
                                      ?.timeZone.offset ?? 0) >= 0
                                      ? '+'
                                      : ''}${(event.start?.timeZone.offset ??
                                      0) ~/ (60 * 60 * 1000)})',
                                      style: Theme
                                          .of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: buttonTextColor)),
                                  onTap: () async {
                                    unFocus();
                                    final timezone = await showSearch(
                                        context: context,
                                        delegate: TimeZoneSearchDelegate());
                                    if (timezone is MapEntry<String,
                                        Location>) {
                                      setState(() {
                                        final start = event.start;
                                        final end = event.end;
                                        if (start != null) {
                                          event.start = TZDateTime(
                                            timezone.value,
                                            start.year,
                                            start.month,
                                            start.day,
                                            start.hour,
                                            start.minute,
                                            start.second,
                                            start.millisecond,
                                            start.microsecond,
                                          );
                                        }
                                        if (end != null) {
                                          event.end = TZDateTime(
                                            timezone.value,
                                            end.year,
                                            end.month,
                                            end.day,
                                            end.hour,
                                            end.minute,
                                            end.second,
                                            end.millisecond,
                                            end.microsecond,
                                          );
                                        }
                                      });
                                    }
                                  },
                                ),
                                )
                              )
                            ],
                          ),
                          divider(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              InkWell(
                                  onTap: event.location?.isEmpty ?? true
                                      ? null
                                      : () async {
                                    openMapLocation(event.location ?? '');
                                  }, child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                                child: Icon(Icons.location_on_outlined,
                                    color: event.location?.isEmpty ?? true ? iconColor : Colors.blue),
                              )),
                              Expanded(
                                child: AbsorbPointer(
                                  absorbing: calendar?.isReadOnly ?? false,
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
                              )
                            ],
                          ),
                          divider(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              InkWell(
                                  onTap: event.url?.data?.contentText == null
                                      ? null
                                      : () async {
                                    final url = Uri.parse(
                                        event.url?.data?.contentText ?? '');
                                    if (url != null) {
                                      if (!await launchUrl(url)) {
                                        throw Exception(
                                            'Could not launch $url');
                                      }
                                    }
                                  }, child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                                child: Icon(Icons.web_sharp,
                                    color: event.url?.data?.contentText == null ? iconColor : Colors.blue),
                              )),

                              Expanded(
                                child: AbsorbPointer(
                                  absorbing: calendar?.isReadOnly ?? false,
                                  child:  TextFormField(
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
                              )
                            ],
                          ),
                          divider(),
                      AbsorbPointer(
                        absorbing: calendar?.isReadOnly ?? false,
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(16, 16, 4, 20),
                                child: Icon(Icons.question_mark,
                                    color: iconColor),
                              ),
                              Expanded(
                                child: ListTile(
                                  title: Text(
                                      getEventStatus() == EventStatus.None
                                          ? 'set_status'.localize()
                                          : getEventStatus().enumToString
                                          .localize(),
                                      style: Theme
                                          .of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: buttonTextColor)
                                  ),
                                  onTap: () async {
                                    selectStatus();
                                  },
                                ),
                              )
                            ],
                          ),
                      ),
                          divider(),
                      AbsorbPointer(
                        absorbing: calendar?.isReadOnly ?? false,
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(16, 16, 4, 20),
                                child: Icon(Icons.timelapse,
                                    color: iconColor),
                              ),
                              Expanded(
                                child: ListTile(
                                  title: Text(
                                    event.availability.enumToString.localize(),
                                    style: Theme
                                        .of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: buttonTextColor),),
                                  onTap: () async {
                                    selectAvailability();
                                  },
                                ),
                              )
                            ],
                          ),
                      ),
                          divider(),
                      AbsorbPointer(
                        absorbing: calendar?.isReadOnly ?? false,
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(16, 16, 0, 20),
                                child: Icon(Icons.group,
                                    color: iconColor),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    for (final Attendee attendee
                                    in event.attendees?.nonNulls ?? [])
                                      ListTile(
                                        title: Text(
                                            '${attendee.name} (${attendee
                                                .emailAddress})'),
                                        subtitle: Text(() {
                                          StringBuffer buffer = StringBuffer();
                                          if ((attendee.role ??
                                              AttendeeRole.None) !=
                                              AttendeeRole.None) {
                                            buffer.write(
                                                attendee.role!
                                                    .enumToString);
                                            buffer.write(' ');
                                          }
                                          if (Platform.isAndroid) {
                                            if ((attendee
                                                .androidAttendeeDetails
                                                ?.attendanceStatus ??
                                                AndroidAttendanceStatus
                                                    .None) !=
                                                AndroidAttendanceStatus
                                                    .None) {
                                              buffer.write(
                                                  '(${(attendee
                                                      .androidAttendeeDetails
                                                      ?.attendanceStatus ??
                                                      AndroidAttendanceStatus
                                                          .None)
                                                      .enumToString})');
                                            }
                                          }
                                          if (Platform.isIOS) {
                                            if ((attendee
                                                .iosAttendeeDetails
                                                ?.attendanceStatus ??
                                                IosAttendanceStatus
                                                    .Unknown) !=
                                                IosAttendanceStatus
                                                    .Unknown) {
                                              buffer.write(
                                                  '(${(attendee
                                                      .iosAttendeeDetails
                                                      ?.attendanceStatus ??
                                                      IosAttendanceStatus
                                                          .Unknown)
                                                      .enumToString})');
                                            }
                                          }
                                          return buffer.toString()
                                              .trim();
                                        }(),),
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
                                        style: Theme
                                            .of(context)
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
                      )
                        ],
                      ),
                    ),
                    const SizedBox(height: 72,)
                  ]),
          ),

          )));
        }));
  }

  int maxInteger = 0x7FFFFFFFFFFFFFFF;

  void addReminder() async {
    unFocus();
    Reminder? reminder = (await showDialog<Reminder>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            backgroundColor: EditCalendarEventPage.backgroundColor,
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
                  Navigator.pop(context, Reminder(minutes: maxInteger));
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
    if (reminder?.minutes == maxInteger) {
      reminder = reminder = (await showDialog<Reminder>(
        context: context,
        builder: (BuildContext context) {
          TextEditingController numberController =
          TextEditingController(text: '10');
          int currentIndex = 0;
          return AlertDialog(
            backgroundColor: EditCalendarEventPage.backgroundColor,
            title: Text('custom'.localize()),
            content: StatefulBuilder(
              builder: (BuildContext context,
                  void Function(void Function()) setState) {
                return SizedBox(
                    height: 280,
                    child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            TextField(
                              focusNode: FocusNode()
                                ..requestFocus(),
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
                        )));
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
        event.reminders = (event.reminders ?? [])
          ..add(reminder!);
      });
    }
  }

  void selectRecurrenceRule() async {
    unFocus();
    RecurrenceRule? rule = (await showDialog<RecurrenceRule>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            backgroundColor: EditCalendarEventPage.backgroundColor,
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
    if (rule == null) { // back pressed
      return;
    }
    if (rule.interval == 0x7FFFFFFFFFFFFFFF) {
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
          if (endDate().isBeforeOrSame(startDate())) {
            event.start = event.end?.subtract(Duration(hours: 1));
          }
        });
      }
    });
  }

  void setStartTime(BuildContext context) async {
    final time = await
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(startDate()),
    );
    if (time != null) {
      Duration? duration = event.end?.difference(event.start ?? DateTime.now());
      if ((duration?.inMinutes ?? 0) <= 0) {
        duration = const Duration(minutes: 1);
      }
      setState(() {
        final newDateTime = event.start?.add(Duration(
            hours: time.hour - startDate().hour,
            minutes: time.minute - startDate().minute));
        if (newDateTime != null) {
          event.start = newDateTime;
          if (duration != null) {
            event.end = event.start?.add(duration);
            updatedEndDate = event.end;
          }
        }
      });
    }
  }

  void setStartDate(DateTime newDate, int? hour, int? minutes) {
    Duration? duration = event.end?.difference(event.start ?? DateTime.now());
    if ((duration?.inMinutes ?? 0) <= 0) {
      duration = const Duration(minutes: 1);
    }
    setState(() {
      final newDateTime = epochMillisToTZDateTime(newDate
          .add(Duration(hours: hour ?? 0, minutes: minutes ?? 0))
          .millisecondsSinceEpoch);
      event.start = newDateTime;
      if (duration != null) {
        event.end = event.start?.add(duration);
        updatedEndDate = event.end;
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
      if (endDate().isBeforeOrSame(startDate())) {
        event.start = event.end?.subtract(const Duration(hours: 1));
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
      initialDate: startDate(),
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
    if (event.status == EventStatus.Canceled) {
      final cancel = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('confirm_cancellation'.localize()),
            content: Text('confirm_cancellation_text'.localize()),
            actions: <Widget>[
              TextButton(
                child: Text('keep_event'.localize()),
                onPressed: () {
                  Navigator.of(context).pop(false); // Close the dialog
                },
              ),
              TextButton(
                child: Text('delete'.localize()),
                onPressed: () {
                  Navigator.of(context).pop(true); // Close the dialog
                },
              ),
            ],
          );
        },
      );
      if (cancel != true) {
        event.status = EventStatus.Tentative;
      }
    }
    event.title = _titleController.text;
    event.description = _descriptionController.text;
    event.location = _locationController.text;
    EventColor? bufferedEventColor;
    event.url = parseUrl(_websiteController.text.trim());
    if (allDay() && event.start != null && event.end != null) {
     event.start = TZDateTime.utc(event.start!.year, event.start!.month, event.start!.day);
      event.end = TZDateTime.utc(event.end!.year, event.end!.month, event.end!.day, 23, 59, 59, 999);
    }

    final cachedEnd = event.end;
    final cachedColorKey = event.colorKey;
    if ((event.colorKey ?? 0) <
        0) { // fallBack Color which doesnt exist in db so dont store it!
      event.colorKey = null;
    }
    final eventId = await _deviceCalendarPlugin.createOrUpdateEvent(event);
    event.eventId = eventId?.data;
    if (event.eventId == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('error_saving_event'.localize())));
      return;
    }
    event.colorKey = cachedColorKey;
    if (allDay()) { // for allDay the end Time was nextDay 00:00 insteasdf of thisDas 00:00 when loading normally, so caced endTime to fix this
      event.end = cachedEnd;
    }
    if (context.mounted) {
      Navigator.pop(
          context, (resultType: event.status == EventStatus.Canceled
          ? ResultType.deleted
          : ResultType.saved, event: event));
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
      if (
      recurrenceRule.until == null &&
          recurrenceRule.count == null &&
          recurrenceRule.interval == 1 &&
          recurrenceRule.bySeconds.isEmpty &&
          recurrenceRule.byMinutes.isEmpty &&
          recurrenceRule.byHours.isEmpty &&
          recurrenceRule.byWeekDays.isEmpty &&
          recurrenceRule.byMonthDays.isEmpty &&
          recurrenceRule.byYearDays.isEmpty &&
          recurrenceRule.byWeeks.isEmpty &&
          recurrenceRule.byMonths.isEmpty &&
          recurrenceRule.bySetPositions.isEmpty) {
        return RecurrenceFrequency
            .fromFrequency(recurrenceRule.frequency)
            .name
            .localize();
      }
      else {
        buffer.write('${'every'.localize()}');
      }
    }

    // if  reminder has only frequency set
    if (recurrenceRule.until == null && recurrenceRule.count == null &&
        recurrenceRule.interval == null && recurrenceRule.weekStart == null &&
        recurrenceRule.bySeconds.isEmpty && recurrenceRule.byMinutes.isEmpty &&
        recurrenceRule.byHours.isEmpty && recurrenceRule.byWeekDays.isEmpty &&
        recurrenceRule.byMonthDays.isEmpty &&
        recurrenceRule.byYearDays.isEmpty && recurrenceRule.byWeeks.isEmpty &&
        recurrenceRule.byMonths.isEmpty && recurrenceRule.bySeconds.isEmpty) {
      return recurrenceRule.frequency
          .toString()
          .toLowerCase()
          .capitalize()
          .localize();
    }
    switch (recurrenceRule.frequency) {
      case Frequency.daily:
        buffer.write(' ${(interval == 1 ? "day" : 'days').localize()}');
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
          buffer.write(
              " ${sprintf('on_day_s'.localize(), [monthDays.join(", ")])}");
        } else if (byWeekdays.isNotEmpty) {
          buffer.write(' ${sprintf('on_s'.localize(), [
            byWeekdays
                .map((weekDay) =>
                DateFormat.E().format(
                    DateTime(2018, 1, 1).add(Duration(days: weekDay.day - 1))))
                .join(", ")
          ])}');
          if (bySetPosition.isNotEmpty) {
            buffer.write(" ${sprintf('for_s'.localize(), [
              bySetPosition
                  .map((weekNmbr) => '${weekNmbr}_week'.localize())
                  .join(', ')
            ])}");
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
      buffer.write(" ${sprintf('in_s'.localize(), [
        byMonth.map((monthNmbr) =>
            DateFormat.MMM().format(DateTime(2020, monthNmbr, 15))).join(", ")
      ])}");
    }

    if (recurrenceRule.count != null) {
      buffer.write(
          " ${sprintf('for_n_events'.localize(), [recurrenceRule.count])}");
    } else if (recurrenceRule.until != null) {
      buffer.write(" ${sprintf('until_s'.localize(),
          [DateFormat.yMMMMEEEEd().format(recurrenceRule.until!.toUtc())])}");
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
            backgroundColor: EditCalendarEventPage.backgroundColor,
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
            backgroundColor: EditCalendarEventPage.backgroundColor,
            children: <Widget>[
              for (final availability in Availability.values.whereNot((avail) =>
              avail == Availability
                  .Unavailable)) // Unavailable doesn't do anything for android
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

  EventStatus getEventStatus() {
    return event.status ?? EventStatus.None;
  }


  /// clear focus so keyuboard doesnt appear after returnung from dialog
  void unFocus() {
    contentFocusNode.requestFocus();
  }

  Uri? parseUrl(String url) {
    if (url.isEmpty) {
      return null;
    }
    // Add a default scheme if none is present
    if (!url.startsWith(RegExp(r'http[s]?://'))) {
      url = 'https://$url';
    }

    // Attempt to parse the URL and catch any errors
    try {
      Uri? uri = Uri.dataFromString(url);
      // Additional validation to ensure the URI has a scheme and host
      return uri;
    } catch (e) {
      // Handle any exceptions (optional logging)
      debugPrint('Error parsing URL: $e');
    }

    // Return null if the URL is invalid
    return null;
  }


  Future<void> openMapLocation(String location) async {
    final query = Uri.encodeComponent(location);
    Uri? uri;

    if (Platform.isIOS) {
      // Apple Maps URL
      uri = Uri.parse("http://maps.apple.com/?q=$query");
      // Alternative using latitude/longitude if available:
      // uri = Uri.parse("maps:0,0?q=$query"); // For search
      // uri = Uri.parse("maps://?ll=latitude,longitude"); // For specific coordinates
    } else if (Platform.isAndroid) {
      // Google Maps URL for search
      uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
      // Alternative using geo intent:
      // uri = Uri.parse("geo:0,0?q=$query");
    } else {
      // Optional: Handle other platforms or throw an error
      debugPrint("Map functionality not supported on this platform.");
      // throw 'Map functionality not supported on this platform.';
      return;
    }

    // This check is technically redundant if you handle the 'else' case above
    // where uri would remain null for unsupported platforms.
    // if (uri == null) {
    //   debugPrint("URI could not be constructed for location: $location");
    //   return;
    // }

    debugPrint("Attempting to launch map with URI: $uri");

    if (await canLaunchUrl(uri)) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint("Error launching URL $uri: $e");
        throw 'Could not launch map for location: $location. Error: $e';
      }
    } else {
      debugPrint("Cannot launch URL: $uri. 'canLaunchUrl' returned false.");
      // Provide more specific feedback based on platform if possible
      String platformSpecificHelp = "";
      if (Platform.isAndroid) {
        platformSpecificHelp = " For Android, ensure <queries> for 'https' scheme is in AndroidManifest.xml.";
      } else if (Platform.isIOS) {
        platformSpecificHelp = " For iOS, ensure 'LSApplicationQueriesSchemes' includes 'http' in Info.plist.";
      }
      throw 'Could not launch map for location: $location. Ensure the map application is installed and permissions are set.$platformSpecificHelp';
    }
  }
}