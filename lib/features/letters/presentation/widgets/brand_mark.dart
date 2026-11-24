import 'package:flutter/material.dart';

import '../../../../app/localization/l10n_extension.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false, this.showTagline = true});

  final bool compact;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          l10n.appName,
          style:
              (compact
                      ? theme.textTheme.headlineSmall
                      : theme.textTheme.headlineMedium)
                  ?.copyWith(letterSpacing: 0.4, fontWeight: FontWeight.w600),
        ),
        if (showTagline)
          Text(
            l10n.appTagline,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.1,
            ),
          ),
      ],
    );
  }
}
