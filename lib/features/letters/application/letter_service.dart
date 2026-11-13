import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/models/app_settings.dart';
import '../../../core/models/letter.dart';
import '../../../core/models/letter_status.dart';
import '../../../core/services/notification_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/sembast_letter_repository.dart';

class LetterSaveResult {
  const LetterSaveResult({required this.letter, this.notificationError});

  final Letter letter;
  final Object? notificationError;
}

class LetterDeleteResult {
  const LetterDeleteResult({this.notificationError});

  final Object? notificationError;
}

/// Domain service that keeps letter persistence and notification scheduling in
/// sync. Notification failures never roll back a successfully saved letter.
class LetterService {
  LetterService(
    this._repository,
    this._notifications,
    this._settings,
    this._clock,
  );

  final LetterRepository _repository;
  final NotificationService _notifications;
  final AppSettings Function() _settings;
  final DateTime Function() _clock;

  Future<void> _syncQueue = Future<void>.value();

  Future<LetterSaveResult> saveDraft(Letter letter) async {
    final toSave = letter.copyWith(isDraft: true, updatedAt: _clock().toUtc());
    await _repository.upsert(toSave);
    // Drafts are never in the notification schedule. Saving one must not
    // cancel or reschedule sealed letters (and must not hit the web backend on
    // every debounced autosave).
    return LetterSaveResult(letter: toSave);
  }

  Future<LetterSaveResult> seal({
    required Letter letter,
    required DateTime openAt,
  }) async {
    final now = _clock().toUtc();
    if (!openAt.toUtc().isAfter(now)) {
      throw ArgumentError.value(openAt, 'openAt', 'Must be in the future.');
    }
    final toSave = letter.copyWith(
      openAt: openAt.toUtc(),
      openedAt: null,
      isDraft: false,
      updatedAt: now,
    );
    await _repository.upsert(toSave);
    final error = await _syncSafely();
    return LetterSaveResult(letter: toSave, notificationError: error);
  }

  Future<LetterSaveResult> updateSealed({
    required Letter letter,
    required String title,
    required String body,
    required DateTime openAt,
  }) async {
    if (!openAt.toUtc().isAfter(_clock().toUtc())) {
      throw ArgumentError.value(openAt, 'openAt', 'Must be in the future.');
    }
    final toSave = letter.copyWith(
      title: title,
      body: body,
      openAt: openAt.toUtc(),
      updatedAt: _clock().toUtc(),
    );
    await _repository.upsert(toSave);
    final error = await _syncSafely();
    return LetterSaveResult(letter: toSave, notificationError: error);
  }

  Future<LetterSaveResult> markOpened(Letter letter) async {
    if (letter.openedAt != null) {
      return LetterSaveResult(letter: letter);
    }
    final status = letter.statusAt(_clock());
    if (status != LetterStatus.ready) {
      throw StateError('A sealed or draft letter cannot be opened.');
    }
    final now = _clock().toUtc();
    final toSave = letter.copyWith(openedAt: now, updatedAt: now);
    await _repository.upsert(toSave);
    final error = await _syncSafely();
    return LetterSaveResult(letter: toSave, notificationError: error);
  }

  Future<LetterDeleteResult> delete(Letter letter) async {
    await _repository.delete(letter.id);
    final error = await _syncSafely();
    return LetterDeleteResult(notificationError: error);
  }

  Future<LetterDeleteResult> deleteAll() async {
    await _repository.deleteAll();
    final error = await _syncSafely();
    return LetterDeleteResult(notificationError: error);
  }

  Future<ImportSummary> importLetters(List<Letter> letters) async {
    final summary = await _repository.importAll(letters);
    await _syncSafely();
    return summary;
  }

  /// Rebuilds the complete notification schedule from persisted letters.
  ///
  /// Returns an error object for the caller to surface as a warning, or null.
  Future<Object?> synchronizeSchedules() => _syncSafely();

  /// Serializes schedule rebuilds. Concurrent saves/deletes must not race and
  /// leave the newest server/OS schedule overwritten by an older snapshot.
  Future<Object?> _syncSafely() {
    final completer = Completer<Object?>();
    _syncQueue = _syncQueue.then((_) async {
      Object? error;
      try {
        error = await _performSync();
      } on Object catch (syncError) {
        error = syncError;
      }
      completer.complete(error);
    });
    return completer.future;
  }

  Future<Object?> _performSync() async {
    try {
      final settings = _settings();
      final allLetters = await _repository.getAll();
      final now = _clock().toUtc();

      final future = allLetters
          .where(
            (letter) =>
                !letter.isDraft &&
                letter.openedAt == null &&
                letter.openAt != null &&
                letter.openAt!.isAfter(now),
          )
          .map(
            (letter) => ScheduledLetter(
              letterId: letter.id,
              notificationId: letter.notificationId,
              openAt: letter.openAt!,
            ),
          )
          .toList();

      if (!settings.notificationsEnabled || future.isEmpty) {
        await _notifications.cancelAllScheduled();
        return null;
      }

      final permission = await _notifications.permissionStatus();
      if (!permission.isGranted) {
        await _notifications.cancelAllScheduled();
        return null;
      }

      final l10n = lookupAppLocalizations(settings.locale.locale);
      await _notifications.synchronize(
        letters: future,
        localeCode: settings.locale.languageCode,
        title: l10n.notificationTitle,
        body: l10n.notificationBody,
        channelName: l10n.notificationChannelName,
        channelDescription: l10n.notificationChannelDescription,
      );
      return null;
    } on Object catch (error) {
      return error;
    }
  }

  String? letterIdFromPayload(String? payload) {
    if (payload == null) {
      return null;
    }
    const prefix = 'letter:';
    if (!payload.startsWith(prefix)) {
      return null;
    }
    final id = payload.substring(prefix.length).trim();
    return id.isEmpty ? null : id;
  }

  /// Cancels everything when the user turns notifications off or deletes data.
  Future<void> cancelAll() async {
    try {
      await _notifications.cancelAllScheduled();
    } on Object {
      // Nothing else can be done; the next sync will try again.
    }
  }

  Future<void> initializeNotifications(
    ValueChanged<String> onTap, {
    VoidCallback? onSubscriptionChanged,
  }) async {
    await _notifications.initialize(
      onTap: onTap,
      onSubscriptionChanged: onSubscriptionChanged,
    );
  }

  Future<String?> takeLaunchPayload() => _notifications.takeLaunchPayload();

  Future<NotificationPermissionStatus> permissionStatus() =>
      _notifications.permissionStatus();

  Future<NotificationPermissionStatus> requestPermission() =>
      _notifications.requestPermission();

  Future<bool> showTestNotification() async {
    final settings = _settings();
    final l10n = lookupAppLocalizations(settings.locale.locale);
    return _notifications.showTest(
      title: l10n.testNotificationTitle,
      body: l10n.testNotificationBody,
      channelName: l10n.notificationChannelName,
      channelDescription: l10n.notificationChannelDescription,
    );
  }

  Future<bool> openSystemNotificationSettings() =>
      _notifications.openSystemSettings();

  NotificationPlatformInfo get platformInfo => _notifications.platformInfo;

  Future<PushServerStatus> pushServerStatus() =>
      _notifications.pushServerStatus();
}
