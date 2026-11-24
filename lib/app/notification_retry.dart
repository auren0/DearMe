import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/notification_service.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_keys.dart';
import 'localization/l10n_extension.dart';
import 'providers.dart';
import 'snackbar.dart';

AppLocalizations _currentL10n(ProviderContainer container) {
  final context = rootScaffoldMessengerKey.currentContext;
  if (context != null) {
    return context.l10n;
  }
  return lookupAppLocalizations(
    container.read(settingsControllerProvider).locale.locale,
  );
}

/// Shows the localized "saved but not scheduled" warning.
///
/// Permission failures get a specific message and an "Open system settings"
/// action where the platform supports it. Other failures offer a retry.
///
/// The action keeps working after the screen that triggered it is popped (the
/// editor navigates to the detail screen immediately after saving), so it
/// captures the provider container instead of a `WidgetRef`.
void showNotificationScheduleError(
  BuildContext context,
  WidgetRef ref, {
  Object? error,
}) {
  final l10n = context.l10n;
  final container = ProviderScope.containerOf(context, listen: false);

  if (error is NotificationPermissionException) {
    _showPermissionError(container);
    return;
  }

  showAppSnackBar(
    l10n.errorNotificationSchedule,
    isWarning: true,
    actionLabel: l10n.retry,
    onAction: () => unawaited(retryNotificationSchedules(container)),
  );
}

void _showPermissionError(ProviderContainer container) {
  final l10n = _currentL10n(container);
  final platform = container.read(letterServiceProvider).platformInfo;
  if (platform.supportsSystemSettings) {
    showAppSnackBar(
      l10n.errorNotificationPermissionSaved,
      isError: true,
      actionLabel: l10n.openSystemSettings,
      onAction: () => unawaited(_openSystemSettings(container)),
    );
    return;
  }

  showAppSnackBar(
    l10n.errorNotificationPermissionSaved,
    isError: true,
    actionLabel: l10n.retry,
    onAction: () => unawaited(retryNotificationSchedules(container)),
  );
}

Future<void> _openSystemSettings(ProviderContainer container) async {
  final opened = await container
      .read(letterServiceProvider)
      .openSystemNotificationSettings();
  if (!opened) {
    showAppSnackBar(
      _currentL10n(container).systemSettingsUnavailable,
      isWarning: true,
    );
  }
}

Future<void> _markPermissionRequested(ProviderContainer container) async {
  try {
    await container
        .read(settingsControllerProvider.notifier)
        .setNotificationPermissionRequested(true);
  } on Object {
    // Remembering the prompt is a convenience; it must not block scheduling.
  }
}

/// Rebuilds the notification schedule from persisted letters.
///
/// Nothing here touches letter storage: a failure can only affect reminders,
/// never the saved letters themselves.
Future<void> retryNotificationSchedules(ProviderContainer container) async {
  final settings = container.read(settingsControllerProvider);
  if (!settings.notificationsEnabled) {
    showAppSnackBar(
      _currentL10n(container).notificationsDisabled,
      isWarning: true,
    );
    return;
  }

  final service = container.read(letterServiceProvider);
  var permission = await service.permissionStatus();

  // A retry is a direct user gesture, so it is a good moment to ask again on
  // platforms that expose a runtime prompt. Do not keep re-prompting after a
  // denial; the permission error action opens system settings where available.
  if (!permission.isGranted &&
      service.platformInfo.supportsPermissionRequest &&
      !(permission == NotificationPermissionStatus.denied &&
          settings.notificationPermissionRequested)) {
    permission = await service.requestPermission();
    await _markPermissionRequested(container);
  }

  if (!permission.isGranted) {
    _showPermissionError(container);
    return;
  }

  final error = await container
      .read(lettersControllerProvider.notifier)
      .retryNotificationScheduling();
  final l10n = _currentL10n(container);

  if (error == null) {
    showAppSnackBar(l10n.notificationScheduleRetried);
    return;
  }

  if (error is NotificationPermissionException) {
    _showPermissionError(container);
    return;
  }

  showAppSnackBar(
    l10n.errorNotificationSchedule,
    isWarning: true,
    actionLabel: l10n.retry,
    onAction: () => unawaited(retryNotificationSchedules(container)),
  );
}
