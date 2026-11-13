import 'package:flutter/material.dart';
import 'package:fluent_icons_kit/fluent_icons_kit.dart';

import '../../../../app/localization/l10n_extension.dart';
import '../../../../app/theme/app_theme.dart';
import 'envelope_art.dart';

class EmptyLettersState extends StatelessWidget {
  const EmptyLettersState({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final palette = theme.extension<DearMePalette>()!;

    return Card(
      color: palette.heroStart.withValues(alpha: 0.64),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: palette.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const EnvelopeArt(width: 230),
            const SizedBox(height: 12),
            Text(
              l10n.emptyTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Text(
                l10n.emptyBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: onCreate,
              icon: Icon(FluentIcons.line.add),
              label: Text(l10n.emptyAction),
            ),
          ],
        ),
      ),
    );
  }
}
