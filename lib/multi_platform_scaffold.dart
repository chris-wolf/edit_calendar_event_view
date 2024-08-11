
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';

import 'common/common.dart';
import 'edit_calendar_event_page.dart';

class MultiPlatformScaffold extends StatelessWidget {
  final String? title;
  final Widget? body;
  final List<ToolbarItem>? macOsActions;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final Color? appBarColor;
  final PreferredSizeWidget? appBar;
  final bool? resizeToAvoidBottomInset;
  final Widget? macOsLeading;

  const MultiPlatformScaffold(
      {super.key,
        this.floatingActionButton,
        this.backgroundColor,
        this.appBarColor,
        this.appBar,
        this.resizeToAvoidBottomInset,
        this.actions,
        required this.body,
        this.macOsLeading,
        this.title,
        this.macOsActions});

  @override
  Widget build(BuildContext context) {
    if (MacosTheme.maybeOf(context) == null) {
      return Scaffold(
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        appBar: appBar ??
            AppBar(
              title: Text(title!),
              backgroundColor: appBarColor,
              actions: actions,
            ),
        backgroundColor: backgroundColor ?? EditCalendarEventPage.backgroundColor,
        body: Builder(builder: (context) {
          return body!;
        }),
        floatingActionButton: floatingActionButton,
      );
    } else {
      return MacosScaffold(
        toolBar: ToolBar(
            decoration: isUnifiedMacOsStyle() ? null : BoxDecoration(color: MediaQuery.platformBrightnessOf(context) == Brightness.light ? const Color.fromARGB(0xFF, 0xF5, 0xF1, 0xED) : const Color.fromARGB(0xFF, 0x34, 0x2A, 0x27)),
            title: Text(title!),
            centerTitle: true,
            leading: macOsLeading,
            actions: macOsActions),
        children: [
          ContentArea(
            builder: (context, scrollController) {
              return RawKeyboardListener(
                  onKey: (RawKeyEvent event) async {
                    if (event is RawKeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.escape) {
                        if (!ModalRoute.of(context)!.isFirst) {
                          Navigator.of(context).pop();
                        }
                      }
                    }
                  },
                  focusNode: FocusNode(),
                  child: Theme(
                      data: ThemeData(
                          brightness: MacosTheme.of(context).brightness),
                      child: Container(
                          color: MacosTheme.of(context).brightness == Brightness.light ? Colors.white : null, // background is weird beeche color https://github.com/macosui/macos_ui/issues/435
                          child: body!)),
              );
            },
            minWidth: 300,
          )
        ],
      );
    }
  }
}
