import 'package:flutter/material.dart';
import 'package:fluent_icons_kit/fluent_icons_kit.dart';

import '../../../../app/localization/l10n_extension.dart';
import '../../../../core/models/letter_status.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final LetterStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final scheme = theme.colorScheme;

    final (
      Color background,
      Color foreground,
      IconData icon,
      String label,
    ) = switch (status) {
      LetterStatus.sealed => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        FluentIcons.line.lock_closed,
        l10n.statusSealed,
      ),
      LetterStatus.ready => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        FluentIcons.line.open,
        l10n.statusReady,
      ),
      LetterStatus.opened => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
        FluentIcons.line.mail_read,
        l10n.statusOpened,
      ),
      LetterStatus.draft => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        FluentIcons.line.edit,
        l10n.statusDraft,
      ),
    };

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground,
                  letterSpacing: 0.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
