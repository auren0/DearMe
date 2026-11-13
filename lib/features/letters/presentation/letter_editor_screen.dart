import 'dart:async';

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
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/content_width.dart';

class LetterEditorScreen extends ConsumerStatefulWidget {
  const LetterEditorScreen({super.key, this.letterId});

  final String? letterId;

  @override
  ConsumerState<LetterEditorScreen> createState() => _LetterEditorScreenState();
}

class _LetterEditorScreenState extends ConsumerState<LetterEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  Letter? _letter;
  DateTime? _openAtLocal;
  DateTime? _lastAutosavedAt;

  Timer? _autosaveTimer;
  AppLifecycleListener? _lifecycleListener;

  bool _initialized = false;
  bool _loadingScheduled = false;
  bool _dirty = false;
  bool _saving = false;
  bool _autosaveFailed = false;
  String? _dateError;

  bool get _isNew => widget.letterId == null;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onInactive: _flushOnLifecycle,
      onPause: _flushOnLifecycle,
      onHide: _flushOnLifecycle,
    );
    if (_isNew) {
      final now = ref.read(clockProvider)();
      _letter = Letter.create(now: now, isDraft: true);
      _openAtLocal = _defaultOpenAt(now.toLocal());
      _initialized = true;
      _attachTextListeners();
    }
  }

  DateTime _defaultOpenAt(DateTime localNow) {
    var target = DateTime(localNow.year + 1, localNow.month, localNow.day, 9);
    if (!target.isAfter(localNow)) {
      target = target.add(const Duration(days: 1));
    }
    return target;
  }

  void _attachTextListeners() {
    _titleController.addListener(_onTextChanged);
    _bodyController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _dirty = true;
    });
    _scheduleAutosave();
  }

  void _scheduleAutosave() {
    if (!_initialized || _saving) {
      return;
    }
    _autosaveTimer?.cancel();
    if (!_hasContent) {
      return;
    }
    _autosaveTimer = Timer(const Duration(milliseconds: 900), () {
      unawaited(_saveDraftSilently());
    });
  }

  bool get _hasContent =>
      _titleController.text.trim().isNotEmpty ||
      _bodyController.text.trim().isNotEmpty;

  Letter _compose({required bool isDraft}) {
    final now = ref.read(clockProvider)().toUtc();
    return _letter!.copyWith(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      openAt: _openAtLocal?.toUtc(),
      updatedAt: now,
      isDraft: isDraft,
    );
  }

  Future<bool> _saveDraftSilently() async {
    if (!mounted || !_initialized) {
      return false;
    }
    _autosaveTimer?.cancel();
    if (!_hasContent) {
      return true;
    }

    final candidate = _compose(isDraft: true);
    try {
      final saved = await ref
          .read(lettersControllerProvider.notifier)
          .saveDraft(candidate);
      if (!mounted) {
        return true;
      }
      final latest = _compose(isDraft: true);
      final changedSinceSave =
          latest.title != saved.title ||
          latest.body != saved.body ||
          latest.openAt != saved.openAt;
      setState(() {
        _letter = saved;
        _lastAutosavedAt = ref.read(clockProvider)();
        _autosaveFailed = false;
        _dirty = changedSinceSave;
      });
      if (changedSinceSave) {
        _scheduleAutosave();
      }
      return true;
    } on Object {
      if (mounted) {
        setState(() => _autosaveFailed = true);
      }
      return false;
    }
  }

  void _flushOnLifecycle() {
    if (_dirty && _initialized) {
      unawaited(_saveDraftSilently());
    }
  }

  void _loadLetter(Letter letter) {
    if (_loadingScheduled || _initialized) {
      return;
    }
    _loadingScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _letter = letter;
      _titleController.text = letter.title;
      _bodyController.text = letter.body;
      _openAtLocal =
          letter.openAt?.toLocal() ??
          _defaultOpenAt(ref.read(clockProvider)().toLocal());
      _initialized = true;
      _loadingScheduled = false;
      _attachTextListeners();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _lifecycleListener?.dispose();
    _titleController
      ..removeListener(_onTextChanged)
      ..dispose();
    _bodyController
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final l10n = context.l10n;
    final now = ref.read(clockProvider)().toLocal();
    final current = _openAtLocal ?? _defaultOpenAt(now);
    final initial = current.isBefore(now) ? now : current;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 100),
      helpText: l10n.datePickerHelp,
      confirmText: l10n.done,
      cancelText: l10n.cancel,
      locale: Localizations.localeOf(context),
    );
    if (picked == null || !mounted) {
      return;
    }
    final time = _openAtLocal ?? current;
    final updated = DateTime(
      picked.year,
      picked.month,
      picked.day,
      time.hour,
      time.minute,
    );
    setState(() {
      _openAtLocal = updated;
      _dirty = true;
      _dateError = updated.toUtc().isAfter(ref.read(clockProvider)())
          ? null
          : l10n.editorOpenAtFuture;
    });
    _scheduleAutosave();
  }

  Future<void> _pickTime() async {
    final l10n = context.l10n;
    final current = _openAtLocal ?? _defaultOpenAt(DateTime.now());
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: l10n.timePickerHelp,
      confirmText: l10n.done,
      cancelText: l10n.cancel,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    final updated = DateTime(
      current.year,
      current.month,
      current.day,
      picked.hour,
      picked.minute,
    );
    setState(() {
      _openAtLocal = updated;
      _dirty = true;
      _dateError = updated.toUtc().isAfter(ref.read(clockProvider)())
          ? null
          : l10n.editorOpenAtFuture;
    });
    _scheduleAutosave();
  }

  bool _validateOpenAt() {
    final l10n = context.l10n;
    final openAt = _openAtLocal;
    final now = ref.read(clockProvider)();
    if (openAt == null) {
      setState(() => _dateError = l10n.editorOpenAtRequired);
      return false;
    }
    if (!openAt.toUtc().isAfter(now)) {
      setState(() => _dateError = l10n.editorOpenAtFuture);
      return false;
    }
    setState(() => _dateError = null);
    return true;
  }

  Future<void> _sealLetter() async {
    final l10n = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!_validateOpenAt()) {
      return;
    }
    final openAt = _openAtLocal!;
    final dateText = AppDateFormatter.dateTime(openAt.toUtc(), l10n.localeName);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.saveConfirmTitle),
          content: Text(l10n.saveConfirmBody(dateText)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.saveConfirmAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    _autosaveTimer?.cancel();
    setState(() => _saving = true);
    try {
      final prepared = _compose(isDraft: false);
      final result = await ref
          .read(lettersControllerProvider.notifier)
          .seal(letter: prepared, openAt: openAt.toUtc());
      if (!mounted) {
        return;
      }
      if (result.notificationError != null) {
        showAppSnackBar(l10n.errorNotificationSchedule, isWarning: true);
      } else {
        showAppSnackBar(_isNew ? l10n.sealedSuccess : l10n.letterUpdated);
      }
      context.go('/letter/${result.letter.id}');
    } on Object {
      if (mounted) {
        showAppSnackBar(l10n.storageWriteError, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteDraft() async {
    final letter = _letter;
    if (_saving || letter == null || _isNew) {
      return;
    }
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.detailDeleteTitle),
        content: Text(
          l10n.detailDeleteBody(
            letter.title.trim().isEmpty ? l10n.statusDraft : letter.title,
          ),
        ),
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
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    _autosaveTimer?.cancel();
    setState(() => _saving = true);
    try {
      await ref.read(lettersControllerProvider.notifier).deleteLetter(letter);
      if (!mounted) {
        return;
      }
      showAppSnackBar(l10n.detailDeleted);
      await _leaveNow();
    } on Object {
      if (mounted) {
        showAppSnackBar(l10n.storageWriteError, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _saveDraftAndLeave() async {
    if (_saving) {
      return;
    }
    final l10n = context.l10n;
    final saved = await _saveDraftSilently();
    if (!saved) {
      if (mounted) {
        showAppSnackBar(l10n.autosaveFailed, isError: true);
      }
      return;
    }
    if (!mounted) {
      return;
    }
    showAppSnackBar(l10n.draftSaved);
    await _leaveNow();
  }

  Future<void> _attemptLeave() async {
    if (_saving) {
      return;
    }
    if (!_dirty && !_hasContent) {
      await _leaveNow();
      return;
    }
    final saved = await _saveDraftSilently();
    if (!saved) {
      if (mounted) {
        showAppSnackBar(context.l10n.autosaveFailed, isError: true);
      }
      return;
    }
    if (!mounted) {
      return;
    }
    if (_dirty && _hasContent) {
      // A save raced with another keystroke; try once more rather than losing
      // the most recent text.
      final retry = await _saveDraftSilently();
      if (!retry) {
        return;
      }
    }
    await _leaveNow();
  }

  Future<void> _leaveNow() async {
    if (!mounted) {
      return;
    }
    setState(() => _dirty = false);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isNew) {
      final existing = ref.watch(letterByIdProvider(widget.letterId!));
      return existing.when(
        loading: () => _EditorScaffold(
          title: context.l10n.editorEditTitle,
          onBack: _attemptLeave,
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => _EditorScaffold(
          title: context.l10n.editorEditTitle,
          onBack: _leaveNow,
          child: _EditorMessage(
            icon: FluentIcons.line.warning,
            title: context.l10n.loadErrorTitle,
            body: context.l10n.storageError,
            actionLabel: context.l10n.detailBackHome,
            onAction: _leaveNow,
          ),
        ),
        data: (letter) {
          if (letter == null) {
            return _EditorScaffold(
              title: context.l10n.editorEditTitle,
              onBack: _leaveNow,
              child: _EditorMessage(
                icon: FluentIcons.line.error_circle,
                title: context.l10n.detailNotFound,
                body: context.l10n.detailNotFoundBody,
                actionLabel: context.l10n.detailBackHome,
                onAction: _leaveNow,
              ),
            );
          }
          if (!letter.isDraft) {
            return _EditorScaffold(
              title: context.l10n.editorEditTitle,
              onBack: _leaveNow,
              child: _EditorMessage(
                icon: FluentIcons.line.lock_closed,
                title: context.l10n.detailSealedTitle,
                body: context.l10n.sealedEditNotAllowed,
                actionLabel: context.l10n.detailBackHome,
                onAction: _leaveNow,
              ),
            );
          }
          _loadLetter(letter);
          if (!_initialized) {
            return _EditorScaffold(
              title: context.l10n.editorEditTitle,
              onBack: _leaveNow,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          return _buildEditor();
        },
      );
    }
    return _buildEditor();
  }

  Widget _buildEditor() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.extension<DearMePalette>()!;
    final locale = l10n.localeName;
    final openAt = _openAtLocal;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          unawaited(_attemptLeave());
        }
      },
      child: _EditorScaffold(
        title: _isNew ? l10n.editorNewTitle : l10n.editorEditTitle,
        onBack: _attemptLeave,
        trailing: _AutosaveIndicator(
          failed: _autosaveFailed,
          lastSavedAt: _lastAutosavedAt,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom + 40,
          ),
          child: ContentWidth(
            maxWidth: 840,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: palette.heroStart.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.cardBorder),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        FluentIcons.line.edit,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          l10n.draftNotice,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TextFormField(
                            controller: _titleController,
                            textInputAction: TextInputAction.next,
                            maxLength: Letter.maxTitleLength,
                            textCapitalization: TextCapitalization.sentences,
                            style: theme.textTheme.titleLarge,
                            decoration: InputDecoration(
                              labelText: l10n.editorTitleLabel,
                              hintText: l10n.editorTitleHint,
                              counterText: '',
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return l10n.editorTitleRequired;
                              }
                              if (text.length > Letter.maxTitleLength) {
                                return l10n.editorTitleTooLong(
                                  Letter.maxTitleLength,
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              l10n.charCount(
                                _titleController.text.characters.length,
                                Letter.maxTitleLength,
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _bodyController,
                            minLines: 9,
                            maxLines: null,
                            maxLength: Letter.maxBodyLength,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              height: 1.7,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.editorBodyLabel,
                              hintText: l10n.editorBodyHint,
                              alignLabelWithHint: true,
                              counterText: '',
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return l10n.editorBodyRequired;
                              }
                              if (text.length > Letter.maxBodyLength) {
                                return l10n.editorBodyTooLong(
                                  Letter.maxBodyLength,
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              l10n.charCount(
                                _bodyController.text.characters.length,
                                Letter.maxBodyLength,
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              FluentIcons.line.calendar,
                              size: 19,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                l10n.editorOpenAt,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.editorOpenAtHelper,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final twoColumns = constraints.maxWidth >= 480;
                            final width = twoColumns
                                ? (constraints.maxWidth - 12) / 2
                                : constraints.maxWidth;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: <Widget>[
                                SizedBox(
                                  width: width,
                                  child: _DateTimeTile(
                                    icon: FluentIcons.line.calendar,
                                    label: l10n.editorOpenDate,
                                    value: openAt == null
                                        ? l10n.editorChooseDate
                                        : AppDateFormatter.date(
                                            openAt.toUtc(),
                                            locale,
                                          ),
                                    onTap: _pickDate,
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _DateTimeTile(
                                    icon: FluentIcons.line.clock,
                                    label: l10n.editorOpenTime,
                                    value: openAt == null
                                        ? l10n.editorChooseTime
                                        : AppDateFormatter.time(
                                            openAt.toUtc(),
                                            locale,
                                          ),
                                    onTap: _pickTime,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        if (_dateError != null) ...<Widget>[
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              Icon(
                                FluentIcons.line.error_circle,
                                size: 15,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _dateError!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 520;
                    final draftButton = TextButton.icon(
                      onPressed: _saving || !_hasContent
                          ? null
                          : _saveDraftAndLeave,
                      icon: Icon(FluentIcons.line.save),
                      label: Text(l10n.saveDraft),
                    );
                    final deleteDraftButton =
                        !_isNew && _letter?.isDraft == true
                        ? TextButton.icon(
                            onPressed: _saving ? null : _deleteDraft,
                            icon: Icon(
                              FluentIcons.line.delete,
                              size: 17,
                              color: theme.colorScheme.error,
                            ),
                            label: Text(
                              l10n.detailDelete,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          )
                        : null;
                    final sealButton = FilledButton.icon(
                      onPressed: _saving ? null : _sealLetter,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(FluentIcons.line.send),
                      label: Text(l10n.sealLetter),
                    );
                    if (!wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          sealButton,
                          const SizedBox(height: 8),
                          draftButton,
                          if (deleteDraftButton != null) ...<Widget>[
                            const SizedBox(height: 4),
                            deleteDraftButton,
                          ],
                        ],
                      );
                    }
                    return OverflowBar(
                      alignment: MainAxisAlignment.spaceBetween,
                      overflowAlignment: OverflowBarAlignment.end,
                      spacing: 8,
                      overflowSpacing: 8,
                      children: <Widget>[
                        ?deleteDraftButton,
                        draftButton,
                        sealButton,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorScaffold extends StatelessWidget {
  const _EditorScaffold({
    required this.title,
    required this.onBack,
    required this.child,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AppBackground(
        showGlow: false,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: onBack,
                          tooltip: context.l10n.a11yBack,
                          icon: Icon(FluentIcons.line.arrow_left),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                        if (constraints.maxWidth >= 560) ?trailing,
                        const SizedBox(width: 8),
                      ],
                    ),
                  );
                },
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _AutosaveIndicator extends StatelessWidget {
  const _AutosaveIndicator({required this.failed, required this.lastSavedAt});

  final bool failed;
  final DateTime? lastSavedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final savedText = lastSavedAt == null
        ? l10n.draftAutosaveHint
        : l10n.savedAt(AppDateFormatter.time(lastSavedAt!, l10n.localeName));
    final color = failed
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Row(
        key: ValueKey<String>(
          '${failed}_${lastSavedAt?.millisecondsSinceEpoch}',
        ),
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            failed
                ? FluentIcons.line.warning
                : FluentIcons.line.checkmark_circle,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              failed ? l10n.autosaveFailed : savedText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<DearMePalette>()!;
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: palette.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
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

class _EditorMessage extends StatelessWidget {
  const _EditorMessage({
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
