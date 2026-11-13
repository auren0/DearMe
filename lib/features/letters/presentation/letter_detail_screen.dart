import 'package:flutter/material.dart';
import 'package:fluent_icons_kit/fluent_icons_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/app_date_format.dart';
import '../../../app/localization/l10n_extension.dart';
import '../../../app/providers.dart';
import '../../../app/snackbar.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/models/letter.dart';
import '../../../core/models/letter_status.dart';
import '../../../core/utils/countdown_format.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/content_width.dart';
import 'widgets/envelope_art.dart';
import 'widgets/status_pill.dart';

enum _DetailAction { reschedule, delete }

class LetterDetailScreen extends ConsumerStatefulWidget {
  const LetterDetailScreen({super.key, required this.letterId});

  final String letterId;

  @override
  ConsumerState<LetterDetailScreen> createState() => _LetterDetailScreenState();
}

class _LetterDetailScreenState extends ConsumerState<LetterDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _envelopeController;

  bool _revealed = false;
  bool _opening = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _envelopeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );
  }

  @override
  void dispose() {
    _envelopeController.dispose();
    super.dispose();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _openLetter(Letter letter) async {
    if (_opening || _revealed) {
      return;
    }
    setState(() => _opening = true);
    try {
      await _envelopeController.forward(from: 0);
      if (!mounted) {
        return;
      }
      setState(() {
        _revealed = true;
        _opening = false;
      });
      final result = await ref
          .read(lettersControllerProvider.notifier)
          .markOpened(letter);
      if (!mounted) {
        return;
      }
      if (result.notificationError != null) {
        showAppSnackBar(
          context.l10n.errorNotificationSchedule,
          isWarning: true,
        );
      }
    } on Object {
      if (mounted) {
        setState(() => _opening = false);
        showAppSnackBar(context.l10n.storageWriteError, isError: true);
      }
    }
  }

  Future<void> _reschedule(Letter letter) async {
    if (_busy) {
      return;
    }
    final current = letter.openAt?.toLocal();
    if (current == null) {
      return;
    }
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => _RescheduleDialog(initial: current),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(lettersControllerProvider.notifier)
          .updateSealed(
            letter: letter,
            title: letter.title,
            body: letter.body,
            openAt: selected.toUtc(),
          );
      if (!mounted) {
        return;
      }
      if (result.notificationError != null) {
        showAppSnackBar(
          context.l10n.errorNotificationSchedule,
          isWarning: true,
        );
      } else {
        showAppSnackBar(context.l10n.rescheduleSuccess);
      }
    } on Object {
      if (mounted) {
        showAppSnackBar(context.l10n.storageWriteError, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _delete(Letter letter) async {
    if (_busy) {
      return;
    }
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.detailDeleteTitle),
          content: Text(l10n.detailDeleteBody(letter.title)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(lettersControllerProvider.notifier).deleteLetter(letter);
      if (!mounted) {
        return;
      }
      showAppSnackBar(l10n.detailDeleted);
      context.go('/');
    } on Object {
      if (mounted) {
        showAppSnackBar(l10n.storageWriteError, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final letterAsync = ref.watch(letterByIdProvider(widget.letterId));
    final clock = ref.watch(clockProvider);
    final now = ref.watch(tickingNowProvider).value ?? clock();

    return letterAsync.when(
      loading: () => _DetailShell(
        onBack: _leave,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _DetailShell(
        onBack: _leave,
        child: _DetailMessage(
          icon: FluentIcons.line.warning,
          title: context.l10n.loadErrorTitle,
          body: context.l10n.storageError,
          actionLabel: context.l10n.detailBackHome,
          onAction: () => context.go('/'),
        ),
      ),
      data: (letter) {
        if (letter == null) {
          return _DetailShell(
            onBack: _leave,
            child: _DetailMessage(
              icon: FluentIcons.line.error_circle,
              title: context.l10n.detailNotFound,
              body: context.l10n.detailNotFoundBody,
              actionLabel: context.l10n.detailBackHome,
              onAction: () => context.go('/'),
            ),
          );
        }
        final status = letter.statusAt(now);
        final showContent = letter.openedAt != null || _revealed;
        final canReschedule =
            !showContent &&
            (status == LetterStatus.sealed || status == LetterStatus.ready);

        return _DetailShell(
          onBack: _leave,
          showMenu: true,
          canReschedule: canReschedule,
          canDelete: !_busy,
          onReschedule: () => _reschedule(letter),
          onDelete: () => _delete(letter),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 36,
            ),
            child: ContentWidth(
              maxWidth: 780,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: showContent
                    ? _OpenedLetter(
                        key: const ValueKey<String>('opened'),
                        letter: letter,
                        onDelete: () => _delete(letter),
                      )
                    : _SealedLetter(
                        key: const ValueKey<String>('sealed'),
                        letter: letter,
                        status: status,
                        now: now,
                        controller: _envelopeController,
                        opening: _opening,
                        onOpen: () => _openLetter(letter),
                        onReschedule: canReschedule
                            ? () => _reschedule(letter)
                            : null,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailShell extends StatelessWidget {
  const _DetailShell({
    required this.onBack,
    required this.child,
    this.showMenu = false,
    this.canReschedule = false,
    this.canDelete = false,
    this.onReschedule,
    this.onDelete,
  });

  final VoidCallback onBack;
  final Widget child;
  final bool showMenu;
  final bool canReschedule;
  final bool canDelete;
  final VoidCallback? onReschedule;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      body: AppBackground(
        showGlow: false,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: onBack,
                      tooltip: l10n.a11yBack,
                      icon: Icon(FluentIcons.line.arrow_left),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l10n.detailLetterFromPast,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (showMenu)
                      PopupMenuButton<_DetailAction>(
                        tooltip: l10n.a11yMore,
                        icon: Icon(FluentIcons.line.more_vertical),
                        onSelected: (action) {
                          switch (action) {
                            case _DetailAction.reschedule:
                              onReschedule?.call();
                            case _DetailAction.delete:
                              onDelete?.call();
                          }
                        },
                        itemBuilder: (context) =>
                            <PopupMenuEntry<_DetailAction>>[
                              if (canReschedule)
                                PopupMenuItem<_DetailAction>(
                                  value: _DetailAction.reschedule,
                                  child: Row(
                                    children: <Widget>[
                                      Icon(FluentIcons.line.calendar, size: 17),
                                      const SizedBox(width: 10),
                                      Text(l10n.detailReschedule),
                                    ],
                                  ),
                                ),
                              PopupMenuItem<_DetailAction>(
                                value: _DetailAction.delete,
                                enabled: canDelete,
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      FluentIcons.line.delete,
                                      size: 17,
                                      color: theme.colorScheme.error,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      l10n.detailDelete,
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _SealedLetter extends StatelessWidget {
  const _SealedLetter({
    super.key,
    required this.letter,
    required this.status,
    required this.now,
    required this.controller,
    required this.opening,
    required this.onOpen,
    this.onReschedule,
  });

  final Letter letter;
  final LetterStatus status;
  final DateTime now;
  final AnimationController controller;
  final bool opening;
  final VoidCallback onOpen;
  final VoidCallback? onReschedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final palette = theme.extension<DearMePalette>()!;
    final locale = l10n.localeName;
    final ready = status == LetterStatus.ready;

    return Column(
      children: <Widget>[
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return EnvelopeArt(
              width: 300,
              openProgress: controller.value,
              semanticLabel: ready
                  ? l10n.detailOpenButton
                  : l10n.detailSealedTitle,
            );
          },
        ),
        const SizedBox(height: 18),
        StatusPill(status: status),
        const SizedBox(height: 16),
        Text(
          letter.title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            ready
                ? l10n.detailReadyTitle
                : l10n.detailSealedBody(
                    AppDateFormatter.date(letter.createdAt, locale),
                    AppDateFormatter.dateTime(letter.openAt!, locale),
                  ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.65,
            ),
          ),
        ),
        if (!ready) ...<Widget>[
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: palette.heroStart.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      FluentIcons.line.timer,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      l10n.opensIn,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formatCountdown(letter.openAt!.difference(now), l10n),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppDateFormatter.dateTime(letter.openAt!, locale),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                FluentIcons.line.lock_closed,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  l10n.detailLockedHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (ready) ...<Widget>[
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: opening ? null : onOpen,
            icon: opening
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(FluentIcons.line.open),
            label: Text(l10n.detailOpenButton),
          ),
        ],
        if (onReschedule != null) ...<Widget>[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onReschedule,
            icon: Icon(FluentIcons.line.calendar, size: 17),
            label: Text(l10n.detailReschedule),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          l10n.detailWrittenAt(
            AppDateFormatter.dateTime(letter.createdAt, locale),
          ),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _OpenedLetter extends StatelessWidget {
  const _OpenedLetter({
    super.key,
    required this.letter,
    required this.onDelete,
  });

  final Letter letter;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final palette = theme.extension<DearMePalette>()!;
    final locale = l10n.localeName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            StatusPill(status: LetterStatus.opened),
            const Spacer(),
            Text(
              l10n.wordCount(letter.wordCount),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: palette.letterPaper,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: palette.cardBorder),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.28 : 0.07,
                ),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: 0,
                left: 24,
                right: 24,
                child: Container(
                  height: 3,
                  color: palette.glow.withValues(alpha: 0.65),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          FluentIcons.line.book_open,
                          size: 16,
                          color: palette.waxSeal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.detailLetterFromPast,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: palette.waxSeal,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SelectableText(
                      letter.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: palette.letterInk,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.detailWrittenAt(
                        AppDateFormatter.dateTime(letter.createdAt, locale),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.letterInk.withValues(alpha: 0.58),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 1,
                      color: palette.letterInk.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 22),
                    SelectableText(
                      letter.body,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: palette.letterInk,
                        fontSize: 18.5,
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: <Widget>[
                        Icon(
                          FluentIcons.line.heart,
                          size: 15,
                          color: palette.waxSeal.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            letter.openedAt == null
                                ? ''
                                : l10n.detailOpenedAt(
                                    AppDateFormatter.dateTime(
                                      letter.openedAt!,
                                      locale,
                                    ),
                                  ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.letterInk.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: <Widget>[
            TextButton.icon(
              onPressed: onDelete,
              icon: Icon(
                FluentIcons.line.delete,
                size: 17,
                color: theme.colorScheme.error,
              ),
              label: Text(
                l10n.detailDelete,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _RescheduleDialog extends StatefulWidget {
  const _RescheduleDialog({required this.initial});

  final DateTime initial;

  @override
  State<_RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<_RescheduleDialog> {
  late DateTime _value;
  String? _error;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _value.isBefore(now) ? now : _value;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 100),
      helpText: context.l10n.datePickerHelp,
      confirmText: context.l10n.done,
      cancelText: context.l10n.cancel,
      locale: Localizations.localeOf(context),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _value = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _value.hour,
        _value.minute,
      );
      _error = _value.isAfter(DateTime.now())
          ? null
          : context.l10n.editorOpenAtFuture;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_value),
      helpText: context.l10n.timePickerHelp,
      confirmText: context.l10n.done,
      cancelText: context.l10n.cancel,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _value = DateTime(
        _value.year,
        _value.month,
        _value.day,
        picked.hour,
        picked.minute,
      );
      _error = _value.isAfter(DateTime.now())
          ? null
          : context.l10n.editorOpenAtFuture;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = l10n.localeName;
    return AlertDialog(
      title: Text(l10n.rescheduleTitle),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _DialogChoice(
              icon: FluentIcons.line.calendar,
              value: AppDateFormatter.date(_value.toUtc(), locale),
              onTap: _pickDate,
            ),
            const SizedBox(height: 10),
            _DialogChoice(
              icon: FluentIcons.line.clock,
              value: AppDateFormatter.time(_value.toUtc(), locale),
              onTap: _pickTime,
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_value.isAfter(DateTime.now())) {
              setState(() => _error = l10n.editorOpenAtFuture);
              return;
            }
            Navigator.of(context).pop(_value);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _DialogChoice extends StatelessWidget {
  const _DialogChoice({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(value, style: theme.textTheme.titleSmall)),
              Icon(
                FluentIcons.line.chevron_right,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailMessage extends StatelessWidget {
  const _DetailMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ContentWidth(
        maxWidth: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 34, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
