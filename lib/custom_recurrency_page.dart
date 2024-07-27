import 'package:device_calendar/device_calendar.dart';
import 'package:edit_calendar_event_view/recurrency_frequency.dart';
import 'package:edit_calendar_event_view/string_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


enum MonthRuleType {
  monthDay,
  nthWeek
}
enum Ends {
  never,
  count,
  date,
}

class CustomRecurrencePage extends StatefulWidget {

   final DateTime? eventStartDate;
   const CustomRecurrencePage(this.eventStartDate, {super.key});


  @override
  _CustomRecurrencePageState createState() => _CustomRecurrencePageState();
}

class _CustomRecurrencePageState extends State<CustomRecurrencePage> {
  RecurrenceFrequency _frequency = RecurrenceFrequency.Daily;
  DateTime? _until;
  int? _count;
  int _interval = 1;
  MonthRuleType monthRuleType = MonthRuleType.monthDay;
  List<int> _byWeekDays = [];
  List<int> _byMonthDays = [];
  List<int> _bySetPositions = [];
  List<int> _byMonths = [];
  int? _weekStart = DateTime.monday;
  DateTime? endDate;
  int count = 1;
  Ends ends = Ends.never;


  static const sectionPadding = 16.0;

  TextStyle? headerTheme;

  @override
  void initState() {
    final date = widget.eventStartDate;
    if (date != null) {
      _byWeekDays = [date.weekday];
      _byMonthDays = [date.day];
      _bySetPositions = [date.day ~/ 7 + 1];
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
     headerTheme ??= Theme.of(context).textTheme.bodyLarge;
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Recurrence Rule'),
      ),
      body: ListView(
          padding: EdgeInsets.all(24),
          children: [
            Text('Repeat every:',
            style: headerTheme),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNumberPicker(),
                _buildFrequencyPicker(),
              ],
            ),
            if (_frequency == RecurrenceFrequency.Monthly)
              _buildMonthRulePicker(),
            if (_frequency == RecurrenceFrequency.Weekly || (_frequency == RecurrenceFrequency.Monthly && monthRuleType == MonthRuleType.nthWeek))
              _buildWeekDaysPicker(),
            if (_frequency == RecurrenceFrequency.Monthly && monthRuleType == MonthRuleType.monthDay)
              _buildMonthDaysPicker(),
            if (_frequency != RecurrenceFrequency.Yearly)
              _buildMonthPicker(),
            _buildEndsPicker(),
            const SizedBox(height: 48.0,)
          ],
      ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'save'.localize(),
          onPressed: () async {
             _onSavePressed();
          },
          backgroundColor: Colors.green,
          child: const Icon(
            Icons.check,
            color: Colors.white,
          ),
        )
    );
  }

  Widget _buildNumberPicker() {
    return SizedBox(
      width: 72,
      height: 72,
      child: CupertinoPicker.builder(
        backgroundColor: Colors.transparent,
        childCount: 100,
        itemBuilder: (BuildContext context, int index) =>
            Center(child: Text('${index + 1}', textAlign: TextAlign.center)),
        onSelectedItemChanged: (int value) {
          setState(() {
            _interval = value + 1;
          });
        },
        itemExtent: 32,
      ),
    );
  }

  Widget _buildFrequencyPicker() {
    return SizedBox(
      width: 72,
      height: 72,
      child: CupertinoPicker.builder(
        backgroundColor: Colors.transparent,
        childCount: RecurrenceFrequency.values.length,
        itemBuilder: (BuildContext context, int index) =>
            Center(child: Text(RecurrenceFrequency.values[index].localize(_interval), textAlign: TextAlign.center)),
        onSelectedItemChanged: (int value) {
          setState(() {
            _frequency = RecurrenceFrequency.values[value];
          });
        },
        itemExtent: 32,
      ),
    );
  }

  Widget _buildMonthRulePicker() {
    return Padding(
      padding:  const EdgeInsets.only(top: sectionPadding),
      child: CupertinoSlidingSegmentedControl<MonthRuleType>(
        groupValue: monthRuleType,
        onValueChanged: (MonthRuleType? value) {
          if (value != null) {
            setState(() {
              monthRuleType = value;
            });
          }
        },
        children: {
          MonthRuleType.monthDay: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Monthday'),
          ),
          MonthRuleType.nthWeek: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('nthWeekDAY'),
          ),
        },
      ),
    );
  }

  Widget _buildWeekDaysPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: sectionPadding),
        Text('Select Days of the Week',
        style: Theme.of(context).textTheme.bodyLarge,),
        Wrap(
          spacing: 8.0,
          children: List<Widget>.generate(7, (int index) {
            return ChoiceChip(
              label: Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index]),
              selected: _byWeekDays.contains(index + 1),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _byWeekDays.add(index + 1);
                  } else {
                    _byWeekDays.remove(index + 1);
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMonthDaysPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: sectionPadding,),
        Text('Select Days of the Month'),
        Wrap(
          spacing: 8.0,
          children: List<Widget>.generate(31, (int index) {
            return ChoiceChip(
              label: Text((index + 1).toString()),
              selected: _byMonthDays.contains(index + 1),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _byMonthDays.add(index + 1);
                  } else {
                    _byMonthDays.remove(index + 1);
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSetPositionPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Set Position'),
        Wrap(
          spacing: 8.0,
          children: List<Widget>.generate(5, (int index) {
            return ChoiceChip(
              label: Text(WeekNumber.values[index].name),
              selected: _bySetPositions.contains(index + 1),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _bySetPositions.add(index + 1);
                  } else {
                    _bySetPositions.remove(index + 1);
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMonthPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: sectionPadding,),
        Text('Select Months', style: headerTheme,),
        Wrap(
          spacing: 8.0,
          children: List<Widget>.generate(12, (int index) {
            return ChoiceChip(
              label: Text(['All', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][index]),
              selected: (index == 0) ? _byMonths.isEmpty : (_byMonths.isNotEmpty && _byMonths.contains(index)),
              onSelected: (bool selected) {
                setState(() {
                  if (index == 0) {
                    _byMonths = [];
                  } else if (selected) {
                    _byMonths.add(index);
                  } else {
                    _byMonths.remove(index);
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEndsPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: sectionPadding,),
        Text('Ends:', style: headerTheme,),
        RadioListTile(
          value: Ends.never,
          groupValue: ends,
          title: Text('Never'),
          onChanged: (value) {
            setState(() {
              ends = value!;
            });
          },
        ),
        RadioListTile(
          value: Ends.date,
          groupValue: ends,
          title: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text('Am'),
              ),
              Expanded(
                child: ElevatedButton(
                  child: Text((endDate ?? DateTime.now()).toIso8601String(),),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      setState(() {
                        endDate = date;
                        ends = Ends.date;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          onChanged: (value) async {
            DateTime? date = endDate ?? await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );

            if (date != null) {
              setState(() {
                endDate = date;
                ends = Ends.date;
              });
            }
          },
        ),
        RadioListTile(
          value: Ends.count,
          groupValue: ends,
          title: Row(children: [Text('Nach'), Expanded(child:_buildCountPicker()), Text('Terminen')]),
          onChanged: (value) {
            setState(() {
              ends = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCountPicker() {
    return SizedBox(
      height: 72,
      child: CupertinoPicker.builder(
        backgroundColor: Colors.transparent,
        childCount: 100,
        itemBuilder: (BuildContext context, int index) => Center(child: Text('${index + 1}')),
        onSelectedItemChanged: (int value) {
          setState(() {
            count = value + 1;
          });
        },
        itemExtent: 32,
      ),
    );
  }

  void _onSavePressed() {
    final recurrenceRule = RecurrenceRule(
      frequency: _frequency.toFrequency(),
      until: ends == Ends.date ? _until : null,
      count: ends == Ends.count ? _count : null,
      interval: _interval,
      byWeekDays: (_frequency == RecurrenceFrequency.Weekly || _frequency == RecurrenceFrequency.Monthly && monthRuleType == MonthRuleType.nthWeek) ? _byWeekDays.map((dayNumber) => ByWeekDayEntry(dayNumber)).toList() : [],
      byMonthDays: (_frequency == RecurrenceFrequency.Monthly && monthRuleType == MonthRuleType.nthWeek) ? _byMonthDays : [],
      bySetPositions: (_frequency == RecurrenceFrequency.Monthly && monthRuleType == MonthRuleType.nthWeek) ? _bySetPositions : [],
      byMonths:(_frequency == RecurrenceFrequency.Yearly ) ? [] :  _byMonths,
      weekStart: _weekStart,
    );
    Navigator.pop(context, recurrenceRule);
  }
}