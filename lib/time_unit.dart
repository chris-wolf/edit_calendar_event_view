
import 'package:edit_calendar_event_view/string_extensions.dart';
import 'package:sprintf/sprintf.dart';

enum TimeUnit { minutes, hours, days, weeks;
  String title() {
    return sprintf('s_before'.localize(), [
      sprintf('n_$name'.localize(), [0])
    ]).replaceAll('0', '').trim();
  }
}