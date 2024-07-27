import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class TimeZoneSearchDelegate extends SearchDelegate<MapEntry<String, Location>?> {
  final List<MapEntry<String, Location>> timeZones = tz.timeZoneDatabase.locations.entries.toList();


  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }


  @override
  Widget buildResults(BuildContext context) {
    final results = timeZones.where((tz) => tz.value.name.toLowerCase().contains(query.toLowerCase()) || tz.key.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('${results[index].value.name} (${results[index].key})'),
          onTap: () {
            Navigator.pop(context, results[index]);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = timeZones.where((tz) => tz.value.name.toLowerCase().contains(query.toLowerCase()) || tz.key.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('${results[index].value.name} (${results[index].key})'),
          onTap: () {
            Navigator.pop(context, results[index]);
          },
        );
      },
    );
  }
}