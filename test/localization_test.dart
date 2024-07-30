import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:edit_calendar_event_view/common/localized_map.dart';
import 'package:edit_calendar_event_view/string_extensions.dart';
import 'package:flutter_test/flutter_test.dart';
 const supportedLocales = [
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

void main() {
  final firstLocalizeValue = localizedMap.entries.first.value;

  test('MapEntryCount should be equal to locale count', () {
    expect(localizedMap.entries.first.value.length, supportedLocales.length);
  });

  test('Values count should be the same for all locales', () {
    final firstValuesCount = firstLocalizeValue.length;
    final differentLength = localizedMap.entries
        .any((element) => element.value.length != firstValuesCount);
    expect(differentLength, false);
  });

  test('Values count should be the same for all locales', () {
    localizedMap.entries.map((e) => e.value).forEach((element) {
      for (var entry in element.entries) {
        if (firstLocalizeValue.keys.contains(entry.key) == false) {
          print('does not contain key ${entry.key}');
          assert(false);
        }
      }
    });
  });

  test('All languages have same number of placeholders', () {
    bool error = false;

    final placeHolders = [
      '%s',
      '%0\$s',
      '%1\$s',
      '%2\$s',
      '%3\$s',
      '%d',
      '%0\$d',
      '%1\$d',
      '%2\$d',
      '%3\$d',
      // '_',
      //  '\n'
    ];

    for (var multiLanguagedMap in localizedMap.entries) {
      final outer = multiLanguagedMap.value.entries.first;
      for (var inner in multiLanguagedMap.value.entries) {
        if (inner.key == outer.key) {
          continue;
        }

        final text = inner.value;
        for (var placeHolder in placeHolders) {
          final innerTextMatches = placeHolder.allMatches(text).length;
          final outerTextMatches = placeHolder.allMatches(outer.value).length;
          if (innerTextMatches != outerTextMatches) {
            print(
                'different count of $placeHolder for  ${multiLanguagedMap.key}: \"${inner.value}\" ${inner.key}($innerTextMatches) and \"${outer.value}\" ${outer.key}($outerTextMatches)');
            error = true;
          }
        }
      }
    }
    if (error) {
      assert(false);
    }
  });

  test('All languages have same order of  placeholders', () {
    bool error = false;

    final placeHolders = [
      '%s',
      '%d',
    ];

    for (var multiLanguagedMap in localizedMap.entries) {
      final outer = multiLanguagedMap.value.entries.first;
      for (var inner in multiLanguagedMap.value.entries) {
        if (inner.key == outer.key) {
          continue;
        }

        final text = inner.value;
        List<(String, int)> innerPlaceholderIndexes = [];
        List<(String, int)> outerPlaceholderIndexes = [];

        for (var placeHolder in placeHolders) {
          final innerTextMatches = placeHolder.allMatches(text);
          if (innerTextMatches.length > 2) {
            print(
                'multiple $placeHolder placeholders in string ${multiLanguagedMap.key}: \"${inner.value}\" ${inner.key}($innerTextMatches)');
            error = true;
          }
          final outerTextMatches = placeHolder.allMatches(outer.value);
          if (innerTextMatches.isNotEmpty) {
            innerPlaceholderIndexes
                .add((placeHolder, innerTextMatches.first.start));
            outerPlaceholderIndexes
                .add((placeHolder, outerTextMatches.first.start));
          }
        }
        // Sort by index positions
        innerPlaceholderIndexes.sort((a, b) => a.$2.compareTo(b.$2));
        outerPlaceholderIndexes.sort((a, b) => a.$2.compareTo(b.$2));

        // Compare placeholder positions
        if (innerPlaceholderIndexes.asMap().entries.any((element) =>
            element.value.$1 != outerPlaceholderIndexes[element.key].$1)) {
          print(
              'Warning: Placeholder order mismatch in ${multiLanguagedMap.key} between ${inner.key} and ${outer.key}:\n${inner.value} and ${outer.value}\nmake sure to use stringFormatter() method instead of sprinft() to handle this correctly');
        }
      }
    }
    if (error) {
      assert(false);
    }
  });

  test('%i is no valid format, use %d instead', () {
    for (var element in localizedMap.entries) {
      final allStringsString = element.value.entries.map((e) => e.value).join();
      if (allStringsString.contains('%i')) {
        assert(false);
      }
    }
  });

  test('has EmptyString as localized value', () {
    for (var element in localizedMap.entries) {
      final emptyStringList = element.value.entries
          .where((e) => e.value == '' && e.key != 'noti fication_at_time')
          .toList();
      if (emptyStringList.isNotEmpty) {
        print(
            "EmptyString for language ${element.key} and key ${emptyStringList.map((e) => e.key).join(", ")}");
        assert(false);
      }
    }
  });
}
