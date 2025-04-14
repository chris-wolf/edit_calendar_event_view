import 'package:devicelocale/devicelocale.dart';
import 'package:edit_calendar_event_view/edit_calendar_event_view.dart';
import 'package:edit_calendar_event_view/edit_calendar_event_view_method_channel.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  Event? event;
  static const supportedLocales = [
    Locale('en'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
    Locale('it'),
    Locale('nl'),
    Locale('pl'),
    Locale('ru'),
    Locale('ja'),
    Locale('zh'),
    Locale('pt', 'BR'),
    Locale('bg'),
    Locale('cs'),
    Locale('da'),
    Locale('et'),
    Locale('fi'),
    Locale('el'),
    Locale('hu'),
    Locale('lv'),
    Locale('lt'),
    Locale('ro'),
    Locale('sk'),
    Locale('sl'),
    Locale('sv'),
    Locale('hi'),
    Locale('af'),
    Locale('sq'),
    Locale('am'),
    Locale('ar'),
    Locale('hy'),
    Locale('az'),
    Locale('bn'),
    Locale('eu'),
    Locale('be'),
    Locale('my'),
    Locale('ca'),
    Locale('hr'),
    Locale('is'),
    Locale('id'),
    Locale('kn'),
    Locale('kk'),
    Locale('km'),
    Locale('ko'),
    Locale('ky'),
    Locale('lo'),
    Locale('mk'),
    Locale('ms'),
    Locale('ml'),
    Locale('mr'),
    Locale('mn'),
    Locale('ne'),
    Locale('no'),
    Locale('fa'),
    Locale('pa'),
    Locale('si'),
    Locale('ta'),
    Locale('te'),
    Locale('th'),
    Locale('tr'),
    Locale('uk'),
    Locale('ur'),
    Locale('vi'),
    Locale('zu'),
    Locale('fil'),
    Locale('gl'),
    Locale('ka'),
    Locale('he'),
    Locale('sr'),
    Locale('gu'),
    Locale('sw')
  ];


  @override
  void initState() {
    loadDeviceLocale();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        localizationsDelegates: const  [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: supportedLocales,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Add/Edit Event Example'),
        ),
        body: StatefulBuilder(
          builder: (context,setState) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final result = await EditCalendarEventView.addOrEditCalendarEvent(context, title: "exampleTitle");
                        setState(() {
                          switch(result.resultType) {
                            case ResultType.saved:
                              event = result.event;
                              break;
                            case ResultType.deleted:
                              event = null;
                              break;
                            case ResultType.canceled:
                              break;
                          }
                        });
                      },
                      child: const Text('Add event'),
                    ),
                    if (event != null)
                    ElevatedButton(
                      onPressed: () async {
                        final result = await EditCalendarEventView.addOrEditCalendarEvent(context, eventId: event?.eventId);
                        setState(() {
                          switch(result.resultType) {
                            case ResultType.saved:
                              event = result.event;
                              break;
                            case ResultType.deleted:
                              event = null;
                              break;
                            case ResultType.canceled:
                              break;
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text('Edit event\n${event?.eventId}',
                        textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ),
              ),
                  );
          }
        ),
    ));
  }


  Locale deviceLocale = Locale('en');
  void loadDeviceLocale() async {
    deviceLocale = await Devicelocale.currentAsLocale ?? const Locale('en');
    final supportedLocales = dateTimeSymbolMap();
    if (supportedLocales[deviceLocale.toString()] != null) {
      Intl.defaultLocale = deviceLocale.toString();
    } else if (supportedLocales[deviceLocale.languageCode] != null) {
      Intl.defaultLocale = deviceLocale.languageCode;
    }
  }
}
