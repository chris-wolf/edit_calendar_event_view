import 'dart:io';

import 'package:device_calendar/device_calendar.dart';
import 'package:edit_calendar_event_view/string_extensions.dart';
import 'package:flutter/material.dart';
import 'edit_calendar_event_page.dart';

late DeviceCalendarPlugin _deviceCalendarPlugin;

class EventAttendeePage extends StatefulWidget {
  final Attendee? attendee;
  final String? eventId;
  const EventAttendeePage({Key? key, this.attendee, this.eventId})
      : super(key: key);

  @override
  _EventAttendeePageState createState() =>
      _EventAttendeePageState(attendee, eventId ?? '');
}

class _EventAttendeePageState extends State<EventAttendeePage> {
  Attendee? _attendee;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailAddressController = TextEditingController();
  var _role = AttendeeRole.None;
  var _status = AndroidAttendanceStatus.None;
  String _eventId = '';

  _EventAttendeePageState(Attendee? attendee, eventId) {
    if (attendee != null) {
      _attendee = attendee;
      _nameController.text = _attendee!.name!;
      _emailAddressController.text = _attendee!.emailAddress!;
      _role = _attendee!.role!;
      _status = _attendee!.androidAttendeeDetails?.attendanceStatus ??
          AndroidAttendanceStatus.None;
    }
    _eventId = eventId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: EditCalendarEventPage.backgroundColor,
      appBar: AppBar(
        title: Text(_attendee != null
            ? '${'edit_attendee'.localize} ${_attendee!.name}'
            : 'add_an_attendee'.localize()),
      ),
      body: Center(child: SizedBox(width: 600, child: Column(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextFormField(
                    controller: _nameController,
                    validator: (value) {
                      if (_attendee?.isCurrentUser == false &&
                          (value == null || value.isEmpty)) {
                        return 'please_enter_a_name'.localize();
                      }
                      return null;
                    },
                    decoration: InputDecoration(labelText: 'name'.localize()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextFormField(
                    controller: _emailAddressController,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !value.contains('@')) {
                        return 'enter_valid_email'.localize();
                      }
                      return null;
                    },
                    decoration:
                         InputDecoration(labelText: 'email_address'.localize()),
                  ),
                ),
                ListTile(
                  leading:  Text('role'.localize()),
                  trailing: DropdownButton<AttendeeRole>(
                    onChanged: (value) {
                      setState(() {
                        _role = value as AttendeeRole;
                      });
                    },
                    value: _role,
                    items: AttendeeRole.values
                        .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role.enumToString.toUpperCase().localize()),
                            ))
                        .toList(),
                  ),
                ),
                Visibility(
                  visible: Platform.isAndroid,
                  child: ListTile(
                    leading:  Text('attendee_status'.localize()),
                    trailing: DropdownButton<AndroidAttendanceStatus>(
                      onChanged: (value) {
                        setState(() {
                          _status = value as AndroidAttendanceStatus;
                        });
                      },
                      value: _status,
                      items: AndroidAttendanceStatus.values
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.enumToString.toUpperCase().localize()),
                              ))
                          .toList(),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ))),
        floatingActionButton: FloatingActionButton(
          tooltip: 'save'.localize(),
          onPressed: () async {
            saveAttendee();
          },
          backgroundColor: Colors.green,
          child: const Icon(
            Icons.check,
            color: Colors.white,
          ),
        )
    );
  }

  void saveAttendee() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _attendee = Attendee(
            name: _nameController.text,
            emailAddress: _emailAddressController.text,
            role: _role,
            isOrganiser: _attendee?.isOrganiser ?? false,
            isCurrentUser: _attendee?.isCurrentUser ?? false,
            iosAttendeeDetails: _attendee?.iosAttendeeDetails,
            androidAttendeeDetails: AndroidAttendeeDetails.fromJson(
                {'attendanceStatus': _status.index}));

        _emailAddressController.clear();
      });

      Navigator.pop(context, _attendee);
    }
  }
}
