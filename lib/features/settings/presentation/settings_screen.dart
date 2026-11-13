import 'package:flutter/material.dart';
import 'package:fluent_icons_kit/fluent_icons_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/l10n_extension.dart';
import '../../../app/providers.dart';
import '../../../app/snackbar.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/models/app_locale_option.dart';
import '../../../core/models/app_theme_option.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/platform_info.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../letters/data/letter_transfer_service.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/content_width.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;
  bool _requestingPermission = false;
  bool _sendingTest = false;

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _setTheme(AppThemeOption option) async {
    try {
      await ref.read(settingsControllerProvider.notifier).setTheme(option);
    } on Object {
      if (mounted) {
        showAppSnackBar(context.l10n.settingsSaveError, isError: true);
      }
    }
  }

  Future<void> _setLocale(AppLocaleOption option) async {
    final current = ref.read(settingsControllerProvider).locale;
    if (current == option) {
      return;
    }
    try {
      await ref.read(settingsControllerProvider.notifier).setLocale(option);
      if (!mounted) {
        return;
      }
      final error = await ref
          .read(letterServiceProvider)
          .synchronizeSchedules();
      if (!mounted) {
        return;
      }
      if (error != null) {
        showAppSnackBar(
          context.l10n.errorNotificationSchedule,
          isWarning: true,
        );
      }
    } on Object {
      if (mounted) {
        showAppSnackBar(context.l10n.settingsSaveError, isError: true);
      }
    }
  }

  Future<void> _markPermissionRequested() async {
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .setNotificationPermissionRequested(true);
    } on Object {
      // The permission prompt already happened; failing to remember that fact
      // must not block the actual notification flow.
    }
  }

  Future<void> _toggleNotifications(bool enable) async {
    if (_busy) {
      return;
    }
    final service = ref.read(letterServiceProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    if (!enable) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.notificationDisableConfirmTitle),
          content: Text(context.l10n.notificationDisableConfirmBody),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.disable),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }
      setState(() => _busy = true);
      try {
        await controller.setNotificationsEnabled(false);
        await service.cancelAll();
      } on Object {
        if (mounted) {
          showAppSnackBar(context.l10n.settingsSaveError, isError: true);
        }
      } finally {
        if (mounted) {
          setState(() => _busy = false);
          ref.invalidate(notificationPermissionProvider);
        }
      }
      return;
    }

    setState(() => _busy = true);
    try {
      // Ask immediately from the user's tap; some browsers only show the
      // permission prompt during a direct user gesture.
      final permission = await service.requestPermission();
      await _markPermissionRequested();
      if (!mounted) {
        return;
      }
      ref.invalidate(notificationPermissionProvider);
      if (!permission.isGranted) {
        showAppSnackBar(
          context.l10n.errorNotificationPermission,
          isError: true,
        );
        return;
      }
      await controller.setNotificationsEnabled(true);
      final error = await service.synchronizeSchedules();
      if (!mounted) {
        return;
      }
      if (error != null) {
        showAppSnackBar(
          context.l10n.errorNotificationSchedule,
          isWarning: true,
        );
      }
    } on Object {
      if (mounted) {
        showAppSnackBar(context.l10n.settingsSaveError, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _requestPermission() async {
    if (_requestingPermission) {
      return;
    }
    setState(() => _requestingPermission = true);
    try {
      final service = ref.read(letterServiceProvider);
      final permission = await service.requestPermission();
      await _markPermissionRequested();
      if (!mounted) {
        return;
      }
      ref.invalidate(notificationPermissionProvider);
      if (permission.isGranted) {
        final settings = ref.read(settingsControllerProvider);
        if (settings.notificationsEnabled) {
          await service.synchronizeSchedules();
        }
      } else {
        showAppSnackBar(
          context.l10n.errorNotificationPermission,
          isError: true,
        );
      }
    } on Object {
      if (mounted) {
        showAppSnackBar(
          context.l10n.errorNotificationPermission,
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _requestingPermission = false);
      }
    }
  }

  Future<void> _testNotification() async {
    if (_sendingTest) {
      return;
    }
    setState(() => _sendingTest = true);
    try {
      final permission = await ref
          .read(letterServiceProvider)
          .permissionStatus();
      if (!mounted) {
        return;
      }
      if (!permission.isGranted) {
        showAppSnackBar(
          context.l10n.testNotificationNeedsPermission,
          isWarning: true,
        );
        return;
      }
      final sent = await ref.read(letterServiceProvider).showTestNotification();
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        sent
            ? context.l10n.testNotificationSent
            : context.l10n.testNotificationFailed,
        isError: !sent,
      );
    } on Object {
      if (mounted) {
        showAppSnackBar(context.l10n.testNotificationFailed, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _sendingTest = false);
      }
    }
  }

  Future<void> _openSystemSettings() async {
    final opened = await ref
        .read(letterServiceProvider)
        .openSystemNotificationSettings();
    if (!mounted || opened) {
      return;
    }
    showAppSnackBar(context.l10n.systemSettingsUnavailable, isWarning: true);
  }

  Future<void> _exportLetters() async {
    if (_busy) {
      return;
    }
    final letters = ref.read(lettersControllerProvider).value ?? const [];
    final l10n = context.l10n;
    if (letters.isEmpty) {
      showAppSnackBar(l10n.errorNoLettersToExport, isWarning: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final saved = await ref
          .read(letterTransferServiceProvider)
          .exportLetters(letters);
      if (saved && mounted) {
        showAppSnackBar(l10n.exportSuccess);
      }
    } on Object {
      if (mounted) {
        showAppSnackBar(l10n.exportFailed, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _importLetters() async {
    if (_busy) {
      return;
    }
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final letters = await ref
          .read(letterTransferServiceProvider)
          .pickForImport();
      if (!mounted || letters == null) {
        return;
      }
      if (letters.isEmpty) {
        showAppSnackBar(l10n.importEmpty, isWarning: true);
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.importConfirmTitle),
          content: Text(l10n.importConfirmBody(letters.length)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.importConfirmAction),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }
      final result = await ref
          .read(lettersControllerProvider.notifier)
          .importLetters(letters);
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        '${l10n.importSuccess} '
        '${l10n.importResult(result.imported, result.updated, result.skipped)}',
      );
    } on InvalidBackupException {
      if (mounted) {
        showAppSnackBar(l10n.importInvalid, isError: true);
      }
    } on FormatException {
      if (mounted) {
        showAppSnackBar(l10n.errorImportParse, isError: true);
      }
    } on Object {
      if (mounted) {
        showAppSnackBar(l10n.importFailed, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _deleteAll() async {
    if (_busy) {
      return;
    }
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          _DeleteAllDialog(confirmWord: l10n.deleteAllConfirmWord),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(lettersControllerProvider.notifier).deleteAllLetters();
      await ref.read(settingsControllerProvider.notifier).resetToDefaults();
      await ref.read(letterServiceProvider).cancelAll();
      if (!mounted) {
        return;
      }
      showAppSnackBar(l10n.dataDeleted);
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

  Future<void> _showPrivacy() {
    final l10n = context.l10n;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.aboutPrivacy),
        content: Text(l10n.aboutPrivacyBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showLicenses() {
    final l10n = context.l10n;
    final packageInfo = ref.read(packageInfoProvider).value;
    final version = packageInfo == null
        ? ''
        : '${packageInfo.version} (${packageInfo.buildNumber})';
    showLicensePage(
      context: context,
      applicationName: l10n.appName,
      applicationVersion: version,
      applicationLegalese: l10n.aboutMadeWith,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final stats = ref.watch(letterStatisticsProvider);
    final permissionAsync = ref.watch(notificationPermissionProvider);
    final platformInfo = ref.watch(letterServiceProvider).platformInfo;
    final l10n = context.l10n;

    return Scaffold(
      body: AppBackground(
        showGlow: false,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: _leave,
                      tooltip: l10n.a11yBack,
                      icon: Icon(FluentIcons.line.arrow_left),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l10n.settingsTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    if (_busy)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 40,
                  ),
                  child: ContentWidth(
                    maxWidth: 920,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _SectionCard(
                          title: l10n.settingsAppearance,
                          icon: FluentIcons.line.paint_brush,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final columns = constraints.maxWidth >= 620
                                      ? 3
                                      : 1;
                                  const spacing = 12.0;
                                  final width =
                                      (constraints.maxWidth -
                                          spacing * (columns - 1)) /
                                      columns;
                                  return Wrap(
                                    spacing: spacing,
                                    runSpacing: spacing,
                                    children: <Widget>[
                                      for (final option
                                          in AppThemeOption.values)
                                        SizedBox(
                                          width: width,
                                          child: _ThemeChoice(
                                            option: option,
                                            selected: settings.theme == option,
                                            onTap: () => _setTheme(option),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _SectionCard(
                          title: l10n.settingsLanguage,
                          icon: FluentIcons.line.translate,
                          children: <Widget>[
                            for (final option in AppLocaleOption.values)
                              _ChoiceTile(
                                title: option == AppLocaleOption.russian
                                    ? l10n.languageRu
                                    : l10n.languageEn,
                                selected: settings.locale == option,
                                onTap: () => _setLocale(option),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _SectionCard(
                          title: l10n.settingsNotifications,
                          icon: FluentIcons.line.alert,
                          children: <Widget>[
                            SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              title: Text(l10n.settingsNotificationsEnabled),
                              subtitle: Text(
                                l10n.settingsNotificationsDescription,
                              ),
                              value: settings.notificationsEnabled,
                              onChanged: _busy ? null : _toggleNotifications,
                            ),
                            const Divider(),
                            _SettingsTile(
                              icon: FluentIcons.line.shield,
                              title: l10n.notificationPermissionStatus,
                              subtitle: _permissionLabel(
                                permissionAsync.value,
                                l10n,
                              ),
                              trailing: IconButton(
                                tooltip: l10n.refresh,
                                onPressed: () => ref.invalidate(
                                  notificationPermissionProvider,
                                ),
                                icon: Icon(
                                  FluentIcons.line.arrow_sync,
                                  size: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              onTap: _requestingPermission
                                  ? null
                                  : _requestPermission,
                            ),
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                16,
                              ),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: <Widget>[
                                  OutlinedButton.icon(
                                    onPressed: _requestingPermission
                                        ? null
                                        : _requestPermission,
                                    icon: _requestingPermission
                                        ? const SizedBox(
                                            width: 15,
                                            height: 15,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(
                                            FluentIcons.line.shield,
                                            size: 17,
                                          ),
                                    label: Text(l10n.requestPermission),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _sendingTest
                                        ? null
                                        : _testNotification,
                                    icon: _sendingTest
                                        ? const SizedBox(
                                            width: 15,
                                            height: 15,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(
                                            FluentIcons.line.alert,
                                            size: 17,
                                          ),
                                    label: Text(l10n.testNotification),
                                  ),
                                  if (platformInfo.supportsSystemSettings)
                                    TextButton.icon(
                                      onPressed: _openSystemSettings,
                                      icon: Icon(
                                        FluentIcons.line.settings,
                                        size: 17,
                                      ),
                                      label: Text(l10n.openSystemSettings),
                                    ),
                                ],
                              ),
                            ),
                            _PlatformNote(
                              text: _notificationNote(context, platformInfo),
                            ),
                            if (platformInfo.isWeb)
                              _PushServerTile(platformInfo: platformInfo),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _SectionCard(
                          title: l10n.settingsData,
                          icon: FluentIcons.line.document,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final columns = constraints.maxWidth >= 560
                                      ? 4
                                      : 2;
                                  const spacing = 10.0;
                                  final width =
                                      (constraints.maxWidth -
                                          spacing * (columns - 1)) /
                                      columns;
                                  final items = <Widget>[
                                    _DataStat(
                                      value: stats.total,
                                      label: l10n.dataLetters,
                                    ),
                                    _DataStat(
                                      value: stats.opened,
                                      label: l10n.dataOpened,
                                    ),
                                    _DataStat(
                                      value: stats.sealed + stats.ready,
                                      label: l10n.dataSealed,
                                    ),
                                    _DataStat(
                                      value: stats.drafts,
                                      label: l10n.dataDrafts,
                                    ),
                                  ];
                                  return Wrap(
                                    spacing: spacing,
                                    runSpacing: spacing,
                                    children: <Widget>[
                                      for (final item in items)
                                        SizedBox(width: width, child: item),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const Divider(),
                            _SettingsTile(
                              icon: FluentIcons.line.arrow_export,
                              title: l10n.exportData,
                              subtitle: l10n.exportDescription,
                              onTap: _busy ? null : _exportLetters,
                            ),
                            const Divider(),
                            _SettingsTile(
                              icon: FluentIcons.line.arrow_import,
                              title: l10n.importData,
                              subtitle: l10n.importDescription,
                              onTap: _busy ? null : _importLetters,
                            ),
                            const Divider(),
                            _SettingsTile(
                              icon: FluentIcons.line.delete,
                              title: l10n.deleteAllData,
                              subtitle: l10n.deleteAllDescription,
                              destructive: true,
                              onTap: _busy ? null : _deleteAll,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _AboutSection(
                          onLicenses: _showLicenses,
                          onPrivacy: _showPrivacy,
                        ),
                        const SizedBox(height: 28),
                        Center(
                          child: Text(
                            l10n.aboutMadeWith,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _permissionLabel(
    NotificationPermissionStatus? status,
    AppLocalizations l10n,
  ) {
    return switch (status) {
      NotificationPermissionStatus.granted => l10n.permissionGranted,
      NotificationPermissionStatus.denied => l10n.permissionDenied,
      NotificationPermissionStatus.notDetermined =>
        l10n.permissionNotDetermined,
      NotificationPermissionStatus.unsupported ||
      null => l10n.permissionUnsupported,
    };
  }

  String _notificationNote(
    BuildContext context,
    NotificationPlatformInfo info,
  ) {
    final l10n = context.l10n;
    if (info.isWeb) {
      return info.supportsWebPush
          ? l10n.notificationLimitationsWeb
          : l10n.notificationLimitationsWebUnsupported;
    }
    if (PlatformInfo.isLinux) {
      return l10n.notificationLimitationsLinux;
    }
    if (PlatformInfo.isIOS) {
      return l10n.notificationLimitationsIos;
    }
    if (PlatformInfo.isAndroid) {
      return l10n.notificationLimitationsAndroid;
    }
    if (PlatformInfo.isWindows) {
      return l10n.notificationLimitationsWindows;
    }
    if (PlatformInfo.isMacOS) {
      return l10n.notificationLimitationsMacos;
    }
    return l10n.notificationLimitationsNone;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<DearMePalette>()!;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 19, color: theme.colorScheme.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: Container(
              height: 1,
              color: palette.cardBorder.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(title, style: destructive ? TextStyle(color: color) : null),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing:
          trailing ??
          (onTap == null
              ? null
              : Icon(
                  FluentIcons.line.chevron_right,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                )),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppThemeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final preview = AppTheme.of(option);
    final scheme = preview.colorScheme;
    final label = switch (option) {
      AppThemeOption.light => l10n.themeLight,
      AppThemeOption.dark => l10n.themeDark,
      AppThemeOption.oled => l10n.themeOled,
    };
    final description = switch (option) {
      AppThemeOption.light => l10n.themeLightDescription,
      AppThemeOption.dark => l10n.themeDarkDescription,
      AppThemeOption.oled => l10n.themeOledDescription,
    };
    return Semantics(
      selected: selected,
      label: l10n.a11yThemeSelected(label),
      button: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 68,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        left: 10,
                        top: 10,
                        right: 38,
                        child: Container(
                          height: 7,
                          decoration: BoxDecoration(
                            color: scheme.onSurface.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 24,
                        right: 52,
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: scheme.onSurface.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        bottom: 11,
                        child: Container(
                          width: 40,
                          height: 16,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(label, style: theme.textTheme.titleSmall),
                    ),
                    if (selected)
                      Icon(
                        FluentIcons.line.checkmark_circle,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          FluentIcons.line.globe,
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(title),
        trailing: selected
            ? Icon(
                FluentIcons.line.checkmark,
                size: 17,
                color: theme.colorScheme.primary,
              )
            : null,
      ),
    );
  }
}

class _PlatformNote extends StatelessWidget {
  const _PlatformNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            FluentIcons.line.info,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PushServerTile extends ConsumerWidget {
  const _PushServerTile({required this.platformInfo});

  final NotificationPlatformInfo platformInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final statusAsync = ref.watch(pushServerStatusProvider);
    final status = statusAsync.value;
    final (String label, Color color, IconData icon) = switch (status) {
      PushServerStatus.connected => (
        l10n.pushServerConnected,
        theme.colorScheme.primary,
        FluentIcons.line.cloud,
      ),
      PushServerStatus.notConfigured => (
        l10n.pushServerNotConfigured,
        theme.colorScheme.onSurfaceVariant,
        FluentIcons.line.info,
      ),
      PushServerStatus.unreachable => (
        l10n.pushServerError,
        theme.colorScheme.error,
        FluentIcons.line.warning,
      ),
      null => (
        l10n.loading,
        theme.colorScheme.onSurfaceVariant,
        FluentIcons.line.cloud,
      ),
      PushServerStatus.notApplicable => (
        l10n.permissionUnsupported,
        theme.colorScheme.onSurfaceVariant,
        FluentIcons.line.info,
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.pushServerStatus,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall?.copyWith(color: color),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => ref.invalidate(pushServerStatusProvider),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      FluentIcons.line.arrow_sync,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (!platformInfo.webPushConfigured) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                l10n.pushServerNotConfiguredHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DataStat extends StatelessWidget {
  const _DataStat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends ConsumerWidget {
  const _AboutSection({required this.onLicenses, required this.onPrivacy});

  final VoidCallback onLicenses;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final packageInfo = ref.watch(packageInfoProvider).value;
    final version = packageInfo == null
        ? '—'
        : '${packageInfo.version} (${packageInfo.buildNumber})';

    return _SectionCard(
      title: l10n.settingsAbout,
      icon: FluentIcons.line.info,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.appDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.aboutVersion(version),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _SettingsTile(
          icon: FluentIcons.line.shield,
          title: l10n.aboutPrivacy,
          subtitle: l10n.aboutPrivacyBody,
          onTap: onPrivacy,
        ),
        _SettingsTile(
          icon: FluentIcons.line.document,
          title: l10n.aboutLicenses,
          onTap: onLicenses,
        ),
      ],
    );
  }
}

class _DeleteAllDialog extends StatefulWidget {
  const _DeleteAllDialog({required this.confirmWord});

  final String confirmWord;

  @override
  State<_DeleteAllDialog> createState() => _DeleteAllDialogState();
}

class _DeleteAllDialogState extends State<_DeleteAllDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _matches = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.deleteAllTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.deleteAllBody),
          const SizedBox(height: 16),
          Text(l10n.deleteAllConfirmHint(widget.confirmWord)),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            autocorrect: false,
            onChanged: (value) {
              setState(() => _matches = value == widget.confirmWord);
            },
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          child: Text(l10n.deleteAllAction),
        ),
      ],
    );
  }
}
