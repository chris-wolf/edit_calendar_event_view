import 'package:device_calendar/device_calendar.dart';
import 'package:edit_calendar_event_view/extensions.dart';
import 'package:edit_calendar_event_view/recurrency_frequency.dart';
import 'package:edit_calendar_event_view/string_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


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
        title: Text('custom_recurrency'.localize()),
      ),
      body: ListView(
          padding: EdgeInsets.all(24),
          children: [
            Text('${'repeat_every'.localize()}:',
            style: headerTheme),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(child:_buildNumberPicker()),
                Expanded(child:_buildFrequencyPicker() ,),
              ],
            ),
            if (_frequency == RecurrenceFrequency.Monthly)
              _buildMonthRulePicker(),
            if (_frequency == RecurrenceFrequency.Weekly || (_frequency == RecurrenceFrequency.Monthly && monthRuleType == MonthRuleType.nthWeek))
              _buildWeekDaysPicker(),
            if (_frequency == RecurrenceFrequency.Weekly || (_frequency == RecurrenceFrequency.Monthly && monthRuleType == MonthRuleType.nthWeek))
            _buildSetPositionPicker(),
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('day_of_month'.localize()),
          ),
          MonthRuleType.nthWeek: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('week_of_month'.localize()),
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
        Text('${'select_day_of_the_week'.localize()}:',
        style: Theme.of(context).textTheme.bodyLarge,),
        Wrap(
          spacing: 8.0,
          children: List<Widget>.generate(7, (int index) {
            return ChoiceChip(
              label: Text(DateFormat.EEEE().format(DateTime(2018,1,1).add(Duration(days: index)))),
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
        Text('select_day_of_the_month'.localize(),
          style: Theme.of(context).textTheme.bodyLarge,),
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
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${'on_week_of_the_month'.localize()}:',
            style: Theme.of(context).textTheme.bodyLarge,),
          Wrap(
            spacing: 8.0,
            children: List<Widget>.generate(5, (int index) {
              return ChoiceChip(
                label: Text('${index + 1}_week'.localize()),
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
      ),
    );
  }

  Widget _buildMonthPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: sectionPadding,),
        Text('${'only_for_these_months'.localize()}:', style: headerTheme,),
        Wrap(
          spacing: 8.0,
          children: List<Widget>.generate(12, (int index) {
            return ChoiceChip(
              label: Text(index == 0 ? 'all'.localize() : DateFormat.MMM().format(DateTime(2018,1,15).add(Duration(days: 30 * (index - 1))))),
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
        Text('${'ends'.localize()}:', style: headerTheme,),
        RadioListTile(
          value: Ends.never,
          groupValue: ends,
          title: Text('never'.localize()),
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
                child: Text('on_s'.localize().replaceAll('%s', '').trim()),
              ),
              Expanded(
                child: ElevatedButton(
                  child: Text(DateFormat.yMMMMEEEEd().format(endDate ?? DateTime.now())),
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
          title: Row(children: [Text('for_n_events'.localize().split('%d').atIndexOrNull(0) ?? ''), Expanded(child:_buildCountPicker()), Text('for_n_events'.localize().split('%d').atIndexOrNull(1) ?? '')]),
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