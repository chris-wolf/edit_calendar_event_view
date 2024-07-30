


import 'package:collection/collection.dart';

import 'package:intl/intl.dart';

import 'common/localized_map.dart';

class EditEventLocalization {

static String localize(String key, {String? testLocale}) {
  final locale = testLocale ?? Intl.getCurrentLocale();
  final translateMap = localizedMap[key];
  if (translateMap == null) {
    return key;
  }
  if (translateMap.containsKey(locale)) {
    return translateMap[locale] ?? key;
  }
  final localeSplitted = locale.split('_');
  if (translateMap.containsKey(localeSplitted.first)) {
    return translateMap[localeSplitted.first] ?? key;
  }
  final langKey = translateMap.keys.firstWhereOrNull(
        (element) => element.startsWith('${localeSplitted.first}_'),
  );
  if (langKey != null) {
    return translateMap[localeSplitted.first] ?? key;
  }
  return key;
}
}
