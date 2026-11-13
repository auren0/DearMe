import 'package:flutter/material.dart';
import 'package:fluent_icons_kit/fluent_icons_kit.dart';

import '../../../../app/localization/app_date_format.dart';
import '../../../../app/localization/l10n_extension.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/letter.dart';
import '../../../../core/models/letter_status.dart';
import '../../../../core/utils/countdown_format.dart';
import 'status_pill.dart';

class LetterCard extends StatelessWidget {
  const LetterCard({
    super.key,
    required this.letter,
    required this.now,
    required this.onTap,
  });

  final Letter letter;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final palette = theme.extension<DearMePalette>()!;
    final scheme = theme.colorScheme;
    final status = letter.statusAt(now);
    final locale = l10n.localeName;

    final (icon, accentColor) = switch (status) {
      LetterStatus.sealed => (FluentIcons.line.lock_closed, scheme.secondary),
      LetterStatus.ready => (FluentIcons.line.open, scheme.primary),
      LetterStatus.opened => (
        FluentIcons.line.mail_read,
        scheme.onSurfaceVariant,
      ),
      LetterStatus.draft => (FluentIcons.line.edit, scheme.tertiary),
    };

    final secondaryLine = switch (status) {
      LetterStatus.sealed => l10n.opensOn(
        AppDateFormatter.dateTime(letter.openAt!, locale),
      ),
      LetterStatus.ready => l10n.opensNow,
      LetterStatus.opened => l10n.openedOn(
        AppDateFormatter.dateTime(letter.openedAt!, locale),
      ),
      LetterStatus.draft =>
        letter.openAt == null
            ? l10n.editorOpenAtRequired
            : l10n.opensOn(AppDateFormatter.dateTime(letter.openAt!, locale)),
    };

    final card = Card(
      color: status == LetterStatus.ready
          ? Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.055),
              scheme.surfaceContainerLow,
            )
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: status == LetterStatus.ready
              ? scheme.primary.withValues(alpha: 0.55)
              : palette.cardBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: accentColor, size: 21),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: StatusPill(status: status),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                letter.title.trim().isEmpty ? l10n.statusDraft : letter.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Icon(
                    FluentIcons.line.calendar,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.createdOn(
                        AppDateFormatter.date(letter.createdAt, locale),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Icon(
                    status == LetterStatus.opened
                        ? FluentIcons.line.mail_read
                        : FluentIcons.line.clock,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      secondaryLine,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: status == LetterStatus.ready
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        fontWeight: status == LetterStatus.ready
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              if (status == LetterStatus.sealed) ...<Widget>[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        FluentIcons.line.timer,
                        size: 15,
                        color: scheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        l10n.opensIn,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          formatCountdown(letter.openAt!.difference(now), l10n),
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (status == LetterStatus.ready) ...<Widget>[
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Text(
                      l10n.detailOpenButton,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      FluentIcons.line.chevron_right,
                      size: 16,
                      color: scheme.primary,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: l10n.a11yLetterCard(
        letter.title.trim().isEmpty ? l10n.statusDraft : letter.title,
        switch (status) {
          LetterStatus.sealed => l10n.statusSealed,
          LetterStatus.ready => l10n.statusReady,
          LetterStatus.opened => l10n.statusOpened,
          LetterStatus.draft => l10n.statusDraft,
        },
      ),
      child: ExcludeSemantics(child: card),
    );
  }
}
