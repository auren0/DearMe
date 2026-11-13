import 'package:flutter/material.dart';
import 'package:fluent_icons_kit/fluent_icons_kit.dart';

import 'app_keys.dart';

void showAppSnackBar(
  String message, {
  bool isError = false,
  bool isWarning = false,
}) {
  final messenger = rootScaffoldMessengerKey.currentState;
  if (messenger == null) {
    return;
  }
  final context = rootScaffoldMessengerKey.currentContext;
  final scheme = context == null ? null : Theme.of(context).colorScheme;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            Icon(
              isError
                  ? FluentIcons.line.error_circle
                  : isWarning
                  ? FluentIcons.line.warning
                  : FluentIcons.line.checkmark_circle,
              size: 18,
              color: scheme?.onInverseSurface,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
