import 'package:edit_calendar_event_view/extensions.dart';
import 'package:edit_calendar_event_view/string_extensions.dart';
import 'package:flutter/material.dart';

class ColorPickerDialog {
  static Future<Color?> selectColorDialog(
      List<Color> colors, BuildContext context,
      {Color? selectedColor, canReset = false}) async {
    return await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {

        return AlertDialog(
          title: const Text('Select color'),
          contentPadding: const EdgeInsets.all(8.0),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    int columnCount = (constraints.maxWidth / 72).floor();
                    List<Widget> rows = [];
                    for (int i = 0; i < colors.length; i += columnCount) {
                      List<Widget> rowChildren = [];
                      for (int j = i;
                      j < i + columnCount && j < colors.length + colors.length % columnCount;
                      j++) {
                        final color = colors.atIndexOrNull(j);
                        if (color == null) {
                          rowChildren.add(const Expanded(child: SizedBox()));
                          continue;
                        }
                        bool isSelected = selectedColor == color;
                        rowChildren.add(
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: RawMaterialButton(
                                onPressed: () {
                                  Navigator.pop(context, color);
                                },
                                child: Container(
                                  margin: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color,
                                    border: isSelected
                                        ? Border.all(
                                      color: Colors.grey,
                                      width: 3,
                                    )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      rows.add(Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: rowChildren,
                      ));
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: rows,
                    );
                  },
                ),
            ),
          ),
          actions: [
            if (canReset && selectedColor != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(context, Colors.transparent);
                },
                child:  Text('reset'.localize()),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child:  Text('cancel'.localize()),
            ),
          ],
        );
      },
    );
  }}